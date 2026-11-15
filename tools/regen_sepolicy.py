#!/usr/bin/env python3
"""Regenerate sepolicy/vendor from the stock cil AND make it compile (local check, see check_sepolicy.py).

  python3 tools/regen_sepolicy.py [--work DIR] [--no-base]      (--no-base: reuse DIR/base from an earlier run)

1. builds the base policy (without our dir) for user/userdebug and AVF flag on/off -> DIR/base/*
2. runs gen_sepolicy_from_cil.py with SEPOLICY_BASE_CONFS=DIR/base
3. compiles with our output for the 4 combinations; every neverallow violation reported by checkpolicy is pruned from the
   generated .te files (the rule, or just the offending source/target/perms of a set rule) and listed in sepolicy/vendor/../neverallow_pruned.txt
Anything else that fails is printed and left alone.
Exit code: 0 only if all 4 combinations compile in one clean round and no unexpected type had to be auto-declared;
1 = not all combinations passed after 8 rounds; 3 = unexpected auto-declared type (see sepolicy/autodeclared_review.txt).
Every pruned rule and every workaround of check_sepolicy.py is written to sepolicy/neverallow_pruned.txt and sepolicy/autodeclared_review.txt: REVIEW THEM.
"""
import os, re, subprocess, sys, glob

HERE = os.path.dirname(os.path.abspath(__file__))
DEV = os.path.dirname(HERE)
# Layout (override with env vars): <TREE> holds this repo and android_device_qcom_sepolicy_vndr side by side;
# STEPPE_REF = dir with syssep/ qssisep/ linsep/ (lineage-23.2 clones); STEPPE_DUMP = unpacked stock OTA dump (REQUIRED).
TREE = os.environ.get("STEPPE_TREE", os.path.dirname(DEV))
DUMP = os.environ.get("STEPPE_DUMP") or sys.exit("set STEPPE_DUMP to the unpacked stock OTA dump directory")
REF = os.environ.get("STEPPE_REF", os.path.join(os.path.dirname(TREE), "reference lineage-23.2 sepolicy"))
OUT = f"{DEV}/sepolicy/vendor"
work = os.path.expanduser(sys.argv[sys.argv.index("--work") + 1]) if "--work" in sys.argv else os.path.expanduser("~/sepol_out")
COMBOS = [("user", "true"), ("userdebug", "true"), ("user", "false"), ("userdebug", "false")]


def check(outdir, base=False):
    env = dict(os.environ)
    cmd = ["python3", f"{HERE}/check_sepolicy.py", outdir] + (["--base"] if base else [])
    return env, cmd


def run_check(variant, avf, outdir, base=False):
    env, cmd = check(outdir, base)
    env.update(VARIANT=variant, AVF=avf)
    r = subprocess.run(cmd, env=env, capture_output=True, text=True)
    return r.stdout + r.stderr


if "--no-base" not in sys.argv:
    for v, a in [("user", "true"), ("userdebug", "true"), ("user", "false")]:
        d = f"{work}/base/{v}_{a}"
        print("base build", v, a, "...", flush=True)
        o = run_check(v, a, d, base=True)
        if "checkpolicy rc 0" not in o:
            print(o[:2000]); sys.exit("base policy does not compile - sources/paths changed?")

env = dict(os.environ, SEPOLICY_BASE_CONFS=f"{work}/base")
g = subprocess.run(["python3", f"{HERE}/gen_sepolicy_from_cil.py", DUMP, TREE + "/android_device_qcom_sepolicy_vndr",
                    f"{REF}/syssep", f"{REF}/qssisep", f"{REF}/linsep", OUT], env=env, capture_output=True, text=True)
print(g.stdout[-1800:], g.stderr[-1500:])
if g.returncode:
    sys.exit("generator failed")

RULE = re.compile(r"(allow|auditallow|allowxperm)\s+(\{[^}]*\}|\S+)\s+(\{[^}]*\}|\S+):(\{[^}]*\}|\S+)\s+(\{[^}]*\}|[^;]+);")
VIOL = re.compile(r"violated by (?:allow|allowxperm) (\S+) (\S+):(\S+) (\{[^}]*\}|[^;]+);")
toks = lambda x: re.findall(r"[~\w.*-]+", x)
pruned = []


def prune(src, tgt, cls, perms):
    pset = set(toks(perms))
    hit = False
    for f in glob.glob(f"{OUT}/*.te"):
        lines = open(f).read().split("\n")
        changed = False
        for i, l in enumerate(lines):
            m = RULE.search(l)
            if not m or m.group(1) != "allow":
                continue
            S, T, C, P = toks(m.group(2)), toks(m.group(3)), toks(m.group(4)), toks(m.group(5))
            if src not in S or tgt not in T or cls not in C or not (pset & set(P)):
                continue
            hit = True
            newP = [p for p in P if p not in pset]
            if newP:                                   # keep the permissions that are fine
                rep = "allow %s %s:%s { %s };" % (m.group(2), m.group(3), m.group(4), " ".join(newP))
            elif len(S) > 1:                           # drop only this source
                rep = "allow { %s } %s:%s %s;" % (" ".join(x for x in S if x != src), m.group(3), m.group(4), m.group(5))
            elif len(T) > 1:
                rep = "allow %s { %s }:%s %s;" % (m.group(2), " ".join(x for x in T if x != tgt), m.group(4), m.group(5))
            else:
                rep = None
            pruned.append("%s: %s  ==>  %s" % (os.path.basename(f), m.group(0), rep or "(removed)"))
            lines[i] = l[:m.start()] + (rep if rep else "# pruned (neverallow): " + m.group(0)) + l[m.end():]
            changed = True
        if changed:
            open(f, "w").write("\n".join(lines))
    return hit


AUTODECL = re.compile(r"auto-declared \(REAL if not AOSP-owned\): \[([^\]]*)\]")
CAPS = re.compile(r"policycaps stripped: \[([^\]]*)\]")
NLMSG = re.compile(r"nlmsg xperm rules stripped: (\d+)")
quoted = lambda m: re.findall(r"'([^']+)'", m.group(1)) if m else []
# early_virtmgr: AOSP policy references it even when RELEASE_AVF_ENABLE_EARLY_VM is false (same with --base), so the stub is not ours.
KNOWN_AOSP_STUBS = {"early_virtmgr"}
review = {}
passed = False
for rnd in range(8):
    bad = False
    for v, a in COMBOS:
        o = run_check(v, a, f"{work}/ours/{v}_{a}")
        nl = NLMSG.search(o)
        review[(v, a)] = (quoted(AUTODECL.search(o)), quoted(CAPS.search(o)), nl.group(1) if nl else "?")
        if "checkpolicy rc 0" in o:
            print(f"round {rnd}: {v}/{a}: OK")
            continue
        viol = VIOL.findall(o)
        print(f"round {rnd}: {v}/{a}: FAILED, neverallow violations: {len(viol)}")
        if not viol:
            print(o[:2500])
            bad = True
            continue
        if not any(prune(*x) for x in viol):
            print("could not map violations to generated rules:\n", "\n".join(map(str, viol[:5])))
            bad = True
        else:
            bad = True   # re-run all combos after a prune
    if not bad:
        passed = True
        break

with open(f"{DEV}/sepolicy/neverallow_pruned.txt", "w") as f:
    f.write("# Rules removed from the generated policy because they violate a neverallow of the included policy sources.\n"
            "# Removing a rule makes the policy compile; it does NOT mean the service works without it. Review each one.\n"
            "# Written by tools/regen_sepolicy.py\n" + ("\n".join(pruned) if pruned else "(none)") + "\n")
with open(f"{DEV}/sepolicy/autodeclared_review.txt", "w") as f:
    f.write("# Workarounds applied by tools/check_sepolicy.py to get the LOCAL compile through (nothing here is in the real policy).\n"
            "# A type listed under auto-declared was missing everywhere and got a stub declaration; if it is not AOSP-owned, the real build will fail on it.\n"
            "# Written by tools/regen_sepolicy.py\n")
    for (v, a), (decl, caps, nl) in review.items():
        f.write(f"{v}/avf={a}: auto-declared types={decl or 'none'} | policycaps stripped={caps or 'none'} | nlmsg xperm rules stripped={nl}\n")
unexpected = sorted({t for d, _, _ in review.values() for t in d} - KNOWN_AOSP_STUBS)
print("pruned rules:", len(pruned))
for p_ in pruned:
    print("  ", p_[:200])
print("auto-declared (all combos):", sorted({t for d, _, _ in review.values() for t in d}) or "none", "| unexpected:", unexpected or "none")
if not passed:
    sys.exit("FAILED: not all 4 combinations compiled in one clean round after 8 rounds - the sepolicy is NOT verified")
if unexpected:
    print("FAILED: unexpected auto-declared types (see sepolicy/autodeclared_review.txt)")
    sys.exit(3)
print("OK: 4/4 combinations compile; review sepolicy/neverallow_pruned.txt and sepolicy/autodeclared_review.txt")
