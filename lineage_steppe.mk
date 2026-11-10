#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from generic device
$(call inherit-product, device/xiaomi/steppe/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := steppe
PRODUCT_NAME := lineage_steppe
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := steppe
PRODUCT_MANUFACTURER := Xiaomi

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="steppe-user 16 BP2A.250605.031.A3 OS3.0.313.0.WAVMIXM release-keys" \
    BuildFingerprint=Xiaomi/steppe/steppe:16/BP2A.250605.031.A3/OS3.0.313.0.WAVMIXM:user/release-keys
