#!/usr/bin/env python3
# Generates sepolicy/vendor/* for steppe from the stock compiled vendor policy (vendor_sepolicy.cil).
#
# Only things that are NOT already defined by the policy sources the build includes
# (AOSP system/sepolicy, device/qcom/sepolicy, device/lineage/sepolicy and
#  device/qcom/sepolicy_vndr: generic|qva/vendor/{common,canoe}) are emitted:
#   - type / attribute declarations for the missing types
#   - allow / dontaudit / allowxperm / type_transition rules that touch a missing type
#   - file_contexts, property_contexts, service_contexts, hwservice_contexts, vndservice_contexts,
#     seapp_contexts, keystore2_key_contexts and genfs_contexts entries that label a missing type
#
# Usage: gen_sepolicy_from_cil.py <dump_root> <sepolicy_vndr_dir> <aosp_system_sepolicy> <qssi_sepolicy> <lineage_sepolicy> <out_dir>
import os
import re
import sys
import collections

VER = "_202504"
dump, vndr, syssep, qssisep, linsep, out = sys.argv[1:7]


# ---------------------------------------------------------------- cil parsing
def tokenize(s):
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in " \t\r\n":
            i += 1
        elif c == ";":
            while i < n and s[i] != "\n":
                i += 1
        elif c in "()":
            yield c
            i += 1
        elif c == '"':
            j = i + 1
            while j < n and s[j] != '"':
                j += 1
            yield s[i:j + 1]
            i = j + 1
        else:
            j = i
            while j < n and s[j] not in " \t\r\n()":
                j += 1
            yield s[i:j]
            i = j


def parse(s):
    stack, cur = [], []
    for t in tokenize(s):
        if t == "(":
            stack.append(cur)
            cur = []
        elif t == ")":
            done = cur
            cur = stack.pop()
            cur.append(done)
        else:
            cur.append(t)
    return cur


cil = parse(open(dump + "/vendor/etc/selinux/vendor_sepolicy.cil", errors="replace").read())
print("cil statements:", len(cil))

stock_types, stock_attrs = set(), set()
members = collections.defaultdict(set)      # attribute -> members (raw cil names)
complex_sets = set()
permissive = set()
for st in cil:
    if not st or not isinstance(st[0], str):
        continue
    k = st[0]
    if k == "type" and len(st) == 2:
        stock_types.add(st[1])
    elif k == "typeattribute" and len(st) == 2:
        stock_attrs.add(st[1])
    elif k == "typeattributeset" and len(st) == 3:
        name, expr = st[1], st[2]
        if isinstance(expr, str):
            if expr != "all":
                members[name].add(expr)
        elif expr and expr[0] in ("and", "not", "xor"):
            complex_sets.add(name)
        else:
            flat = expr[1:] if expr and expr[0] == "or" else expr
            for x in flat:
                if isinstance(x, str):
                    members[name].add(x)
                else:
                    complex_sets.add(name)
    elif k == "typepermissive" and len(st) == 2:
        permissive.add(st[1])


# ---------------------------------------------------------------- already-defined names
ID = r"[A-Za-z0-9_.-]+"


def defs(root):
    t, a = set(), set()
    for dp, _, fs in os.walk(root):
        if "/.git" in dp:
            continue
        for f in fs:
            if not (f.endswith(".te") or f == "attributes" or f.endswith(".cil")):
                continue
            s = re.sub(r"#.*", "", open(os.path.join(dp, f), errors="replace").read())
            for m in re.finditer(r"\btype\s+(%s)\s*[,;]" % ID, s):
                t.add(m.group(1))
            for m in re.finditer(r"\btypealias\s+(%s)" % ID, s):
                t.add(m.group(1))
            for m in re.finditer(r"\battribute\s+(%s)\s*;" % ID, s):
                a.add(m.group(1))
            # names declared through macros
            for m in re.finditer(r"\bhal_attribute(?:_hwservice|_service|_vndservice)?\(\s*([A-Za-z0-9_]+)\s*\)", s):
                a.update(["hal_" + m.group(1), "hal_%s_client" % m.group(1), "hal_%s_server" % m.group(1)])
            for m in re.finditer(r"\b(?:system|vendor|product|odm|userdebug_or_eng)_[a-z_]*prop\(\s*(%s)\s*\)" % ID, s):
                t.add(m.group(1))
    return t, a


ID = r"[A-Za-z0-9_.-]+"
VNDR_DIRS = [vndr + "/" + p for p in (
    "generic/vendor/common", "generic/vendor/canoe", "qva/vendor/common", "qva/vendor/canoe")]
known = set()
for root in [syssep, qssisep, linsep] + VNDR_DIRS:
    t, a = defs(root)
    known |= t | a


def norm_name(n):
    return n[:-len(VER)] if n.endswith(VER) else n


def is_typeattr(n):
    return n.startswith("base_typeattr_")


def expand(n):
    """cil name -> set of normalized type/attr names (base_typeattr_N are compiler artifacts: expanded)."""
    if n == "self":
        return {"self"}
    if is_typeattr(norm_name(n)):
        res = set()
        for m in members.get(n, ()):
            res |= expand(m)
        return res
    return {norm_name(n)}


complex_te = {}     # base_typeattr name -> (te expression, set of names it mentions)


def build_complex():
    for st in cil:
        if st and st[0] == "typeattributeset" and len(st) == 3 and isinstance(st[2], list) and st[2] and st[2][0] == "and":
            e = st[2]
            if len(e) == 3 and isinstance(e[1], list) and len(e[1]) == 1 and isinstance(e[2], list) \
                    and e[2][0] == "not" and isinstance(e[2][1], list):
                base = norm_name(e[1][0])
                neg = [norm_name(x) for x in e[2][1] if isinstance(x, str)]
                complex_te[st[1]] = ("{ %s %s }" % (base, " ".join("-" + x for x in neg)), set(neg) | {base})


build_complex()
new_types = {norm_name(t) for t in stock_types if not is_typeattr(t)} - known
new_attrs = {norm_name(a) for a in stock_attrs if not is_typeattr(a)} - known - new_types
new_all = new_types | new_attrs
print("new types: %d, new attributes: %d" % (len(new_types), len(new_attrs)))

# attribute memberships of new types
type_attrs = collections.defaultdict(set)
for a, ms in members.items():
    if is_typeattr(a):
        continue
    na = norm_name(a)
    for m in ms:
        for e in expand(m):
            if e in new_types:
                type_attrs[e].add(na)


# ---------------------------------------------------------------- rules
def flatten_perms(p):
    if isinstance(p, str):
        return [p]
    res = []
    for x in p:
        res += flatten_perms(x)
    return res


def fmt_set(s):
    s = sorted(s)
    return s[0] if len(s) == 1 else "{ " + " ".join(s) + " }"


rules = []           # (owner_type_for_grouping, text)
skipped = collections.Counter()


def add_rule(kind, s_raw, t_raw, cls, perms):
    if isinstance(s_raw, str) and s_raw in complex_te or isinstance(t_raw, str) and t_raw in complex_te:
        se = complex_te.get(s_raw)
        te = complex_te.get(t_raw)
        S = {se[0]} if se else expand(s_raw)
        T = {te[0]} if te else expand(t_raw)
        mention = (se[1] if se else S) | (te[1] if te else T)
        if not (mention & new_all) or not S or not T:
            return
        cl = fmt_set(flatten_perms(cls))
        pr = fmt_set(flatten_perms(perms))
        owner = sorted(mention & new_all)[0]
        sx = se[0] if se else fmt_set(S)
        tx = te[0] if te else fmt_set(T)
        rules.append((owner, "%s %s %s:%s %s;" % (kind, sx, tx, cl, pr)))
        return
    S = expand(s_raw) if isinstance(s_raw, str) else None
    T = expand(t_raw) if isinstance(t_raw, str) else None
    if S is None or T is None:
        skipped["complex-expr"] += 1
        return
    if not S or not T:
        return
    s_new = S & new_all
    t_new = T & new_all
    if not s_new and not t_new:
        return
    cl = fmt_set(flatten_perms(cls))
    pr = fmt_set(flatten_perms(perms))
    parts = []
    if s_new:
        parts.append((s_new, T))
    if t_new:
        parts.append((S - s_new, t_new))
    for ss, tt in parts:
        if not ss or not tt:
            continue
        txt = "%s %s %s:%s %s;" % (kind, fmt_set(ss), fmt_set(tt), cl, pr)
        owner = sorted(ss & new_all)[0] if ss & new_all else sorted(tt & new_all)[0]
        rules.append((owner, txt))


for st in cil:
    if not st or not isinstance(st[0], str):
        continue
    k = st[0]
    try:
        if k in ("allow", "dontaudit") and len(st) == 4:
            spec = st[3]
            add_rule(k, st[1], st[2], spec[0], spec[1])
        elif k == "allowx" and len(st) == 4:
            s, t, spec = st[1], st[2], st[3]
            if spec[0] == "ioctl" and isinstance(s, str) and isinstance(t, str):
                cls = spec[1]
                vals = []
                for x in spec[2:]:
                    if isinstance(x, list) and x and x[0] == "range":
                        vals.append("%s-%s" % (x[1], x[2]))
                    elif isinstance(x, list):
                        for y in x:
                            vals.append("%s-%s" % (y[1], y[2]) if isinstance(y, list) else y)
                    else:
                        vals.append(x)
                S, T = expand(s), expand(t)
                if (S & new_all) or (T & new_all):
                    cl = fmt_set(flatten_perms(cls))
                    rules.append((sorted((S | T) & new_all)[0],
                                  "allowxperm %s %s:%s ioctl { %s };" % (fmt_set(S), fmt_set(T), cl, " ".join(vals))))
        elif k == "typetransition":
            s, t, cls = st[1], st[2], st[3]
            new = st[-1]
            name = st[4] if len(st) == 6 else None
            S, T = expand(s), expand(t)
            nn = norm_name(new)
            if (S | T | {nn}) & new_all:
                cl = fmt_set(flatten_perms(cls))
                nm = (" " + name) if name else ""
                rules.append((sorted((S | T | {nn}) & new_all)[0],
                              "type_transition %s %s:%s %s%s;" % (fmt_set(S), fmt_set(T), cl, nn, nm)))
    except Exception:
        skipped["error:" + k] += 1

# genfscon
genfs = []
for st in cil:
    if st and st[0] == "genfscon" and len(st) == 4:
        ctx = st[3]
        if isinstance(ctx, list) and len(ctx) >= 3 and norm_name(ctx[2]) in new_all:
            genfs.append("genfscon %s %s u:object_r:%s:s0" % (st[1], st[2].strip('"'), norm_name(ctx[2])))
print("rules touching new types: %d, genfs: %d, skipped: %s" % (len(rules), len(genfs), dict(skipped)))


# ---------------------------------------------------------------- grouping / writing
def family(t):
    f = t
    for pre in ("hal_", "vendor_"):
        if f.startswith(pre) and len(f) > len(pre):
            f = f[len(pre):]
            break
    f = re.sub(r"_(default|client|server|exec|service|hwservice|vndservice|prop|data_file|file|device|attr)$", "", f)
    return f


def kind_of(t, is_attr):
    if is_attr:
        return "attributes"
    ta = type_attrs.get(t, set())
    if t.endswith("_prop") or "property_type" in ta:
        return "property"
    if t.endswith("hwservice") or t.endswith("vndservice") or "hwservice_manager_type" in ta \
            or "vndservice_manager_type" in ta or "service_manager_type" in ta:
        return "service"
    if "domain" in ta:
        return "domain"
    if "dev_type" in ta:
        return "device"
    if ta & {"exec_type", "file_type", "fs_type", "sysfs_type", "proc_type"}:
        return "file"
    return "other"


os.makedirs(out, exist_ok=True)
for f in os.listdir(out):
    if f.endswith(".te") or f == "attributes" or f.endswith("_contexts"):
        os.remove(os.path.join(out, f))

with open(out + "/attributes", "w") as fh:
    fh.write("# Generated by tools/gen_sepolicy_from_cil.py from the stock vendor_sepolicy.cil. Do not edit by hand.\n")
    for a in sorted(new_attrs):
        fh.write("attribute %s;\n" % a)

buckets = collections.defaultdict(list)
dropped_attrs = collections.defaultdict(list)
for t in sorted(new_types):
    k = kind_of(t, False)
    attrs = sorted(a for a in type_attrs.get(t, set()) if a in known or a in new_attrs)
    for a in type_attrs.get(t, set()):
        if a not in known and a not in new_attrs:
            dropped_attrs[a].append(t)
    decl = "type %s%s;" % (t, ", " + ", ".join(attrs) if attrs else "")
    if t in permissive:
        decl += "\npermissive %s;" % t
    if k == "property":
        buckets["property.te"].append(decl)
    elif k == "service":
        buckets["service.te"].append(decl)
    elif k == "other":
        buckets["misc.te"].append(decl)
    else:
        buckets[family(t) + ".te"].append(decl)

for owner, txt in rules:
    k = kind_of(owner, owner in new_attrs)
    if k == "property":
        fn = "property.te"
    elif k == "service":
        fn = "service.te"
    elif k == "other":
        fn = "misc.te"
    else:
        fn = family(owner) + ".te"
    buckets[fn].append(txt)

total_lines = 0
for fn, blocks in sorted(buckets.items()):
    seen, lines = set(), []
    for b in blocks:
        if b not in seen:
            seen.add(b)
            lines.append(b)
    with open(out + "/" + fn, "w") as fh:
        fh.write("# Generated by tools/gen_sepolicy_from_cil.py from the stock vendor_sepolicy.cil. Do not edit by hand.\n")
        fh.write("\n".join(lines) + "\n")
    total_lines += len(lines)
print("wrote %d .te files, %d lines" % (len(buckets), total_lines))

if genfs:
    with open(out + "/genfs_contexts", "w") as fh:
        fh.write("\n".join(sorted(set(genfs))) + "\n")


# ---------------------------------------------------------------- contexts files
def ctx_types(line):
    return [norm_name(x) for x in re.findall(r"u:object_r:(%s):s0" % ID, line)]


def other_ctx_names(fname):
    names = {}
    for r in [syssep, qssisep, linsep] + VNDR_DIRS:
        for dp, _, fs in os.walk(r):
            if "/.git" in dp:
                continue
            for f in fs:
                if f == fname:
                    for line in open(os.path.join(dp, f), errors="replace"):
                        line = line.strip()
                        if line and not line.startswith("#"):
                            names[line.split()[0]] = line
    return names


ctxmap = {
    "vendor_file_contexts": "file_contexts",
    "vendor_property_contexts": "property_contexts",
    "vendor_service_contexts": "service_contexts",
    "vendor_hwservice_contexts": "hwservice_contexts",
    "vndservice_contexts": "vndservice_contexts",
    "vendor_tee_service_contexts": "tee_service_contexts",
    "vendor_keystore2_key_contexts": "keystore2_key_contexts",
}
conflicts = []
for src, dst in ctxmap.items():
    p = dump + "/vendor/etc/selinux/" + src
    if not os.path.exists(p):
        continue
    existing = other_ctx_names(dst) if dst != "file_contexts" else {}
    keep = []
    for line in open(p, errors="replace"):
        s = re.sub(r"(:s0):+$", r"\1", line.strip())
        if not s or s.startswith("#"):
            continue
        if any(t in new_all for t in ctx_types(s)):
            nm = s.split()[0]
            if nm in existing:
                conflicts.append((dst, s, existing[nm]))
                continue
            keep.append(re.sub(r"u:object_r:(%s):s0" % ID,
                               lambda m: "u:object_r:%s:s0" % norm_name(m.group(1)), s))
    if keep:
        with open(out + "/" + dst, "w") as fh:
            fh.write("\n".join(keep) + "\n")
    print("%-28s kept %d" % (dst, len(keep)))

p = dump + "/vendor/etc/selinux/vendor_seapp_contexts"
if os.path.exists(p):
    keep = []
    for line in open(p, errors="replace"):
        s = line.strip()
        if s and not s.startswith("#") and any(
                norm_name(x) in new_all for x in re.findall(r"(?:domain|type)=(%s)" % ID, s)):
            keep.append(re.sub(r"=(%s)" % ID, lambda m: "=" + norm_name(m.group(1)), s))
    if keep:
        with open(out + "/seapp_contexts", "w") as fh:
            fh.write("\n".join(keep) + "\n")
    print("seapp_contexts kept", len(keep))

with open("/tmp/sepolicy_gen_report.txt", "w") as fh:
    fh.write("new_types=%d new_attrs=%d rules=%d genfs=%d\n" % (len(new_types), len(new_attrs), len(rules), len(genfs)))
    fh.write("complex attribute sets (not expanded): %s\n" % sorted(complex_sets)[:50])
    fh.write("skipped: %s\n" % dict(skipped))
    fh.write("attributes dropped from type declarations (not defined by any included policy, belong to the stock system_ext/product policy): %s\n" % dict(dropped_attrs))
    fh.write("\nCONTEXT CONFLICTS (same name already labeled by an included policy source, ours dropped):\n")
    for c in conflicts:
        fh.write("  %s\n    stock : %s\n    source: %s\n" % c)

# reference check: names used in generated rules must be known or generated
unknown = set()
for _, txt in rules:
    m = re.match(r"(\S+) (\{[^}]*\}|\S+) (\{[^}]*\}|\S+):", txt)
    if not m:
        continue
    for grp in (m.group(2), m.group(3)):
        for tok in re.findall(r"[A-Za-z_][A-Za-z0-9_.-]*", grp.replace("-", " -").replace(" -", " ") if False else grp):
            if tok != "self" and tok not in known and tok not in new_all:
                unknown.add(tok)
print("names in rules that are neither already-defined nor generated: %d %s" % (len(unknown), sorted(unknown)[:40]))
