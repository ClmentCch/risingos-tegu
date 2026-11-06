# PROJECT_SPEC — RisingOS 9 tegu

Normative specification for the unofficial RisingOS Revived 9 build for Google Pixel 9a.

## 1. Identity

| Field | Value |
| --- | --- |
| Project name | RisingOS 9 tegu |
| ROM name | RisingOS Revived 9 |
| ROM flavour / codename | `CinnamonBun` / `elefthería` (from `vendor/rising/config/version.mk`) |
| Build type | `COMMUNITY` / unofficial (device is not in `vendor/official_devices`) |
| Android version | 17 (`android-17.0.0_r1` AOSP tag) |
| Rising branch | `seventeen` |
| Device baseline | LineageOS `lineage-24.0` |
| Device | Google Pixel 9a |
| Codename | `tegu` |
| SoC | Google Tensor G4 (`zumapro` platform) |
| Architecture | arm64 / arm64-v8a |
| Product name | `rising_tegu` |
| Lunch target | `rising_tegu-userdebug` (also `-user`, `-eng`) |
| Kernel | Linux 6.1, prebuilt (`device/google/tegu-kernels/6.1`) |

## 2. Non-goals

- Not an official RisingOS release; must never be labelled official.
- No device flashing or boot claims without a physical Pixel 9a test.
- No redistribution of proprietary blobs, Google apps or signing keys in this repository.
- No fabricated "successful build" output, logs or test reports.

## 3. Source composition (must all be real, pinned upstreams)

1. **RisingOS manifest** `RisingOS-Revived/android@seventeen` — provides the AOSP/LineageOS
   base manifest, Rising `snippets/rising.xml`, the Rising framework/SystemUI/Settings
   forks and `vendor/rising`.
2. **LineageOS tegu device tree** `LineageOS/android_device_google_tegu@lineage-24.0`.
3. **LineageOS zumapro platform tree** `LineageOS/android_device_google_zumapro@lineage-24.0`
   (Tensor G4 common; inherited by `device-tegu.mk`).
4. **Prebuilt kernel** `LineageOS/android_device_google_tegu-kernels@lineage-24.0`
   (`6.1` subdirectory referenced by `TARGET_KERNEL_DIR`).
5. **Vendor blobs** `TheMuppets/proprietary_vendor_google_tegu@lineage-24.0`
   (mounted at `vendor/google/tegu`, inherited by `tegu-vendor.mk`).
6. **This project** `ClmentCch/risingos-tegu@risingos-9-tegu`, checked out at
   `vendor/rising-tegu`, providing the `rising_tegu` product.

Pixel 8a (`akita`) or any other device's hardware configuration must never be used as a
substitute. Only `tegu`/`zumapro` inputs are permitted.

## 4. Integration requirements

- `rising_tegu.mk` MUST inherit `device/google/tegu/lineage_tegu.mk` first.
- `rising_tegu.mk` MUST inherit `vendor/rising/config/rising.mk`.
- `PRODUCT_NAME` MUST be `rising_tegu`, `PRODUCT_DEVICE` `tegu`, `PRODUCT_MODEL` `Pixel 9a`.
- Device build fingerprint overrides MUST come from the inherited LineageOS product; they
  MUST NOT be invented.
- `PRODUCT_BUILD_PROP_OVERRIDES` MUST carry `RisingChipset` and `RisingMaintainer`.
- Default package policy: vanilla (`WITH_GMS := false`, `WITH_MICROG := false`).
- Blur: `TARGET_ENABLE_BLUR := true` (supported by the Tensor G4 platform).

## 5. Reproducibility requirements

- Every upstream project pinned to a full 40-character commit SHA in
  `manifest/risingos-9-tegu.xml` (branches documented as the tracking ref).
- `scripts/setup.sh` and `scripts/sync.sh` must be idempotent.
- `scripts/verify.sh` must fail (non-zero) when a required path, revision or identity
  string is wrong.
- Build logs must be preserved under `logs/`; artifacts under `output/<timestamp>/` with
  `sha256sum` manifests.
- The build host must satisfy the upstream minimums (64 GB RAM, 400 GB free disk for
  Android 17). Scripts must refuse to start a build that cannot succeed and say why.

## 6. Acceptance criteria

| Criterion | Verification |
| --- | --- |
| Product resolves | `verify.sh` runs `get_build_var PRODUCT_NAME`/`TARGET_DEVICE` after lunch |
| Correct identity | `ro.rising.device`, `ro.rising.chipset`, `ro.build.product` in built image |
| RisingOS present | Rising Settings panels, SystemUI features and Rising apps in the image |
| Kernel present | `boot.img`/`vendor_boot.img` built from `tegu-kernels` prebuilt |
| Vendor present | `vendor/google/tegu` blobs included, `tegu-vendor.mk` parsed |
| Installable package | ZIP + `checksums.sha256`; **not tested on hardware** |
| No fake results | Build/validation status recorded honestly in `docs/SESSION_STATUS.md` |

## 7. Deliverables

- This repository: manifest, integration makefiles, scripts, docs, configs.
- On a capable host: `out/target/product/tegu/*.zip`, `boot.img`, `recovery.img`,
  `vendor_boot.img`, `dtbo.img`, checksums and build logs.
- Handoff state in `docs/SESSION_STATUS.md`, updated every session.
