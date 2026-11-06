# output/

Receive directory for build artifacts produced by `scripts/package.sh`.

```
output/<UTC timestamp>/
├── RisingOS-9-tegu-<date>.zip      # flashable package (when the ROM is built)
├── boot.img                       # kernel/ramdisk
├── recovery.img                   # LineageOS recovery
├── vendor_boot.img                # vendor ramdisk + kernel fragments
├── dtbo.img                       # device tree blobs
├── metadata.json                  # project/device/version/commit/build info
└── checksums.sha256               # SHA-256 of every artifact above
```

Artifacts are **git-ignored** (see `.gitignore`). They are distributed through GitHub
Releases, never committed to the repository. No artifact exists yet: the ROM has not been
compiled (see `docs/SESSION_STATUS.md`).
