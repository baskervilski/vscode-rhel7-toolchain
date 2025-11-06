#!/bin/bash
# Uninstall script for RHEL7 sysroot toolchain
# Safely removes the user-space toolchain installation

set -e

# Default installation directory
INSTALL_DIR=${1:-$HOME/rhel7-sysroot}
USER_BIN_DIR="$HOME/bin"

echo "=== RHEL7 Sysroot Toolchain Uninstaller ==="
echo "This will remove the isolated sysroot toolchain installation."
echo "System gcc and applications will NOT be affected."
echo ""

# Detect architecture from existing installation
TOOLCHAIN_PREFIX=""
if [ -d "$INSTALL_DIR" ]; then
    if [ -d "$INSTALL_DIR/x86_64-linux-gnu" ]; then
        TOOLCHAIN_PREFIX="x86_64-linux-gnu"
        ARCH="x86_64"
    elif [ -d "$INSTALL_DIR/i686-linux-gnu" ]; then
        TOOLCHAIN_PREFIX="i686-linux-gnu"
        ARCH="i386"
    elif [ -d "$INSTALL_DIR/aarch64-linux-gnu" ]; then
        TOOLCHAIN_PREFIX="aarch64-linux-gnu"
        ARCH="aarch64"
    else
        echo "⚠️  Cannot detect toolchain architecture in $INSTALL_DIR"
        echo "Contents:"
        ls -la "$INSTALL_DIR" 2>/dev/null || echo "Directory not accessible"
    fi
else
    echo "ℹ️  Installation directory not found: $INSTALL_DIR"
fi

echo "Installation directory: $INSTALL_DIR"
if [ -n "$TOOLCHAIN_PREFIX" ]; then
    echo "Detected architecture: $ARCH ($TOOLCHAIN_PREFIX)"
fi
echo "User bin directory: $USER_BIN_DIR"
echo ""

# Confirm removal
read -p "❓ Are you sure you want to uninstall the toolchain? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Uninstallation cancelled."
    exit 0
fi

echo ""
echo "🗑️  Starting uninstallation..."

# Remove main installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "📁 Removing toolchain directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo "✅ Toolchain directory removed"
else
    echo "ℹ️  Toolchain directory not found (already removed)"
fi

# Remove patchelf from user bin
if [ -f "$USER_BIN_DIR/patchelf" ]; then
    echo "🔧 Removing patchelf: $USER_BIN_DIR/patchelf"
    rm -f "$USER_BIN_DIR/patchelf"
    echo "✅ patchelf removed"
else
    echo "ℹ️  patchelf not found in user bin directory"
fi

# Remove VS Code environment script
if [ -f "$HOME/vscode-server-env.sh" ]; then
    echo "🌍 Removing VS Code environment script: ~/vscode-server-env.sh"
    rm -f "$HOME/vscode-server-env.sh"
    echo "✅ VS Code environment script removed"
else
    echo "ℹ️  VS Code environment script not found"
fi

# Remove environment setup from bashrc
if [ -f "$HOME/.bashrc" ]; then
    echo "📝 Cleaning VS Code environment from ~/.bashrc"
    
    # Create a backup
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Remove lines related to vscode-server-env.sh
    sed -i '/# VS Code Remote SSH with custom glibc sysroot/d' "$HOME/.bashrc"
    sed -i '/source.*vscode-server-env\.sh/d' "$HOME/.bashrc"
    sed -i '/vscode-server-env\.sh/d' "$HOME/.bashrc"
    
    echo "✅ ~/.bashrc cleaned (backup created)"
else
    echo "ℹ️  ~/.bashrc not found"
fi

# Remove user bin directory from PATH if it's empty
if [ -d "$USER_BIN_DIR" ]; then
    if [ -z "$(ls -A "$USER_BIN_DIR" 2>/dev/null)" ]; then
        echo "📁 Removing empty user bin directory: $USER_BIN_DIR"
        rmdir "$USER_BIN_DIR" 2>/dev/null || echo "⚠️  Could not remove $USER_BIN_DIR (not empty or permission issue)"
        
        # Also remove PATH modification from bashrc if directory is removed
        if [ ! -d "$USER_BIN_DIR" ] && [ -f "$HOME/.bashrc" ]; then
            sed -i "/export PATH.*$(echo $USER_BIN_DIR | sed 's/[[\.*^$()+?{|]/\\&/g')/d" "$HOME/.bashrc"
            sed -i '/# Add user bin directory to PATH/d' "$HOME/.bashrc"
            echo "✅ PATH modification removed from ~/.bashrc"
        fi
    else
        echo "ℹ️  User bin directory not empty, keeping: $USER_BIN_DIR"
        echo "Contents:"
        ls -la "$USER_BIN_DIR"
    fi
fi

# Clean up any remaining installation files in current directory
echo "🧹 Cleaning up installation files in current directory..."
rm -f rhel7-toolchain-*.tar.gz patchelf-*.tar.gz install-toolchain.sh 2>/dev/null || true

echo ""
echo "✅ RHEL7 Sysroot Toolchain uninstallation completed!"
echo ""
echo "📋 Summary:"
echo "   ✅ Toolchain removed from: $INSTALL_DIR"
echo "   ✅ patchelf removed from: $USER_BIN_DIR"
echo "   ✅ VS Code environment configuration removed"
echo "   ✅ ~/.bashrc cleaned (backup created)"
echo ""
echo "⚠️  IMPORTANT:"
echo "   • Restart your SSH session or run: source ~/.bashrc"
echo "   • VS Code Remote SSH will now fail (back to system glibc)"
echo "   • System gcc and applications are unaffected"
echo ""
echo "💡 To reinstall: Run install-toolchain.sh again with the toolchain archive"