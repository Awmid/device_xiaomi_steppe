# Device tree for Redmi 17 5G (`steppe`)

LineageOS 23.2 (Android 16) device tree for the Redmi 17 5G, Snapdragon 4 Gen 5 (`SM4850`, platform `malabar`).

> **Status: early development. Nothing has been built or booted yet.**
> Everything below was checked statically (file-by-file comparison against the stock firmware dump, a local sepolicy compile, VINTF and Makefile reference checks). No ROM source has been synced and the bootloader is still locked, so there is no runtime evidence of any kind. Treat every "done" as "done on paper".

## Device

| | |
|---|---|
| Device | Redmi 17 5G (`steppe` / `steppe_global`, model `26062RN92G`, SKU `hcesim_dsds`) |
| SoC | Snapdragon 4 Gen 5 (`SM4850`), CPU variant `kryo300`, 64-bit only |
| Kernel | 6.12.69 GKI (4K pages), prebuilt, waiting kernel source code |
| Vendor API level | 36 |
| Boot scheme | Header v4, `vendor_boot` ramdisk (LZ4), `init_boot`, separate `recovery` partition |
| Partitions | Virtual A/B with compression, `super` = 10200547328 bytes, filesystems EROFS (matches stock) |
| Display | 320 dpi |
| Stock reference | `OS3.0.313.0.WAVMIXM` global OTA |

## Repositories

| Repo | Branch | Purpose |
|---|---|---|
| `device_xiaomi_steppe` (this repo) | `lineage-23.2-undone` | BoardConfig, makefiles, props, rootdir, VINTF, sepolicy, tools |
| `device_xiaomi_steppe_kernel` | `main` | Prebuilt kernel, DTBs, DTBO, GKI modules, kernel headers |
| `vendor_xiaomi_steppe` | `main` | Extracted proprietary blobs |
| `hardware_qcom-caf_common` (fork) | `lineage-23.2` | LineageOS qcom-caf common plus `malabar` added to the UM 6.6 family |

The manifest is at `local_manifests/steppe.xml` and is versioned in this repo. On the first sync, download the raw file into `.repo/local_manifests/` (the command is in the file header), because `repo` cannot read it from a project it has not synced yet.

References are always the **`lineage-23.2`** branches of the reference trees (Xiaomi `spring`, Xiaomi `peridot`, qcom-caf sm8750), never the default `lineage-24.0` branches. Android 17 comes later, after Android 16 works.

## How the Qualcomm side is wired

Lineage 23.2 ships no qcom-caf platform for `malabar`. The forked `hardware_qcom-caf_common` maps `malabar` to the UM 6.6 family, so `QCOM_HARDWARE_VARIANT` resolves to `sm8750`, the newest platform in Lineage 23.2. Display and audio stay blob-provided on purpose, because the stock display stack is newer than any Lineage source and is Xiaomi-modified. Device sepolicy uses the `canoe` policy directory from `sepolicy_vndr`, which is a best guess at the closest policy.

## Done (static only)

- Kernel, DTBs, DTBO and all GKI modules packaged from the stock dump. The kernel, DTBs and DTBO hashes match stock, and all 314 + 283 + 103 modules are byte-identical.
- BoardConfig and `device.mk` structure, EROFS filesystems and fstab aligned with stock, AVB structure and rollback indexes pinned to stock values.
- Blob extraction (`extract-files.py`, `proprietary-files.txt`) with shims and fixups. The vendor `Android.bp` has no duplicate module names.
- VINTF manifests, SKU manifests and the device compatibility matrix from stock. Framework matrices checked by HAL name.
- Device sepolicy generated from the stock compiled vendor policy (`tools/regen_sepolicy.py`). It compiles in a local approximation of the real build (one monolithic policy, workarounds recorded in `sepolicy/autodeclared_review.txt`, neverallow-pruned rules in `sepolicy/neverallow_pruned.txt`); the real split platform/vendor build is the authority.
- `recovery` is deliberately **not** in `AB_OTA_PARTITIONS`, and firmware images are kept out of the OTA lists.
- Makefile reference audit: 1158 paths checked, 0 missing in the three repos.

## Not finished or not verified

- **No build has ever been run.** The first build is expected to surface at least:
  - the full sepolicy compile and neverallow checks (the local check is only an approximation)
  - `check_vintf` version ranges
  - whether the EROFS images fit in the `super` group
  - AVB hashtrees
  - missing Qualcomm techpack UAPI headers in `kernel-headers/`
- **sepolicy** is generated and untested on a device. Rules that Qualcomm's `canoe` policy already covers are not regenerated, so if the stock BSP is newer there will be runtime denials. The `unsignedhexlpservice` access to the DSP device is removed because it violates a Qualcomm neverallow.
- **canoe genfs path:** Qualcomm's `canoe` `genfs_contexts` has a path without a leading slash that `checkpolicy` rejects. A one-line fix exists as a local, unpushed branch. Use it, or switch to `TARGET_SEPOLICY_DIR := sun`, only if the real build fails there.
- **Firmware:** `proprietary-firmware.txt` exists but is switched off. The dump contains no firmware images apart from `tz.img`. Never ship `abl`, `xbl` or `xbl_config` in a test OTA.
- **Gralloc flags** `GRALLOC_HANDLE_HAS_RESERVED_SIZE` and `CUSTOM_CONTENT_MD_RESERVED_SIZE` are left at their defaults and need runtime confirmation.
- **AVB chain key:** after a build, check that the built `vbmeta.img` shows the stock chained key (sha1 starts `85f7b343fdc4`). Vbmeta is built with verification disabled (`--flags 3`) and test keys on purpose.
- **Ignored scripts:** a few stock scripts are not called by any rc file (dead but harmless). Do not delete them.
- **Credits:** `LICENSE` is Apache 2.0. Per-file copyright headers and a credits list for the reference trees (Xiaomi `spring` and `peridot`) still need to be written.

## Before any test boot

1. **Update the phone to `OS3.0.313.0.WAVMIXM`.** All blobs and the kernel prebuilts come from that build, and a phone on `OS3.0.311` does not match them.
2. **Respect anti-rollback.** `fastboot` reports `anti:1`. Never flash firmware or images from a different build than the one installed.
3. **Make extra sure the `recovery` isnt added in OTA partition flashing in the first tests.** you need a working safety net for anything going wrong

## Build plan (planned, not started)
If you want smaller checks before full ROM build
1. Soong dry run and config checks
2. Sepolicy alone (`m selinux_policy`)
3. VINTF and manifest checks
4. Boot-image packaging (there is no kernel source, so this is only packaging)
5. Full ROM

A free build service is no longer available, so the first-build route is undecided. 

## Tools

- `tools/gen_sepolicy_from_cil.py` and `tools/regen_sepolicy.py` regenerate `sepolicy/vendor` from the stock compiled policy. Use these and not older copies.
- `tools/check_sepolicy.py` builds a monolithic policy and runs `checkpolicy` with neverallow enforcement (needs `m4` and `checkpolicy`).
- `extract-files.py` re-extracts the blobs from a stock dump.
- Detailed development notes are kept outside this repository.

## Rules for contributors

- References are always the `lineage-23.2` branches.
- Do not dedupe the kernel module load lists. The duplicates are identical to stock.
- Do not use the security-patch timestamp for AVB rollback indexes. They are pinned to stock.
- Do not re-add `recovery` to the OTA partition list before the tree is proven working.
- Do not turn firmware packaging on without trimming the firmware list first.
