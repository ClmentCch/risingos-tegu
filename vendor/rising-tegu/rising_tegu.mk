#
# SPDX-License-Identifier: Apache-2.0
#
# RisingOS Revived 9 product for the Google Pixel 9a (tegu)
#
# Composition:
#   1. LineageOS tegu device foundation (device tree, kernel, vendor, HALs)
#   2. LineageOS full-phone vendor config (inherited by lineage_tegu.mk)
#   3. RisingOS 9 software layer (framework, SystemUI, Settings, apps, config)
#
# This is an UNOFFICIAL community product. tegu is not listed in
# vendor/official_devices/OTA/risingOS.devices, so vendor/rising/config/version.mk
# classifies the build as COMMUNITY and it must not be presented as official RisingOS.
#

# ---------------------------------------------------------------------------
# 1. Device foundation — MUST be inherited first, before any Rising override.
#    This pulls in:
#      - vendor/lineage/config/common_full_phone.mk
#      - device/google/tegu/aosp_tegu.mk + device-tegu.mk
#      - device/google/zumapro/common.mk (Tensor G4 platform)
#      - prebuilt kernel from device/google/tegu-kernels/6.1
#      - vendor/google/tegu/tegu-vendor.mk (proprietary blobs)
#      - the real tegu fingerprint/build description overrides
# ---------------------------------------------------------------------------
$(call inherit-product, device/google/tegu/lineage_tegu.mk)

# ---------------------------------------------------------------------------
# 2. RisingOS 9 software layer.
#    Brings in vendor/rising/config/{properties,packages,version}.mk, the Rising
#    overlays, prebuilts (RisingWalls, BtHelper, ColumbusService, ...), adblock and
#    the freeform/SIP permissions. The framework, SystemUI and Settings in this
#    build are the RisingOS forks pinned in the Rising manifest — not LineageOS.
# ---------------------------------------------------------------------------
$(call inherit-product, vendor/rising/config/rising.mk)

# ---------------------------------------------------------------------------
# 3. Product identity. Declared after all inclusions, per Android product rules.
# ---------------------------------------------------------------------------
PRODUCT_NAME := rising_tegu
PRODUCT_DEVICE := tegu
PRODUCT_MODEL := Pixel 9a
PRODUCT_BRAND := google
PRODUCT_MANUFACTURER := Google

# Keep the system image identity consistent with the inherited tegu product.
PRODUCT_SYSTEM_NAME := generic_system_google

# ---------------------------------------------------------------------------
# 4. RisingOS build metadata (see RisingOS-Revived/android README).
#    RisingChipset / RisingMaintainer are exposed as ro.rising.chipset and
#    ro.rising.maintainer. Keep these in sync with config/project.json.
# ---------------------------------------------------------------------------
RISING_MAINTAINER := ClmentCch

PRODUCT_BUILD_PROP_OVERRIDES += \
    RisingChipset="Google Tensor G4" \
    RisingMaintainer="ClmentCch"

# ---------------------------------------------------------------------------
# 5. Package policy for an unofficial, redistributable build.
#    Google apps are NOT bundled: their redistribution is not permitted.
#    Builders may enable GMS locally (WITH_GMS := true), but such builds are
#    not covered by this project's licensing and must not be published as-is.
# ---------------------------------------------------------------------------
WITH_GMS := false
WITH_MICROG := false

# ---------------------------------------------------------------------------
# 6. Display / UX.
#    Pixel 9a (Tensor G4) supports blur; RisingOS reads TARGET_ENABLE_BLUR.
# ---------------------------------------------------------------------------
TARGET_ENABLE_BLUR := true

# Keep the LineageOS camera app (Aperture) that the tegu product ships with.
PRODUCT_NO_CAMERA := false

# ---------------------------------------------------------------------------
# 7. Sanity: this product must never be built for another device.
#    (Product stubs are evaluated at parse time; a wrong TARGET_DEVICE is caught
#    by scripts/verify.sh via get_build_var rather than here.)
# ---------------------------------------------------------------------------
