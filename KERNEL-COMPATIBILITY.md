# RHEL 7 Kernel Compatibility Fix

## Problem
VS Code Server was failing with "FATAL: kernel too old" error because the toolchain was built expecting kernel 4.19+ but RHEL 7 runs kernel 3.10.x.

## Solution Applied
Updated the crosstool-ng configuration to use RHEL 7 compatible kernel versions:

```bash
# Before (incompatible)
CT_LINUX_VERSION="4.19.287"
CT_GLIBC_MIN_KERNEL="4.19.287"

# After (RHEL 7 compatible)
CT_LINUX_VERSION="3.10.108"
CT_GLIBC_MIN_KERNEL="3.10.0"
```

## Files Modified
- `x86_64-gcc-8.5.0-glibc-2.28.config` - Updated kernel compatibility settings
- `check-target-kernel.sh` - New utility to check target system compatibility

## Next Steps
1. **Rebuild the toolchain** with the new kernel-compatible configuration:
   ```bash
   make clean-output
   make build-toolchain
   ```

2. **Repackage the toolchain**:
   ```bash
   make package
   ```

3. **Test on your RHEL 7 system** - the "kernel too old" error should be resolved.

## For Future Use
Run `./check-target-kernel.sh` on any target system to generate appropriate kernel compatibility settings automatically.

## Technical Details
- **RHEL 7** uses Linux kernel 3.10.x series
- **glibc 2.28** can be built to support older kernels by setting `CT_GLIBC_MIN_KERNEL` appropriately
- **VS Code Server** requires glibc that can run on the target kernel version
- **Kernel 3.10.108** is a stable LTS version from the 3.10 series that crosstool-ng can download