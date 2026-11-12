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

# Modelled on spring's lineage-23.2 extract-files.py.
# Every fixup below was checked against the actual steppe dump (blob exists and
# has the dependency the fixup targets), except the "unverified shim" group.
namespace_imports = [
    'device/xiaomi/steppe',
    # TODO: add the hardware/qcom-caf/<platform> HAL namespace for malabar once chosen
    'hardware/qcom-caf/wlan',
    'hardware/xiaomi',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        # vendor.qti.diaghal@1.0 exists in both vendor and system_ext in the dump
        'vendor.qti.diaghal@1.0',
        'vendor.qti.hardware.wifidisplaysession@1.0',
        'vendor.qti.imsrtpservice@3.0',
        'vendor.qti.imsrtpservice@3.1',
    ): lib_fixup_vendor_suffix,
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
