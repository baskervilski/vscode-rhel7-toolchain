# Install Script Documentation

## Overview

The `install-toolchain.sh` script is a **static script** that provides a complete **offline installation** experience for the RHEL7 sysroot toolchain on target servers.

## Benefits of Static Script Approach

- **Better maintainability**: Logic is in a readable shell script, not embedded in Makefile
- **Version control friendly**: Script changes are clearly visible in git diffs
- **Easier testing**: Can test the script independently
- **Self-documenting**: Contains all the installation logic in one place
- **No generation required**: Ready to use, no dynamic creation needed

## Script Features

- ✅ **Safe installation**: Installs to isolated directory (default: `/opt/rhel7-sysroot`)
- ✅ **Offline patchelf**: Uses bundled patchelf, no internet required
- ✅ **Environment setup**: Creates VS Code Remote SSH environment variables
- ✅ **Configuration generation**: Creates C/C++ configuration for VS Code IntelliSense
- ✅ **User-friendly output**: Clear progress indicators and next steps
- ✅ **Error handling**: Validates all archives exist before attempting installation

## Usage

```bash
# Default installation to /opt/rhel7-sysroot
./install-toolchain.sh

# Custom installation directory
./install-toolchain.sh /path/to/custom/location
```

## Files Created

- `/opt/rhel7-sysroot/` - Toolchain installation
- `/usr/local/bin/patchelf` - patchelf binary for VS Code
- `~/vscode-server-env.sh` - Environment variables script
- `~/.bashrc` - Updated with VS Code environment
- `vscode-cpp-config.json` - VS Code C/C++ configuration

## Integration with Makefile

The Makefile `package` target simply copies the static script:

```makefile
package:
    # ... create archive ...
    @cp install-toolchain.sh $(EXPORT_DIR)/
    @chmod +x $(EXPORT_DIR)/install-toolchain.sh
```

This is much cleaner than the previous approach of generating the script dynamically with dozens of `@echo` commands.