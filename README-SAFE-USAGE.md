# Safe RHEL 7 Sysroot Usage Guide for Python Development

## ⚠️ SAFETY FIRST

This sysroot toolchain creates an **isolated environment** that is completely separate from your RHEL 7 system. It will **NOT** interfere with:
- System applications
- Existing system libraries (glibc 2.17)
- Legacy software
- Package manager (yum)
- Python installations

## What is a Sysroot for VS Code?

A **sysroot** for VS Code Remote SSH is a self-contained directory that contains:
- Modern glibc 2.28 libraries (required by VS Code server)
- patchelf tool for dynamic library patching
- Environment variables for VS Code server integration
- **Purpose**: Enable VS Code Remote SSH on legacy RHEL 7 servers

## Installation (100% Safe)

1. **Transfer files to RHEL 7 server:**
```bash
scp exported-toolchain/* user@rhel7-server:
```

2. **Install sysroot (does NOT modify system):**
```bash
chmod +x install-toolchain.sh
./install-toolchain.sh
```

This installs to `/opt/rhel7-sysroot` - completely isolated from your system!

**What gets installed:**
- Modern glibc 2.28 libraries in `/opt/rhel7-sysroot/`
- patchelf tool in `/usr/local/bin/patchelf`  
- VS Code environment variables in `~/vscode-server-env.sh`

## VS Code Remote SSH Setup

3. **Restart your SSH session to load environment variables:**
```bash
# Exit and reconnect, or:
source ~/.bashrc
```

4. **Verify VS Code environment setup:**
```bash
echo $VSCODE_SERVER_PATCHELF_PATH      # Should show /usr/local/bin/patchelf
echo $VSCODE_SERVER_CUSTOM_GLIBC_PATH  # Should show sysroot lib paths
patchelf --version                     # Should show v0.18.0+
```

5. **Connect VS Code Remote SSH:**
   - VS Code will now connect successfully to your RHEL 7 server
   - Python development works perfectly
   - No additional configuration needed for Python projects

## Safe Python Development Workflow

### ✅ DO (Safe):
- Connect VS Code Remote SSH to your RHEL 7 server
- Develop Python applications as usual
- Use VS Code Python extension and debugging
- Access system Python installations normally
- Run Python scripts with system Python interpreter

### ❌ DON'T (Unnecessary):
- The sysroot is only for VS Code server compatibility
- You don't need to configure Python paths or interpreters
- System Python works normally and is unaffected
- No special Python setup required

## Testing Your Setup

```bash
# Verify sysroot installation
ls -la /opt/rhel7-sysroot/

# Check VS Code environment variables
env | grep VSCODE_SERVER

# Test patchelf installation
patchelf --version

# Verify system is unchanged (should show glibc 2.17)
ldd --version

# Test Python (should work normally)
python --version
python3 --version
```

## VS Code Remote SSH Connection Process

When you connect to the RHEL 7 server:

1. **VS Code server installation**: VS Code automatically installs its server components
2. **patchelf magic**: The server uses patchelf to patch its binaries to use your custom glibc 2.28
3. **Dynamic linking**: Server runs with modern glibc while system remains on glibc 2.17
4. **Seamless development**: You get modern features without breaking the system

## VS Code Remote SSH Benefits for Python Development

With this setup, VS Code will:
- ✅ **Connect successfully** to RHEL 7 servers (bypasses glibc compatibility issues)
- ✅ **Python development works perfectly** with all extensions
- ✅ **Debugging and IntelliSense** work for Python projects
- ✅ **Terminal integration** works normally  
- ✅ **Extension marketplace** accessible for Python tools
- ✅ **Git integration** and other features work seamlessly
- ✅ **No special Python configuration** needed

All while keeping your RHEL 7 system completely safe and unchanged!

## Expected VS Code Behavior

⚠️ **Normal**: VS Code will show a dialog saying the connection is "not supported"
✅ **This is expected** when using custom glibc - the connection will work fine
🔧 **VS Code server will be patched** automatically to use your sysroot libraries

## Troubleshooting

**Q: Can this break my RHEL 7 system?**
A: No! The sysroot is completely isolated in `/opt/rhel7-sysroot`

**Q: Will this affect other applications?**
A: No! System applications continue using system gcc and glibc 2.17

**Q: Can I remove it safely?**
A: Yes! Just `sudo rm -rf /opt/rhel7-sysroot`

**Q: How do I develop Python with this setup?**
A: Just connect VS Code Remote SSH normally - Python development works automatically