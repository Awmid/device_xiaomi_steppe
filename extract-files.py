#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

# Modelled on spring's and peridot's lineage-23.2 extract-files.py.
# Every fixup below was checked against the actual steppe dump (blob exists and
# has the dependency the fixup targets), except the "unverified shim" group.
namespace_imports = [
    'device/xiaomi/steppe',
    # malabar resolves to the sm8750 HAL platform through our hardware/qcom-caf/common fork (UM_6_6_FAMILY)
    'hardware/qcom-caf/sm8750',
    'hardware/qcom-caf/wlan',
    'hardware/xiaomi',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


def _libs_in_vendor_and_elsewhere():
    # Soong rejects two modules with the same name, and the dump ships the same
    # library in vendor/ and in system/system_ext/odm/product. Find every such
    # library from proprietary-files.txt and give the vendor copy a _vendor suffix.
    import os
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'proprietary-files.txt')
    parts = {}
    with open(path) as f:
        for line in f:
            line = line.strip().lstrip('-')
            if not line or line.startswith('#'):
                continue
            blob = line.split(';')[0].split('|')[0]
            if not blob.endswith('.so') or '/lib' not in blob:
                continue
            partition = blob.split('/')[0]
            stem = os.path.basename(blob)[:-3]
            parts.setdefault(stem, set()).add(partition)
    return tuple(sorted(s for s, p in parts.items() if 'vendor' in p and len(p) > 1))


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    _libs_in_vendor_and_elsewhere(): lib_fixup_vendor_suffix,
}


blob_fixups: blob_fixups_user_type = {
    # system_ext manifest starts with a comment block before <manifest>
    'system_ext/etc/vintf/manifest/vendor.qti.qesdsys.service.xml': blob_fixup()
        .regex_replace(r'(?s)^.*?(?=<manifest)', ''),
    # Blobs that link the system libtinyxml2.so (libdpps / libsnapdragoncolor-manager
    # use the bundled libtinyxml2_1.so and need no change)
    (
        'odm/bin/hw/vendor.xiaomi.sensor.citsensorservice.aidl',
        'vendor/bin/hw/vendor.qti.camera.provider-service_64',
        'vendor/bin/hw/vendor.qti.hardware.display.composer-service',
        'vendor/lib64/camx.provider-impl.so',
        'vendor/lib64/liblearningmodule.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    # Unverified shims: carried over from spring (same Qualcomm blobs). The shim
    # modules must exist in the ROM tree, the first build will tell us.
    (
        'vendor/bin/qcc-vendor',
        'vendor/bin/qms',
        'vendor/bin/xtra-daemon',
        'vendor/lib64/libcne.so',
        'vendor/lib64/libqcc_sdk.so',
        'vendor/lib64/libqms_client.so',
    ): blob_fixup()
        .add_needed('libbinder_shim.so'),
    'vendor/lib64/libqcodec2_core.so': blob_fixup()
        .add_needed('libcodec2_shim.so'),
    'vendor/lib64/vendor.libdpmframework.so': blob_fixup()
        .add_needed('libbinder_shim.so')
        .add_needed('libhidlbase_shim.so'),
    'vendor/lib64/libcameraopt.so': blob_fixup()
        .add_needed('libprocessgroup_shim.so'),
    # Codec XMLs include files that Lineage already provides
    (
        'vendor/etc/media_codecs_malabar.xml',
        'vendor/etc/media_codecs_malabar_vendor.xml',
    ): blob_fixup()
        .regex_replace('.*media_codecs_(google_audio|google_telephony|vendor_audio|google_c2|dolby_audio).*\n', ''),
    ('vendor/lib64/libqcrilNr.so', 'vendor/lib64/libril-db.so'): blob_fixup()
        .binary_regex_replace(rb'persist\.vendor\.radio\.poweron_opt', rb'persist.vendor.radio.poweron_ign'),
    # --- from peridot (official lineage-23.2), each verified against the steppe dump ---
    'system_ext/lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so': blob_fixup()
        .replace_needed('libprotobuf-cpp-full.so', 'libprotobuf-cpp-full-21.7.so'),
    (
        'vendor/lib64/libagm.so',
        'vendor/lib64/libar-pal.so',
        'vendor/lib64/libmcs.so',
    ): blob_fixup()
        .replace_needed('libaudioroute.so', 'libaudioroute-v34.so'),
    # camera blobs link allocator V1, A16 only gets V2 (same blobs peridot patches)
    (
        'vendor/lib64/libcamximageformatutils.so',
        'vendor/lib64/libchifeature2.so',
        'vendor/lib64/camera/components/com.qti.node.dewarp.so',
        'vendor/lib64/hw/com.qti.chi.offline.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/vendor.qti.hardware.camera.postproc@1.0-service-impl.so',
        'vendor/bin/chifeature2test',
        'vendor/bin/chiofflinepostproctest',
        'vendor/bin/f2player',
    ): blob_fixup()
        .replace_needed(
            'android.hardware.graphics.allocator-V1-ndk.so',
            'android.hardware.graphics.allocator-V2-ndk.so',
        ),
    'vendor/etc/seccomp_policy/c2audio.vendor.ext-arm64.policy': blob_fixup()
        .add_line_if_missing('setsockopt: 1'),
    # Wi-Fi Display (same patches as peridot; both blobs link libgui/libinput/libbinder, verified in the dump)
    'system_ext/lib64/libwfdmmsrc_system.so': blob_fixup()
        .add_needed('libgui_shim.so'),
    'system_ext/lib64/libwfdnative.so': blob_fixup()
        .add_needed('libbinder_shim.so')
        .add_needed('libinput_shim.so'),
}  # fmt: skip


module = ExtractUtilsModule(
    'steppe',
    'xiaomi',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    # add_firmware_proprietary_file=True needs the firmware partition images
    # (abl, xbl, modem, ...) next to the dump plus a proprietary-firmware.txt;
    # the current dump only has tz.img. Enable once they are extracted from the OTA payload.
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
