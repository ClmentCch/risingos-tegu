# vendor/rising-tegu — in-tree Rising product for Pixel 9a

This directory is checked out by `repo` at `vendor/rising-tegu` inside the Android tree.

| File | Role |
| --- | --- |
| `AndroidProducts.mk` | Makes `rising_tegu` discoverable (`build/make` globs `vendor/*/*/AndroidProducts.mk`). |
| `rising_tegu.mk` | The product: inherits the LineageOS tegu foundation, then the RisingOS layer, then sets identity/props. |

## Why a vendor-side product instead of editing the device tree

- The LineageOS device tree stays pristine and updatable (`lineage-24.0` can be synced
  without merge conflicts).
- RisingOS is layered as a software product on top of the device foundation — the
  framework, SystemUI, Settings and system apps come from the Rising forks that the Rising
  manifest pins, not from applying a "patch" on LineageOS.
- Nothing here reimplements hardware support: kernel, HALs, firmware compatibility and
  recovery all come from the upstream tegu/zumapro trees.

## Inheritance order (important)

```
vendor/rising-tegu/rising_tegu.mk
├── device/google/tegu/lineage_tegu.mk
│   ├── vendor/lineage/config/common_full_phone.mk
│   ├── device/google/tegu/aosp_tegu.mk
│   │   ├── device/google/zumapro/aosp_common.mk
│   │   └── device/google/tegu/device-tegu.mk
│   │       └── include device/google/zumapro/common.mk
│   ├── vendor/google/tegu/tegu-vendor.mk        (proprietary blobs)
│   └── build fingerprint / build description overrides for tegu
└── vendor/rising/config/rising.mk
    ├── vendor/rising/config/properties.mk
    ├── vendor/rising/config/packages.mk
    ├── vendor/rising/config/version.mk          (Rising 9, CinnamonBun)
    ├── vendor/rising/overlays/build.mk
    └── vendor/rising/prebuilts/prebuilts.mk
```

`PRODUCT_NAME := rising_tegu` must stay **after** both inherit calls.

## Verifying it resolves

```bash
. build/envsetup.sh
lunch rising_tegu-userdebug
get_build_var PRODUCT_NAME     # rising_tegu
get_build_var TARGET_DEVICE    # tegu
get_build_var PRODUCT_MODEL    # Pixel 9a
```

`scripts/verify.sh` performs these checks automatically (when run on a synced tree).
