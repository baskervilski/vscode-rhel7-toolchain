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
if [ ! -f "rhel7-toolchain-*.tar.gz" ]; then
    echo "❌ Error: No toolchain archive found (rhel7-toolchain-*.tar.gz)"
    echo "Make sure you're running this script in the same directory as the archive."
    exit 1
fi

ARCHIVE=$(ls rhel7-toolchain-*.tar.gz | head -1)
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
cd /tmp
cp "../patchelf-$PATCHELF_VERSION-x86_64.tar.gz" .
tar -xzf patchelf-$PATCHELF_VERSION-x86_64.tar.gz
sudo cp patchelf-$PATCHELF_VERSION-x86_64/bin/patchelf /usr/local/bin/
sudo chmod +x /usr/local/bin/patchelf
rm -rf patchelf-*
cd - > /dev/null

# Create VS Code environment variables script
echo "🌍 Setting up VS Code server environment variables..."
cat > vscode-server-env.sh << EOF
#!/bin/bash
# VS Code Remote SSH Environment Variables for Custom glibc Sysroot
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=$INSTALL_DIR/x86_64-unknown-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=$INSTALL_DIR/x86_64-unknown-linux-gnu/sysroot/lib:$INSTALL_DIR/x86_64-unknown-linux-gnu/sysroot/usr/lib
EOF

chmod +x vscode-server-env.sh
cp vscode-server-env.sh ~/

# Add to bashrc if not already present
if ! grep -q "vscode-server-env.sh" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# VS Code Remote SSH with custom glibc sysroot" >> ~/.bashrc
    echo "source ~/vscode-server-env.sh" >> ~/.bashrc
    echo "🔌 Added VS Code environment to ~/.bashrc"
else
    echo "🔌 VS Code environment already in ~/.bashrc"
fi

# Create VS Code C/C++ configuration
echo "⚙️  Creating VS Code C/C++ configuration..."
cat > vscode-cpp-config.json << EOF
{
    "configurations": [{
        "name": "RHEL7-Sysroot",
        "compilerPath": "$INSTALL_DIR/bin/x86_64-unknown-linux-gnu-gcc",
        "includePath": ["$INSTALL_DIR/x86_64-unknown-linux-gnu/sysroot/usr/include/**"],
        "defines": [],
        "cStandard": "c17",
        "cppStandard": "c++17",
        "intelliSenseMode": "gcc-x64"
    }],
    "version": 4
}
EOF

echo ""
echo "✅ Sysroot toolchain installed safely to $INSTALL_DIR"
echo "🔧 patchelf v$PATCHELF_VERSION installed to /usr/local/bin/patchelf"
echo "🌍 VS Code environment variables configured in ~/vscode-server-env.sh"
echo "📋 VS Code C/C++ config created: vscode-cpp-config.json"
echo ""
echo "📖 Next steps:"
echo "   1. Restart your SSH session or run: source ~/.bashrc"
echo "   2. Copy vscode-cpp-config.json to your VS Code project:"
echo "      cp vscode-cpp-config.json /path/to/project/.vscode/c_cpp_properties.json"
echo "   3. Test with: $INSTALL_DIR/bin/x86_64-unknown-linux-gnu-gcc --version"
echo ""
echo "⚠️  IMPORTANT: This is an ISOLATED sysroot - won't affect system!"
echo "✅ Safe for production servers and legacy applications"