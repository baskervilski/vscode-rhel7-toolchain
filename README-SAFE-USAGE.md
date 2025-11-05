# Safe RHEL 7 Sysroot Usage Guide

## ⚠️ SAFETY FIRST

This toolchain creates an **isolated sysroot** that is completely separate from your RHEL 7 system. It will **NOT** interfere with:
- System applications
- Existing gcc/glibc
- Legacy software
- Package manager (yum)

## What is a Sysroot?

A **sysroot** is a self-contained directory that contains:
- Cross-compiler toolchain (`gcc`, `g++`, `ld`, etc.)
- Target system headers and libraries (`glibc 2.28`)
- Development tools isolated from the host system

## Installation (100% Safe)

1. **Transfer files to RHEL 7 server:**
```bash
scp rhel7-toolchain-*.tar.gz install-toolchain.sh user@rhel7-server:
```

2. **Install sysroot (does NOT modify system):**
```bash
chmod +x install-toolchain.sh
./install-toolchain.sh /opt/rhel7-sysroot
```

This installs to `/opt/rhel7-sysroot` - completely isolated!

## VS Code Remote SSH Configuration

3. **Restart your SSH session to load environment variables:**
```bash
# Exit and reconnect, or:
source ~/.bashrc
```

4. **Verify VS Code environment setup:**
```bash
echo $VSCODE_SERVER_PATCHELF_PATH
echo $VSCODE_SERVER_CUSTOM_GLIBC_LINKER  
echo $VSCODE_SERVER_CUSTOM_GLIBC_PATH
patchelf --version  # Should show v0.18.0+
```

5. **Create VS Code project configuration:**
```bash
# In your project directory on RHEL 7 server
mkdir -p .vscode
cp vscode-cpp-config.json .vscode/c_cpp_properties.json
```

6. **Configure VS Code tasks (optional):**
Create `.vscode/tasks.json`:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "build with sysroot",
            "type": "shell",
            "command": "/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-gcc",
            "args": [
                "${file}",
                "-o",
                "${fileDirname}/${fileBasenameNoExtension}"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

## Safe Development Workflow

### ✅ DO (Safe):
- Use the sysroot compiler for development: `/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-gcc`
- Configure VS Code to use the sysroot toolchain
- Build your applications with the sysroot
- Test binaries on the RHEL 7 system

### ❌ DON'T (Dangerous):
- Add sysroot to system PATH: `export PATH=/opt/rhel7-sysroot/bin:$PATH`
- Replace system gcc with sysroot gcc
- Use `sudo make install` or similar system-wide installations

## Testing Your Setup

```bash
# Test the isolated compiler (safe)
/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-gcc --version

# Verify system gcc is unchanged (should show old version)
gcc --version

# Build a test program with sysroot
echo 'int main(){return 0;}' > test.c
/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-gcc test.c -o test_sysroot
./test_sysroot && echo "Sysroot toolchain working!"
```

## VS Code Remote SSH Connection Process

When you connect to the RHEL 7 server:

1. **VS Code server installation**: VS Code automatically installs its server components
2. **patchelf magic**: The server uses patchelf to patch its binaries to use your custom glibc 2.28
3. **Dynamic linking**: Server runs with modern glibc while system remains on glibc 2.17
4. **Seamless development**: You get modern features without breaking the system

## VS Code Remote SSH Benefits

With this setup, VS Code will:
- ✅ **Install and run successfully** on RHEL 7 (with custom glibc)
- ✅ **Use modern IntelliSense** with glibc 2.28 headers  
- ✅ **Provide accurate code completion** and error detection
- ✅ **Support modern C/C++ standards** (C17, C++17)
- ✅ **Work with the VS Code C/C++ extension** 
- ✅ **Debug with modern gdb features**
- ✅ **Show "unsupported connection" dialog** (this is normal and expected)

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

**Q: How do I use it in VS Code?**
A: Configure `.vscode/c_cpp_properties.json` to point to the sysroot compiler