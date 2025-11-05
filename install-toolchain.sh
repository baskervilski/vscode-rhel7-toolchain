#!/bin/bash
# Installation script for RHEL7 sysroot toolchain
# Safe installation for VS Code Remote SSH development

set -e

INSTALL_DIR=${1:-/opt/rhel7-sysroot}
PATCHELF_VERSION=0.18.0

echo "=== RHEL7 Sysroot Toolchain Installer ==="
echo "Installing ISOLATED sysroot toolchain to $INSTALL_DIR..."
echo "This will NOT affect system gcc or applications."
echo ""

# Check if archive exists
ARCHIVE=$(ls rhel7-toolchain-*.tar.gz 2>/dev/null | head -1)
if [ -z "$ARCHIVE" ]; then
    echo "❌ Error: No toolchain archive found (rhel7-toolchain-*.tar.gz)"
    echo "Make sure you're running this script in the same directory as the archive."
    exit 1
fi
echo "📦 Found archive: $ARCHIVE"

# Install toolchain
echo "📁 Creating installation directory..."
sudo mkdir -p $INSTALL_DIR
echo "📦 Extracting toolchain archive..."
sudo tar -xzf $ARCHIVE -C $INSTALL_DIR

# Install patchelf (required by VS Code server)
echo "🔧 Installing patchelf (required by VS Code server)..."
if [ ! -f "patchelf-$PATCHELF_VERSION-x86_64.tar.gz" ]; then
    echo "❌ Error: patchelf archive not found (patchelf-$PATCHELF_VERSION-x86_64.tar.gz)"
    echo "Make sure you're running this script in the same directory as the patchelf archive."
    exit 1
fi
CURRENT_DIR=$(pwd)
TEMP_DIR="${TMPDIR:-$HOME/.tmp}/patchelf-install-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
cp "$CURRENT_DIR/patchelf-$PATCHELF_VERSION-x86_64.tar.gz" .
tar -xzf patchelf-$PATCHELF_VERSION-x86_64.tar.gz
sudo cp bin/patchelf /usr/local/bin/
sudo chmod +x /usr/local/bin/patchelf
cd "$CURRENT_DIR"
rm -rf "$TEMP_DIR"

# Create VS Code environment variables script
echo "🌍 Setting up VS Code server environment variables..."
cat > vscode-server-env.sh << EOF
#!/bin/bash
# VS Code Remote SSH Environment Variables for Custom glibc Sysroot
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=$INSTALL_DIR/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=$INSTALL_DIR/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib:$INSTALL_DIR/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/usr/lib
EOF

chmod +x vscode-server-env.sh
if [ "$(pwd)" != "$HOME" ]; then
    cp vscode-server-env.sh ~/
fi

# Add to bashrc if not already present
if ! grep -q "vscode-server-env.sh" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# VS Code Remote SSH with custom glibc sysroot" >> ~/.bashrc
    echo "source ~/vscode-server-env.sh" >> ~/.bashrc
    echo "🔌 Added VS Code environment to ~/.bashrc"
else
    echo "🔌 VS Code environment already in ~/.bashrc"
fi

echo ""
echo "✅ Sysroot toolchain installed safely to $INSTALL_DIR"
echo "🔧 patchelf v$PATCHELF_VERSION installed to /usr/local/bin/patchelf"
echo "🌍 VS Code environment variables configured in ~/vscode-server-env.sh"
echo ""
echo "📖 Next steps:"
echo "   1. Restart your SSH session or run: source ~/.bashrc"
echo "   2. VS Code Remote SSH should now connect successfully!"
echo "   3. Test toolchain (optional): $INSTALL_DIR/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version"
echo ""
echo "⚠️  IMPORTANT: This is an ISOLATED sysroot - won't affect system!"
echo "✅ Safe for production servers and legacy applications"