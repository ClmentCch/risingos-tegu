# Source audit — verified 2026-11-06

Method: GitHub REST API (repository metadata, branch lists) and `git ls-remote` for exact
commit IDs, plus raw retrieval of the referenced manifests/makefiles to confirm the
declared inheritance and paths. No repository was assumed to exist; each was checked.

## RisingOS

| Check | Result |
| --- | --- |
| Organisation | `https://github.com/RisingOS-Revived` (exists, not archived) |
| Manifest repository | `RisingOS-Revived/android` — default branch **seventeen** |
| Manifest revision | `4197174e43f84deaadccfd8b980aeb73fb47d84d` |
| Manifest branches present | `fifteen`, `seventeen`, `sixteen`, `sixteen-qpr2`, `qpr2` |
| Init command (from README) | `repo init -u https://github.com/RisingOS-Revived/android -b seventeen --git-lfs` |
| AOSP base tag | `refs/tags/android-17.0.0_r1` (Android 17) |
| Default project revision | `refs/heads/lineage-24.0` |
| Includes | `snippets/rising.xml`, `snippets/extra.xml`, `snippets/lineage.xml` |
| Rising remote | `https://github.com/RisingOS-Revived`, revision `refs/heads/seventeen` |
| Vendor layer | `RisingOS-Revived/android_vendor_rising@seventeen` — `config/rising.mk`, `config/version.mk`, `overlays/`, `prebuilts/` confirmed |
| Lineage config layer | `RisingOS-Revived/android_vendor_lineage@seventeen` — `config/common_full_phone.mk` confirmed |
| Rising version | `RISING_VERSION := 9`, `RISING_FLAVOR := CinnamonBun`, `RISING_CODENAME := elefthería` |
| Official devices list | `RisingOS-Revived/official_devices` pinned by the Rising manifest to branch `fifteen`; `tegu` absent → `RISING_BUILDTYPE=COMMUNITY` |
| Framework / SystemUI / Settings | supplied by the Rising forks pinned in `snippets/rising.xml` (`android_frameworks_base`-class projects, `android_packages_apps_Settings`, `android_frameworks_libs_systemui`, `android_lineage-sdk`, …) |

## LineageOS device foundation (tegu)

| Check | Result |
| --- | --- |
| Device tree | `LineageOS/android_device_google_tegu` — default branch `lineage-24.0` |
| Branches | `lineage-23.0`, `lineage-23.1`, `lineage-23.2`, `lineage-24.0` |
| Pinned revision | `0df2d90b48370375f154ac7cf0bee96d1f372074` |
| Files verified | `AndroidProducts.mk`, `aosp_tegu.mk`, `lineage_tegu.mk`, `device-tegu.mk`, `extract-files.py`, `lineage.dependencies`, 148 tracked files |
| `lineage.dependencies` | `LineageOS/android_device_google_zumapro` → `device/google/zumapro`; `LineageOS/android_device_google_tegu-kernels` → `device/google/tegu-kernels` |
| Kernel wiring | `TARGET_LINUX_KERNEL_VERSION := 6.1`; `TARGET_KERNEL_DIR := device/google/tegu-kernels/6.1`; `TARGET_KERNEL_PLATFORM_SOURCE := google/gs-6.1` |
| Product identity | `PRODUCT_MODEL := Pixel 9a`, `SHIPPING_API_LEVEL := 35`, `PRODUCT_NAME := lineage_tegu` |
| Build fingerprint | `google/tegu/tegu:17/CP3A.261005.005/16271449:user/release-keys` |
| Recovery | `device/google/tegu/recovery/init.recovery.device.rc`, `init.recovery.tegu.touch.rc` |
| Platform common | `LineageOS/android_device_google_zumapro@lineage-24.0` — `c03df81e8fed84aeb4f2d26e9cef2ea5762d7c3f`; `common.mk` includes `TARGET_BOARD_PLATFORM := zumapro`, hardware/google/{av,interfaces,pixel} namespaces |
| Prebuilt kernel | `LineageOS/android_device_google_tegu-kernels@lineage-24.0` — `06318d991a4a688cf281d69815143a8370e503b4` |
| Vendor blobs | `TheMuppets/proprietary_vendor_google_tegu@lineage-24.0` — `6840f69264a3191a3be83816b950ecec4c4d88f1`; `tegu-vendor.mk` verified (adds `vendor/google/tegu` namespace and copy rules) |
| LineageOS wiki | `https://wiki.lineageos.org/devices/tegu/build/` reachable; states 64 GB RAM and 400 GB storage for `lineage-21`+ |

## Negative results (recorded so they are not retried blindly)

| Probed | Result |
| --- | --- |
| `LineageOS/android_kernel_google_gs`, `android_kernel_google_gs101`, `android_device_google_tegu-kernel` | do not exist (no refs returned) — the kernel ships prebuilt via `tegu-kernels` |
| `TheMuppets/proprietary_vendor_google_zumapro` | not accessible (no such public repository); only `vendor/google/tegu` is required by the tegu product |
| `RisingOS-Revived/vendor_rising` | does not exist; the correct name is `android_vendor_rising` |
| `official_devices` branch `seventeen` | does not exist; upstream manifest pins `fifteen` |

## Compatibility conclusion

- RisingOS `seventeen` targets Android 17 and defaults to `lineage-24.0` project revisions —
  the same branch as the tegu device tree. Branch-level compatibility is aligned.
- The tegu tree's fingerprint (`CP3A.261005.005`, Android 17) matches the Rising base's
  Android 17 tag generation; the vendor blobs and prebuilt kernel come from the same
  LineageOS branch, so the foundation is internally consistent.
- No akita/Pixel 8a source is used anywhere.

## Reproducibility caveats

1. `vendor/lineage` is pinned by revision name (`refs/heads/seventeen`) because the Rising
   manifest already defines that project; a SHA pin in a local manifest for the same project
   would be overridden or conflict. Upstream movement of that branch is therefore possible.
2. `vendor/official_devices` is pinned upstream to `fifteen`; it only affects build-type
   classification.
3. The RisingOS manifest itself is consumed from branch `seventeen` at init time; its
   current HEAD was recorded (`4197174e…`) but `repo init -b` is a moving reference. For a
   byte-reproducible build, snapshot the manifest repo at that SHA and re-init from it.
4. Proprietary blobs are firmware-derived and versioned by TheMuppets, not by this project.
