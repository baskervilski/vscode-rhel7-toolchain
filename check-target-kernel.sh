#!/bin/bash
# Check target system kernel and generate compatibility patch

echo "=== Target System Kernel Check ==="
echo ""

# Check kernel version
KERNEL_VERSION=$(uname -r)
KERNEL_MAJOR=$(echo $KERNEL_VERSION | cut -d. -f1)
KERNEL_MINOR=$(echo $KERNEL_VERSION | cut -d. -f2)
KERNEL_PATCH=$(echo $KERNEL_VERSION | cut -d. -f3 | cut -d- -f1)

echo "🔍 Detected kernel version: $KERNEL_VERSION"
echo "📊 Parsed version: $KERNEL_MAJOR.$KERNEL_MINOR.$KERNEL_PATCH"

# Check glibc version
GLIBC_VERSION=$(ldd --version 2>/dev/null | head -n1 | grep -o '[0-9]\+\.[0-9]\+' || echo "Unknown")
echo "📚 Current glibc version: $GLIBC_VERSION"

# Determine appropriate kernel version for crosstool-ng
# Use a stable kernel version from the same major.minor series
case "$KERNEL_MAJOR.$KERNEL_MINOR" in
    "3.10")
        RECOMMENDED_KERNEL="3.10.108"
        ;;
    "4.18")
        RECOMMENDED_KERNEL="4.18.0"
        ;;
    "5.4")
        RECOMMENDED_KERNEL="5.4.260"
        ;;
    *)
        RECOMMENDED_KERNEL="$KERNEL_MAJOR.$KERNEL_MINOR.0"
        ;;
esac

echo ""
echo "=== Recommended Crosstool-NG Configuration ==="
echo "Target kernel series: $KERNEL_MAJOR.$KERNEL_MINOR.x"
echo "Recommended build kernel: $RECOMMENDED_KERNEL"
echo "Minimum kernel for glibc: $KERNEL_MAJOR.$KERNEL_MINOR.0"

# Generate config update patch
echo ""
echo "=== Auto-Generated Config Update ==="
cat > kernel-config.patch << EOF
# Kernel compatibility settings for RHEL 7 (kernel $KERNEL_VERSION)
# Generated on $(date)
CT_LINUX_VERSION="$RECOMMENDED_KERNEL"
CT_GLIBC_MIN_KERNEL="$KERNEL_MAJOR.$KERNEL_MINOR.0"
EOF

echo "✅ Config patch created: kernel-config.patch"
echo ""
echo "📋 To apply this configuration:"
echo "   1. Copy kernel-config.patch to your build system"
echo "   2. Run: make clean-output && make build-toolchain"
echo ""
echo "💡 This will ensure your toolchain is compatible with kernel $KERNEL_VERSION"