#!/bin/bash
# Installation script for RHEL7 sysroot toolchain
# User-space installation for VS Code Remote SSH development
# No root privileges required!

set -e

# User-space directories
INSTALL_DIR=${1:-$HOME/rhel7-sysroot}
PATCHELF_VERSION=0.18.0
USER_BIN_DIR="$HOME/bin"

echo "=== RHEL7 Sysroot Toolchain Installer (User-Space) ==="
echo "Installing ISOLATED sysroot toolchain to $INSTALL_DIR..."
echo "Installing patchelf to $USER_BIN_DIR..."
echo "This will NOT affect system gcc or applications."
echo "No root privileges required!"
echo ""

# Check if archive exists
ARCHIVE=$(ls rhel7-toolchain-*.tar.gz 2>/dev/null | head -1)
if [ -z "$ARCHIVE" ]; then
    echo "❌ Error: No toolchain archive found (rhel7-toolchain-*.tar.gz)"
    echo "Make sure you're running this script in the same directory as the archive."
    exit 1
fi
echo "📦 Found archive: $ARCHIVE"

# Install toolchain to user directory
echo "📁 Creating installation directory..."
mkdir -p "$INSTALL_DIR"
echo "📦 Extracting toolchain archive..."
tar -xzf "$ARCHIVE" -C "$INSTALL_DIR"

# Install patchelf to user bin directory
echo "🔧 Installing patchelf to user directory (required by VS Code server)..."
if [ ! -f "patchelf-$PATCHELF_VERSION-x86_64.tar.gz" ]; then
    echo "❌ Error: patchelf archive not found (patchelf-$PATCHELF_VERSION-x86_64.tar.gz)"
    echo "Make sure you're running this script in the same directory as the patchelf archive."
    exit 1
fi

# Create user bin directory if it doesn't exist
mkdir -p "$USER_BIN_DIR"

# Extract patchelf to user directory
CURRENT_DIR=$(pwd)
TEMP_DIR="${TMPDIR:-$HOME/.tmp}/patchelf-install-$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
cp "$CURRENT_DIR/patchelf-$PATCHELF_VERSION-x86_64.tar.gz" .
tar -xzf "patchelf-$PATCHELF_VERSION-x86_64.tar.gz"
cp bin/patchelf "$USER_BIN_DIR/"
chmod +x "$USER_BIN_DIR/patchelf"
cd "$CURRENT_DIR"
rm -rf "$TEMP_DIR"

# Add user bin to PATH if not already there
if [[ ":$PATH:" != *":$USER_BIN_DIR:"* ]]; then
    echo "🔧 Adding $USER_BIN_DIR to PATH in ~/.bashrc"
    if ! grep -q "export PATH.*$USER_BIN_DIR" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Add user bin directory to PATH" >> ~/.bashrc
        echo "export PATH=\"$USER_BIN_DIR:\$PATH\"" >> ~/.bashrc
    fi
fi

# Create VS Code environment variables script
echo "🌍 Setting up VS Code server environment variables..."
cat > vscode-server-env.sh << EOF
#!/bin/bash
# VS Code Remote SSH Environment Variables for Custom glibc Sysroot
# USER-SPACE INSTALLATION - No root required!
export VSCODE_SERVER_PATCHELF_PATH=$USER_BIN_DIR/patchelf
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
    echo "# VS Code Remote SSH with custom glibc sysroot (user-space)" >> ~/.bashrc
    echo "source ~/vscode-server-env.sh" >> ~/.bashrc
    echo "🔌 Added VS Code environment to ~/.bashrc"
else
    echo "🔌 VS Code environment already in ~/.bashrc"
fi

echo ""
echo "✅ Sysroot toolchain installed safely to $INSTALL_DIR"
echo "🔧 patchelf v$PATCHELF_VERSION installed to $USER_BIN_DIR/patchelf"
echo "🌍 VS Code environment variables configured in ~/vscode-server-env.sh"
echo "📁 User bin directory ($USER_BIN_DIR) added to PATH"
echo ""
echo "📖 Next steps:"
echo "   1. Restart your SSH session or run: source ~/.bashrc"
echo "   2. VS Code Remote SSH should now connect successfully!"
echo "   3. Test toolchain (optional): $INSTALL_DIR/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version"
echo "   4. Test patchelf: which patchelf (should show $USER_BIN_DIR/patchelf)"
echo ""
echo "⚠️  IMPORTANT: This is an ISOLATED user-space sysroot - won't affect system!"
echo "✅ Safe for production servers and legacy applications"
echo "� No root privileges required!"