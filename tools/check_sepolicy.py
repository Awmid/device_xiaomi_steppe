#!/usr/bin/env python3
"""Local neverallow check for the steppe sepolicy (no AOSP tree needed).

Builds ONE monolithic policy.conf from: lineage-23.2 system sepolicy, QSSI, Lineage, sepolicy_vndr (sm8750/canoe)
and this device's sepolicy/vendor, then runs checkpolicy (which enforces neverallow rules).
Approximation of the real build (single monolithic policy, checkpolicy 3.5 from Ubuntu, not Android's split plat/vendor flow).

  VARIANT=user|userdebug AVF=true|false ./check_sepolicy.py <out_dir> [--base]     (--base = without our sepolicy/vendor)
Setup once:  mkdir -p ~/.cache/seltools && cd ~/.cache/seltools && apt-get download m4 checkpolicy && for d in *.deb; do dpkg -x $d root; done
"""
import os, re, sys, glob, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
# Layout (override with env vars): <TREE>/device_xiaomi_steppe (this repo) and <TREE>/android_device_qcom_sepolicy_vndr side by side;
# <REF>/{syssep,qssisep,linsep} = lineage-23.2 clones of android_system_sepolicy, device_qcom_sepolicy, device_lineage_sepolicy.
TREE = os.environ.get("STEPPE_TREE", os.path.dirname(os.path.dirname(HERE)))
REF = os.environ.get("STEPPE_REF", os.path.join(os.path.dirname(TREE), "reference lineage-23.2 sepolicy"))
SYS, QSSI, LIN = f"{REF}/syssep", f"{REF}/qssisep", f"{REF}/linsep"
VNDR = f"{TREE}/android_device_qcom_sepolicy_vndr"
OURS = os.path.join(os.path.dirname(HERE), "sepolicy", "vendor")
TOOLS = os.path.expanduser("~/.cache/seltools/root/usr/bin")
variant = os.environ.get("VARIANT", "user")
avf = os.environ.get("AVF", "true")
out = sys.argv[1]
os.makedirs(out, exist_ok=True)

dirs = [f"{SYS}/public", f"{SYS}/private",
        f"{QSSI}/generic/public", f"{QSSI}/generic/public/attribute", f"{QSSI}/generic/private",
        f"{QSSI}/generic/product/public", f"{QSSI}/generic/product/private",
        f"{LIN}/common/public", f"{LIN}/common/private", f"{LIN}/qcom/private",
        f"{SYS}/vendor",
        f"{LIN}/common/dynamic", f"{LIN}/common/vendor", f"{LIN}/qcom/dynamic", f"{LIN}/qcom/vendor",
        VNDR, f"{VNDR}/generic/vendor/common", f"{VNDR}/generic/vendor/common/attribute", f"{VNDR}/qva/vendor/common",
        f"{VNDR}/generic/vendor/canoe", f"{VNDR}/qva/vendor/canoe"]
if variant != "user":
    dirs += [f"{VNDR}/generic/vendor/test", f"{VNDR}/qva/vendor/test", f"{VNDR}/qva/vendor/test/sysmonapp"]
if "--base" not in sys.argv:
    dirs.append(OURS)
dirs = [d for d in dirs if os.path.isdir(d)]

first = ("security_classes initial_sids access_vectors global_macros neverallow_macros mls_macros mls_decl mls "
         "policy_capabilities roles_decl te_macros attributes ioctl_defines ioctl_macros").split()
last = "roles users initial_sid_contexts fs_use genfs_contexts port_contexts".split()
files = [f"{SYS}/flagging/flagging_macros"]
for n in first:
    files += [f"{d}/{n}" for d in dirs if os.path.isfile(f"{d}/{n}")]
for d in dirs:
    files += sorted(glob.glob(f"{d}/*.te"))
for n in last:
    files += [f"{d}/{n}" for d in dirs if os.path.isfile(f"{d}/{n}")]

defs = dict(mls_num_sens=1, mls_num_cats=1024, target_build_variant=variant, target_arch="arm64", target_with_asan="false",
            target_with_dexpreopt="true", target_with_native_coverage="false", target_full_treble="true",
            target_compatible_property="true", target_treble_sysprop_neverallow="true", target_enforce_sysprop_owner="true",
            target_exclude_build_test="false", target_requires_insecure_execmem_for_swiftshader="false",
            target_enforce_debugfs_restriction="true", target_recovery="false", target_flatten_apex="false",
            target_board_api_level=202504, target_flag_RELEASE_AVF_ENABLE_EARLY_VM=avf)
# Lineage device/lineage/sepolicy/qcom/sepolicy.mk BOARD_SEPOLICY_M4DEFS
for kv in ("custom_ab_block_device=vendor_custom_ab_block_device display_vendor_data_file=vendor_display_vendor_data_file "
           "hal_gnss_qti=vendor_hal_gnss_qti hal_perf_default=vendor_hal_perf_default location_domain=vendor_location "
           "persist_block_device=vendor_persist_block_device qdisplay_service=vendor_qdisplay_service "
           "sysfs_battery_supply=vendor_sysfs_battery_supply sysfs_devfreq=vendor_sysfs_devfreq sysfs_graphics=vendor_sysfs_graphics "
           "sysfs_kgsl=vendor_sysfs_kgsl sysfs_scsi_host=vendor_sysfs_scsi_host sysfs_socinfo_sensitive=vendor_sysfs_soc_sensitive "
           "sysfs_usb_supply=vendor_sysfs_usb_supply").split():
    k, v = kv.split("=")
    defs[k] = v
open(f"{out}/files.txt", "w").write("\n".join(files))
r = subprocess.run([f"{TOOLS}/m4", "-s"] + [f"-D{k}={v}" for k, v in defs.items()] + files, capture_output=True, text=True)
print("variant", variant, "| AVF early vm", avf, "| m4 rc", r.returncode, "| files", len(files))
if r.returncode:
    print(r.stderr[:1500]); sys.exit(1)

conf = r.stdout
# --- workarounds for the old checkpolicy / missing repos (check-only, nothing is written back to the tree) ---
conf, ngenfs = re.subn(r"(?m)^(genfscon \w+ )([^/\s])", r"\1/\2", conf)   # qcom canoe genfs path without leading slash
conf, nn = re.subn(r"\b(?:neverallowxperm|auditallowxperm|allowxperm|dontauditxperm)\b[^;]*?\bnlmsg\b[^;]*;", "", conf, flags=re.S)
removed_caps, declared, dropped = [], [], []
for _ in range(400):
    open(f"{out}/policy.conf", "w").write(conf)
    c = subprocess.run([f"{TOOLS}/checkpolicy", "-M", "-c", "30", "-o", f"{out}/policy.bin", f"{out}/policy.conf"], capture_output=True, text=True)
    msg = c.stdout + c.stderr
    if c.returncode == 0:
        break
    m = re.search(r"invalid policy capability name (\w+)", msg)
    if m:
        conf = conf.replace(f"policycap {m.group(1)};\n", ""); removed_caps.append(m.group(1)); continue
    m = re.search(r"unknown (?:type|attribute|type/attribute) ([\w-]+)", msg)
    if m and m.group(1) not in declared:
        declared.append(m.group(1))
        decl = (f"type {m.group(1)}, exec_type, file_type, system_file_type;" if m.group(1).endswith("_exec") else f"type {m.group(1)}, domain;")
        conf = re.sub(r"(?m)^user ", decl + "\nuser ", conf, count=1); continue
    break
open(f"{out}/checkpolicy.err", "w").write(msg)
print("unsupported policycaps stripped:", removed_caps, "| unknown types auto-declared (REAL if not AOSP-owned):", declared)
print("nlmsg xperm rules stripped:", nn, "| genfs paths patched:", ngenfs)
print("checkpolicy rc", c.returncode)
print(msg[:4000])
sys.exit(0 if c.returncode == 0 else 1)
