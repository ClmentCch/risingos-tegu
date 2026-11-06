# patches/

## Current state: no source patches are required

The RisingOS 9 tegu integration is achieved **without patching upstream sources**:

- Rising framework, SystemUI, Settings, launcher, customization panels and system apps
  come from the RisingOS forks that `RisingOS-Revived/android@seventeen` pins via
  `snippets/rising.xml`. There is nothing to patch: they *are* the build.
- The device foundation is untouched: `device/google/tegu` is used as-is.
- The product is added beside the tree (`vendor/rising-tegu/AndroidProducts.mk`), which
  `build/make` discovers automatically (`vendor/*/*/AndroidProducts.mk`), so no
  `device/google/tegu/AndroidProducts.mk` edit is needed.

Fabricating patches for `framework/`, `systemui/` or `settings/` would misrepresent the
project, so those directories are intentionally absent until a real conflict is found.

## When a patch becomes necessary

1. Reproduce the real build failure on a capable host and capture the log excerpt.
2. Create the patch as a proper diff against the **pinned** revision:
   ```bash
   cd <tree>/<project>
   git format-patch -1 --stdout > ../../patches/<area>/0001-<slug>.patch
   ```
   Keep `Subject:`, `From:` and a body explaining the failure and fix.
3. Register it for application:
   - add the path to `PATCHES` in `scripts/sync.sh` (applied with `git apply --check`
     first, so a bad patch fails the sync instead of silently corrupting the tree), and
   - document it in this file with area, target project, revision, reason and upstream
     status (sent upstream / device-only).
4. Add a regression check to `scripts/verify.sh` where feasible.
5. Update `docs/SESSION_STATUS.md`.

## Areas

| Directory | Target |
| --- | --- |
| `patches/device/` | `device/google/tegu` |
| `patches/build/` | `build/make`, `build/soong` |
| `patches/framework/` | `frameworks/base` |
| `patches/systemui/` | `frameworks/base/packages/SystemUI` |
| `patches/settings/` | `packages/apps/Settings` |

Only create a subdirectory when it contains at least one real, tested patch.
