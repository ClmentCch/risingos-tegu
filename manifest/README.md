# manifest/

`risingos-9-tegu.xml` is a **repo local manifest**. It does not replace the RisingOS
manifest; it sits next to it in `.repo/local_manifests/` and pins the device-specific and
project-specific projects.

## How it is installed

`scripts/setup.sh` copies (or updates) this file to:

```
$ANDROID_ROOT/.repo/local_manifests/risingos-9-tegu.xml
```

`scripts/sync.sh` re-installs it before every sync, so edits in the repository always win.

## Bootstrap sequence

```bash
repo init -u https://github.com/RisingOS-Revived/android -b seventeen --git-lfs
# then the local manifest is installed by scripts/setup.sh or scripts/sync.sh
repo sync -c --no-clone-bundle --optimized-fetch --prune --force-sync -j8
```

`--git-lfs` is required by the RisingOS manifest (large binary assets in the Rising overlays
and prebuilts).

## Pinning policy

- Device, kernel, vendor and Rising vendor projects are pinned to **full 40-character
  commit SHAs** verified with `git ls-remote` at project creation.
- `vendor/lineage` is pinned to `refs/heads/seventeen` because RisingOS's own manifest
  already defines it; pinning a SHA here as well would require syncing after every upstream
  bump, and the Rising manifest already tracks that branch. This is recorded as a
  reproducibility caveat in `docs/source-audit.md`.
- When updating any revision: update this file **and** `config/sources.json`, then record
  the old/new SHA and the reason in `docs/source-audit.md`.

## Overrides the RisingOS manifest already provides

The Rising manifest sets:

```xml
<remote name="aosp" fetch="https://android.googlesource.com"
        revision="refs/tags/android-17.0.0_r1" />
<default revision="refs/heads/lineage-24.0" remote="github" sync-c="true" sync-j="4" />
<include name="snippets/rising.xml" />   <!-- Rising forks, vendor/rising, vendor/lineage -->
<include name="snippets/extra.xml" />
<include name="snippets/lineage.xml" />
```

so device/kernel AOSP projects, the Rising framework forks and `vendor/official_devices`
(used by `vendor/rising/config/version.mk`) all come from upstream. This local manifest only
adds/pins what is tegu-specific.
