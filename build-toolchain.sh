#!/bin/bash
# Build script for mounted toolchain output

set -e

echo "=== Crosstool-NG Build Script ==="
echo "Output directory: /home/ctng/output"
echo "Configuration: x86_64-gcc-8.5.0-glibc-2.28.config"
echo ""

OUTPUT_DIRNAME=/home/ctng/output
# Load the configuration
echo "Loading configuration..."
cp x86_64-gcc-8.5.0-glibc-2.28.config $OUTPUT_DIRNAME/.config
cd $OUTPUT_DIRNAME

# Show configuration summary
echo ""
echo "=== Build Configuration ==="
echo "Target: $(grep CT_TARGET .config | cut -d= -f2 | tr -d '"')"
echo "GCC Version: $(grep CT_GCC_VERSION .config | cut -d= -f2 | tr -d '"')"
echo "Glibc Version: $(grep CT_GLIBC_VERSION .config | cut -d= -f2 | tr -d '"')"
echo "Output Directory: $(grep CT_PREFIX_DIR .config | cut -d= -f2 | tr -d '"')"
echo ""

echo "Starting build (this will take 30-60 minutes)..."
echo "Build started at: $(date)"

# Build the toolchain
ct-ng build

echo ""
echo "Build completed at: $(date)"
echo "Toolchain installed to: $OUTPUT_DIRNAME"
echo ""
echo "Contents:"
ls -la $OUTPUT_DIRNAME/

echo ""
echo "✅ Toolchain build completed successfully!"
echo "The toolchain is now available in the mounted output directory."