# Install Script Documentation for Python Development

## Overview

The `install-toolchain.sh` script provides a complete **offline installation** experience for enabling **VS Code Remote SSH** on RHEL 7 servers for **Python development**.

## Benefits of Static Script Approach

- **Better maintainability**: Logic is in a readable shell script, not embedded in Makefile
- **Version control friendly**: Script changes are clearly visible in git diffs
- **Easier testing**: Can test the script independently of container builds
- **Self-documenting**: Contains all the installation logic in one place
- **Production ready**: Designed for deployment on real RHEL 7 servers

## Script Features for Python Development

- ✅ **Safe installation**: Installs to isolated directory (default: `/opt/rhel7-sysroot`)
- ✅ **Offline patchelf**: Uses bundled patchelf, no internet required on target server
- ✅ **VS Code compatibility**: Creates environment variables for VS Code Remote SSH
- ✅ **Python focused**: No unnecessary C/C++ configuration bloat
- ✅ **User-friendly output**: Clear progress indicators and next steps
- ✅ **Error handling**: Validates all archives exist before attempting installation

## Usage

```bash
# Default installation to /opt/rhel7-sysroot
./install-toolchain.sh

# Custom installation directory
./install-toolchain.sh /path/to/custom/location
```

## Files Created for Python Development

- `/opt/rhel7-sysroot/` - Sysroot with modern glibc 2.28 (VS Code compatibility)
- `/usr/local/bin/patchelf` - patchelf binary for VS Code server dynamic linking
- `~/vscode-server-env.sh` - Environment variables script for VS Code
- `~/.bashrc` - Updated with VS Code environment (sourced automatically)

**Note**: No C/C++ configuration files are created - this setup is optimized for Python development only.

## Integration with Makefile

The Makefile `package` target simply copies the static script:

```makefile
package:
    # ... create archive ...
    @cp install-toolchain.sh $(EXPORT_DIR)/
    @chmod +x $(EXPORT_DIR)/install-toolchain.sh
```

This is much cleaner than the previous approach of generating the script dynamically with dozens of `@echo` commands.