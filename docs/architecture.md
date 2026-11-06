# Architecture — RisingOS 9 tegu

## Layer model

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ RisingOS Revived 9 software layer          (source: RisingOS-Revived@seventeen)│
│  frameworks/base (Rising fork)  ·  SystemUI  ·  Settings  ·  LineageParts     │
│  Personalizations  ·  RisingWalls  ·  Launcher3  ·  GameSpace  ·  BtHelper     │
│  vendor/rising/config/{rising,properties,packages,version,overlays,prebuilts}  │
├──────────────────────────────────────────────────────────────────────────────┤
│ Product integration                        (source: this repo, vendor/rising-tegu)│
│  AndroidProducts.mk  ·  rising_tegu.mk                                        │
│  inherit(device/google/tegu/lineage_tegu.mk) + inherit(vendor/rising/…/rising.mk)│
├──────────────────────────────────────────────────────────────────────────────┤
│ Device foundation                          (source: LineageOS@lineage-24.0)     │
│  device/google/tegu       product, overlays, recovery, props, fingerprint      │
│  device/google/zumapro    Tensor G4 common platform, HAL wiring                │
│  device/google/tegu-kernels/6.1   prebuilt kernel + DTBO inputs                │
│  vendor/google/tegu       proprietary blobs (tegu-vendor.mk)                   │
├──────────────────────────────────────────────────────────────────────────────┤
│ Android 17 platform                        (source: AOSP android-17.0.0_r1)    │
└──────────────────────────────────────────────────────────────────────────────┘
```

The ROM is RisingOS because the framework, SystemUI, Settings and system apps are compiled
from the RisingOS forks pinned by the Rising manifest. The device foundation is LineageOS
tegu, used unmodified. This project contributes the **product composition** and the build
contract between the two — not a reimplementation of either.

## Boot and image flow

1. Bootloader (unlocked) loads `boot.img` (6.1 kernel from `tegu-kernels`) and
   `vendor_boot.img` (vendor ramdisk with first-stage init and tegu modules/fragments).
2. `dtbo.img` supplies the device tree overlays for tegu hardware.
3. First-stage init mounts dynamic partitions (`super`) containing `system`,
   `system_ext`, `product`, `vendor`, `odm`.
4. `vendor/google/tegu` blobs provide the Tensor G4 HALs (camera, display, audio, modem,
   biometrics, NFC, power/thermal).
5. RisingOS framework/SystemUI start from `system`/`product`; Rising's overlays
   (RRO) are enabled at boot through `vendor/rising/overlays/build.mk`.
6. Recovery: LineageOS recovery is built from `bootable/recovery` (Rising fork) plus
   tegu's `init.recovery.device.rc` and touch configuration.

## Product resolution

`build/make` discovers product makefiles by globbing `device/*/*/AndroidProducts.mk` and
`vendor/*/*/AndroidProducts.mk`. Because this project is checked out at
`vendor/rising-tegu`, its `AndroidProducts.mk` is picked up and exposes:

```
rising_tegu-userdebug / rising_tegu-user / rising_tegu-eng
```

`PRODUCT_NAME := rising_tegu` is declared after both inherit calls, so:

- device identity (kernel, vendor, fingerprint, partition layout) comes from tegu;
- software identity (framework features, packages, version metadata) comes from Rising.

`vendor/rising/config/version.mk` computes `RISING_BUILDTYPE` from
`vendor/official_devices/OTA/risingOS.devices`; `tegu` is not listed, so the build is
`COMMUNITY`. This is the intended unofficial classification and is visible in the build
banner/metadata.

## Why no source patches

See `patches/README.md`. The layering is achieved by product inheritance, which is how
RisingOS expects devices to be integrated. Patching the device tree or the framework would
add maintenance cost without changing the composition; upstream RisingOS already carries the
framework/SystemUI/Settings modifications.

## Failure containment

- `scripts/verify.sh` catches: missing projects, revision drift, inheritance regressions,
  wrong product identity, accidental akita (Pixel 8a) sources.
- `scripts/build.sh` refuses to run a build that cannot succeed and logs to `logs/`.
- `scripts/package.sh` fails when no installable ZIP exists, so a "package" cannot be
  reported without a real artifact.
