STEPPE TREE PLAN  (Redmi 17 5G, steppe, malabar / SD 4 Gen 5, Android 16 base, ref = spring lineage-23.2)
Updated: 2026-11-11   Rule: update this file after every change (Claude and Ahmad).

== DEVICE FACTS (verified) ==
- Platform malabar, 64-bit only (arm64-v8a), vendor API 36, kernel 6.12.69 GKI 4K
- Boot hdr v4, vendor_boot ramdisk lz4, VABC on, separate recovery partition
- Sizes: boot/vendor_boot 0x6000000, recovery 0x6400000, init_boot 0x800000, dtbo 0x4800000
- super 10200547328, group qti_dynamic_partitions 10190061568
- Stock model 26062RN92G, name steppe_global, device steppe, SKU hcesim_dsds
- Bootloader LOCKED (unlocked:no). Unlock path not verified yet.

== DONE ==
1. Sibling refs studied, aospdtgen output generated, super group/size read from OTA payload.
2. Ahmad: fixed group name/size, removed mi_ext, added vbmeta+vbmeta_system, vbmeta_system AVB block, fixed manifest tags.
3. Claude: rewrote BoardConfig.mk spring-style: kernel/dtb/module block (paths in prebuilts/), cmdline minus stale fingerprints, bootconfig (hardware=qcom only), ext4 types, COPY_OUT, metadata, sepolicy include, full AVB boot key, dropped vendor_boot AVB chain (location clash), removed old TARGET_PREBUILT_* + --dtb hack.
4. Ahmad + Claude + Gemini:
   - [Step 0] graphify run / ignored.
   - [Step 1] Prebuilts split into vendor_boot, vendor_dlkm, system_dlkm/<GKI>; dtb.img split into dtbs/ via extract-dtb.
   - [Step 2] device.mk (ext4, dropped mocks, compression.mk, dalvik heap); lineage_steppe.mk (core_64_bit_only, model 26062RN92G).
   - [Step 3] Properties rebuilt from scratch in properties/ (dropped MIUI/ro.build/sdk_full/force_sw_gles/scout/millet).
   - [Step 4] fstab.qcom trimmed (no mi_ext/overlays/sdcard1/duplicate erofs); removed duplicate vendor/etc/fstab.qcom from proprietary-files.txt.
   - [Step 5] VINTF manifests added to vintf/ (manifest_malabar.xml, 6 ODM SKU manifests, compatibility_matrix.xml); BoardConfig uppercase SKU loop; dropped duplicate fragments.
   - [Step 6] Cleanup: removed extract_utils/ from repo, fixed README.md SoC, added .gitignore.
   - [Step 7] Hardware info applied: androidboot.* props from ADB (usbcontroller, memcg, etc.), ro.sf.lcd_density=320, kryo300.
(See detailed CHANGE LOG below for each step).

== NEXT ==
1. Vendor blobs extraction: run `extract-files.py` against the dump directory (`/mnt/data/android_dev/steppe/...`).
2. Build test: configure LineageOS build environment / local_manifests and run a test build (`mka recoveryimage` / `mka bootimage`).
3. Audio / Display / Camera HAL verification: check if any blob shims or fixups (similar to Spring's extract-files.py) are needed for Android 16 / LineageOS 23.2.
4. Kernel prebuilts repo: move prebuilts/ to a separate repository (e.g. `device_xiaomi_steppe-kernel`) later if keeping device tree lean.
5. I had the "main" branch in the local github desktop with unchanged name so later when I switched to the current correct name lineage-23.2-undone and merged main it showed some conflicts, resolve them

== OPEN QUESTIONS ==
- Bootloader unlock eligibility (Mi account clock).
- Testing needs an unlocked tester flashing the INACTIVE slot (fastboot boot cannot test a ROM).
- Another person (Nocticii-W, Telegram) has a TWRP-only tree: possible tester/cross-check.

== CHANGE LOG ==
2026-11-11 (Ahmad + AI):

[Step 2 — device.mk]
- Dropped HIDL mocks: android.hardware.boot@1.2-impl/service, android.hardware.health@2.1-impl/service,
  android.hardware.fastboot@1.1-impl-mock. Vendor HALs provide these; mocks cause conflicts.
- Added virtual_ab_ota/compression.mk (VAB compression / VABC, matches BOARD_USES_VIRTUAL_AB_COMPRESSION).
- Fixed AB_OTA_POSTINSTALL_CONFIG FILESYSTEM_TYPE: erofs → ext4 for both system and vendor, to match
  BoardConfig.mk ext4 image types.

[Step 2 — lineage_steppe.mk]
- Changed core_64_bit.mk → core_64_bit_only.mk (device is arm64-only, no 32-bit ABI).
- Fixed PRODUCT_MODEL: "steppe" → "26062RN92G" (stock model number from device facts).

[Step 4 — fstab.qcom]
- Removed all mi_ext partition rows and /mi_ext bind-mount rows (MIUI-only partition, not present in LineageOS).
- Removed all overlay filesystem rows that layer mi_ext content over product/system (MIUI-specific).
- Removed sdcard1 (sdhci) vfat row — no SD card slot on this device.
- Removed duplicate erofs rows for all logical partitions (system, system_ext, product, vendor,
  vendor_dlkm, system_dlkm, odm) — BoardConfig builds ext4, so only the ext4 fstab line is kept.
- Kept: all real block partitions (boot/vendor_boot/init_boot/dtbo/recovery/metadata/persist/userdata/
  misc/modem/dsp/bluetooth/qmcs), usbotg vfat line.

[Step 6 — Cleanup (partial)]
- README.md: corrected SoC from "Snapdragon 662/678 (SM6115/SM6150)" to
  "Snapdragon 4 Gen 5 (malabar / SM7635)", added kernel/RAM/storage/model info.
- Added .gitignore: covers graphify-out/, extract_utils/, editor/OS junk.
- Removed TODO comment in BoardConfig.mk for fstab (now done).

== DONE (second pass) ==
2026-11-11 (Ahmad + AI) — using /mnt/data/android_dev/steppe dump + /mnt/data/Documents/GitHub/adb output:

[Step 1 — Prebuilts split]
- Restructured prebuilts/modules/ from flat dir into:
    prebuilts/modules/vendor_boot/   (314 .ko + modules.load + modules.load.recovery + modules.blocklist)
    prebuilts/modules/vendor_dlkm/   (283 .ko + modules.load + modules.blocklist)
    prebuilts/modules/system_dlkm/<GKI>/  (103 .ko in kernel/ subtree + all modules.* metadata)
  Source: extracted from OTA dump vendor_boot ramdisk and vendor_dlkm partition.
- Split dtb.img → prebuilts/dtbs/ using extract-dtb (3 DTBs: Malabar 4GB DDR, Malabar, MalabarP).
- Deleted old prebuilts/dtb.img (now replaced by dtbs/ dir).
- Removed old flat .ko files from prebuilts/modules/ root.

[Step 3 — Props rebuild]
- Created clean properties/ directory following Spring reference (lineage-23.2):
    properties/odm.prop
    properties/product.prop
    properties/system_ext.prop
    properties/system.prop
    properties/vendor.prop
- Dropped all MIUI bloat props (ro.miui.*, persist.miui.*, persist.sys.miui*).
- Dropped raw stock build/fingerprint props and sdk_full (ro.build.*, ro.*.build.version.sdk_full).
- Dropped persist.sys.force_sw_gles=1 and performance tracking daemons (scout, millet, spc, turbosched, stability).
- Dropped blotware preloads (agoda, booking, spotify, lazada, temu).
- Moved Dalvik VM configs to frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk in device.mk.
- Deleted obsolete flat prop files and empty dlkm prop files from tree root.
- Updated BoardConfig.mk TARGET_*_PROP paths to $(DEVICE_PATH)/properties/*.prop.

[Step 4 — fstab duplicate fix]
- Removed vendor/etc/fstab.qcom from proprietary-files.txt to prevent duplicate definitions
  and conflict with the tree's modified rootdir/etc/fstab.qcom module.

[Step 5 — VINTF]
- Created vintf/ dir with stock manifests from dump:
    vintf/vendor/manifest_malabar.xml         (platform-level vendor manifest)
    vintf/odm/manifest_hcesim_dsds.xml        (shipping SKU)
    vintf/odm/manifest_hcesim_ssss.xml
    vintf/odm/manifest_hcesimese_dsds.xml
    vintf/odm/manifest_hcesimese_ssss.xml
    vintf/odm/manifest_nonfc_dsds.xml
    vintf/odm/manifest_nonfc_ssss.xml
    vintf/compatibility_matrix.xml
- Removed old hand-written manifest.xml (was incomplete/placeholder).
- Updated BoardConfig.mk: DEVICE_MANIFEST_FILE → vintf/vendor/manifest_malabar.xml;
  added DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE; wired ODM_MANIFEST_SKUS using uppercase loop.
- Removed duplicate vendor/odm manifest fragment dirs from device tree (they are extracted via proprietary-files.txt).
- Cleaned up device.mk wildcard manifest inclusions to avoid duplicate HAL definitions.

[Step 6 — Cleanup]
- Removed extract_utils/ from repo (handled by Lineage build harness).
- README.md: updated with verified SoC and hardware specs.
- Added .gitignore.

[Step 7 — ro.boot.* / lcd_density / cpu_variant]
- BOARD_BOOTCONFIG: added androidboot.usbcontroller=4e00000.dwc3,
  androidboot.memcg=1, androidboot.serialconsole=0,
  androidboot.load_modules_parallel=true (all verified from getprop dump).
- device.mk: added ro.sf.lcd_density=320 (verified from getprop ro.sf.lcd_density).
- BoardConfig.mk: cleared cpu_variant TODO (ro.bionic.cpu_variant not set in stock;
  kryo300 confirmed correct for malabar).
