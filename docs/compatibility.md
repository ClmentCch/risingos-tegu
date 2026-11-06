# Compatibility matrix

## Version alignment

| Layer | Version / branch | Evidence |
| --- | --- | --- |
| Android platform | 17 | Rising manifest `aosp` remote: `refs/tags/android-17.0.0_r1` |
| RisingOS | Revived 9 (`RISING_VERSION := 9`, `CinnamonBun`) | `vendor/rising/config/version.mk` @ `seventeen` |
| RisingOS manifest | `seventeen` @ `4197174e43f84deaadccfd8b980aeb73fb47d84d` | `git ls-remote` |
| LineageOS baseline | `lineage-24.0` (Android 17) | Rising manifest `<default revision>`; tegu branch |
| Device tree | `lineage-24.0` @ `0df2d90b…` | `git ls-remote`, raw file reads |
| Platform tree | `zumapro` `lineage-24.0` @ `c03df81e…` | tegu `lineage.dependencies`, `device-tegu.mk` |
| Kernel | Linux 6.1 prebuilt @ `06318d99…` | `device-tegu.mk`, `tegu-kernels` |
| Vendor blobs | `lineage-24.0` @ `6840f692…` | `tegu-vendor.mk` |
| Firmware baseline | `CP3A.261005.005` (Android 17) | tegu `lineage_tegu.mk` fingerprint overrides |
| Shipping API level | 35 (device ships Android 15, upgraded to 17) | `device-tegu.mk` |

## Branch compatibility rationale

- RisingOS `seventeen` is built on the LineageOS `lineage-24.0` project revisions by
  default, so no cross-branch rebase of the device tree is required.
- The tegu device tree has no `seventeen` branch of its own — LineageOS devices use
  `lineage-24.0`, which is exactly what the Rising manifest resolves.
- Rising's vendor layer replaces `vendor/lineage` with its own fork; tegu's
  `lineage_tegu.mk` inherits `vendor/lineage/config/common_full_phone.mk`, which resolves to
  the Rising fork and therefore pulls Rising's GMS/telephony/one-handed-mode config. This is
  the expected RisingOS device pattern.

## Hardware feature coverage

| Feature | Source | Status |
| --- | --- | --- |
| Tensor G4 SoC / `zumapro` platform | `device/google/zumapro` | present upstream |
| Kernel 6.1 / 16 KB page option | `tegu-kernels/6.1` | present upstream |
| Display 1080×2424 | tegu overlays | present upstream |
| Camera (Pixel camera HAL / Aperture) | vendor blobs + `ApertureOverlayTegu` | present upstream |
| NFC | `PixelNfcOverlayTegu` + blobs | present upstream |
| Modem / telephony / satellite | blobs + `android.hardware.telephony.satellite.xml` | present upstream |
| Fingerprint/biometrics | vendor HALs | present upstream |
| Recovery (LineageOS recovery) | `bootable/recovery` + tegu recovery rc | present upstream |
| Blur | `TARGET_ENABLE_BLUR := true` (this project) | integration choice |
| Rising customisation panels | `vendor/rising` + Rising framework | present upstream |

## Known incompatibilities

| Item | Detail |
| --- | --- |
| Official RisingOS status | `tegu` is not in `vendor/official_devices`; builds are `COMMUNITY`. Do not present as official. |
| Google apps | Not bundled (`WITH_GMS := false`); Play Services/Play Store absent by default. |
| Google hardware attestation | Unofficial builds cannot pass `MEETS_STRONG_INTEGRITY`; banking/DRM apps may refuse. |
| OTA | Rising's OTA/`vendor/official_devices` pipeline is for official devices; this project does not ship OTA updates. |
| Other Pixel 8/9 trees | `akita` (Pixel 8a) and others are not interchangeable with tegu. Verified absent. |
