# RHEL 7 Sysroot Toolchain for VS Code Remote SSH

A complete sysroot toolchain solution that enables **VS Code Remote SSH** to work with legacy RHEL 7/CentOS 7 servers. Designed specifically for **Python development** on servers with outdated glibc libraries.

## 🎯 Problem Solved

**VS Code Remote SSH fails** on RHEL 7/CentOS 7 servers because:
- System glibc 2.17 is too old for modern VS Code server
- VS Code server requires glibc 2.28+ 
- You can't upgrade system glibc (breaks legacy applications)

**This solution provides:**
- ✅ **Isolated sysroot** with modern glibc 2.28
- ✅ **VS Code compatibility** without system changes
- ✅ **Python development ready** - no C/C++ bloat
- ✅ **Production safe** - won't affect existing applications

## 🚀 Quick Start

```bash
# 1. Build toolchain (30-60 minutes)
make build && make build-toolchain && make verify && make package

# 2. Test locally
make test-env                    # Start RHEL 7 test container
make install-sysroot            # Install sysroot toolchain  
# Connect VS Code Remote SSH to localhost:2222 (user: developer, password: developer)

# 3. Deploy to production server  
scp exported-toolchain/* user@rhel7-server:
ssh user@rhel7-server
./install-toolchain.sh
# VS Code Remote SSH now works!
```

## 📋 Make Commands Reference

### **Build Commands**
| Command | Description | Time |
|---------|-------------|------|
| `make build` | Build crosstool-ng container image | ~5 min |
| `make build-toolchain` | Build complete sysroot toolchain | 30-60 min |
| `make verify` | Verify toolchain completeness and functionality | ~1 min |
| `make package` | Package toolchain with patchelf for distribution | ~2 min |

### **Development Commands**  
| Command | Description | Notes |
|---------|-------------|-------|
| `make run` | Interactive container for manual building | For debugging |
| `make check` | Check if toolchain exists in output | Quick status |
| `make docker-build` | Build using Docker (CI/CD compatible) | For GitHub Actions |
| `make docker-toolchain` | Build toolchain using Docker | CI/CD mode |

### **Test Environment Commands**
| Command | Description | Usage |
|---------|-------------|-------|
| `make test-env` | Start RHEL 7 VS Code test container | Opens SSH on port 2222 |
| `make attach-test` | Attach to test container as developer user | For debugging |
| `make stop-test` | Stop running test container | Clean shutdown |

### **Sysroot Management Commands**
| Command | Description | Requirements |
|---------|-------------|--------------|
| `make install-sysroot` | Install sysroot in running test container | Test container must be running |
| `make uninstall-sysroot` | Remove sysroot from test container | For testing removal |

### **Utility Commands**
| Command | Description | Purpose |
|---------|-------------|---------|
| `make help` | Show all available commands | Documentation |
| `make clean` | Remove container images | Cleanup |
| `make clean-output` | Remove toolchain output directory | Start fresh |
| `make rebuild` | Clean and rebuild container | Reset build |

## 🔧 Detailed Workflows

### **Complete Build Workflow**
```bash
# Full build from scratch
make build                      # Build crosstool-ng container (~5 min)
make build-toolchain           # Build sysroot toolchain (~45 min)
make verify                    # Verify all components work (~1 min)
make package                   # Create distribution package (~2 min)

# Result: exported-toolchain/ directory ready for deployment
```

### **Testing Workflow**
```bash
# Terminal 1: Start test environment
make test-env
# Container starts with:
# - RHEL 7 base (glibc 2.17)
# - SSH daemon on localhost:2222
# - developer user with sudo access

# Terminal 2: Install sysroot
make install-sysroot
# Automatically:
# ✅ Copies toolchain files
# ✅ Fixes permissions for developer user  
# ✅ Installs to /opt/rhel7-sysroot
# ✅ Sets up VS Code environment variables

# Terminal 3: Test VS Code
# Connect Remote SSH to localhost:2222
# User: developer, Password: developer
# Should work perfectly for Python development!

# Cleanup
make stop-test
```

### **Production Deployment**
```bash
# After successful local testing
scp exported-toolchain/* user@production-rhel7-server:
ssh user@production-rhel7-server
./install-toolchain.sh

# VS Code Remote SSH now works on production server!
```

## 🏗️ Technical Details

### **Built Components**
- **Crosstool-ng 1.26.0** - Cross-compilation toolchain builder
- **GCC 8.5.0** - Provides modern glibc 2.28 libraries for VS Code compatibility  
- **glibc 2.28** - Compatible with VS Code server requirements
- **patchelf 0.18.0** - Dynamic library patching for VS Code

### **File Structure**
```
exported-toolchain/
├── rhel7-toolchain-YYYYMMDD-HHMMSS.tar.gz  # Main toolchain archive
├── patchelf-0.18.0-x86_64.tar.gz           # patchelf binary
└── install-toolchain.sh                     # Installation script
```

### **Installation Paths**
- **Sysroot**: `/opt/rhel7-sysroot/`
- **patchelf**: `/usr/local/bin/patchelf`
- **Environment**: `~/vscode-server-env.sh`
- **User temp**: `/home/developer/.tmp`

### **Make Variables (Customizable)**
```makefile
IMAGE_NAME = rhel7-sysroot
TEST_IMAGE_NAME = rhel7-vscode-test
SSH_PORT = 2222
TEST_USER = developer
SYSROOT_INSTALL_PATH = /opt/rhel7-sysroot
PATCHELF_VERSION = 0.18.0
TOOLCHAIN_PREFIX = x86_64-linux-gnu
```

## 🎯 Perfect for Python Development

This toolchain is specifically designed for **Python developers** working on legacy RHEL 7 servers:

### **What You Get:**
- ✅ **VS Code Remote SSH works** on old servers
- ✅ **Full Python development** experience  
- ✅ **Terminal integration** and debugging
- ✅ **Extension support** (Python, GitLens, etc.)
- ✅ **No system impact** - completely isolated

### **What's Not Included:**
- ❌ No C/C++ IntelliSense configuration  
- ❌ No build system integration
- ❌ No C++ project templates

*Focus on Python development simplicity!*

## 🔍 Verification

### **Toolchain Verification (make verify)**
```bash
🔍 Verifying toolchain build...
✅ Found GCC binary: x86_64-linux-gnu-gcc (crosstool-NG 1.26.0) 8.5.0
✅ Basic compilation test passed
✅ All essential toolchain components found
✅ Sysroot directory found with complete structure
✅ Toolchain verification completed successfully!
```

### **VS Code Test Results**  
- **Before sysroot**: ❌ VS Code Remote SSH fails (glibc 2.17)  
- **After sysroot**: ✅ VS Code Remote SSH works perfectly (glibc 2.28)
- **Python development**: ✅ Full IDE experience available

## 🐛 Troubleshooting

### **Common Issues**
```bash
# Build issues
make clean && make rebuild       # Reset build environment
make verify                     # Check toolchain completeness

# Test container issues  
make stop-test && make test-env # Restart test environment
make attach-test               # Debug inside container

# Installation issues
make uninstall-sysroot         # Remove sysroot
make install-sysroot          # Reinstall sysroot
```

### **Debug Commands**
```bash
# Check container status
podman ps | grep rhel7-vscode-test

# Verify sysroot installation
make attach-test
ls -la /opt/rhel7-sysroot/
env | grep VSCODE

# Test toolchain manually
/opt/rhel7-sysroot/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version
```

## 📚 Documentation

- **[VSCODE-TEST.md](VSCODE-TEST.md)** - Complete testing guide  
- **[INSTALL-SCRIPT.md](INSTALL-SCRIPT.md)** - Installation script details
- **[GITHUB-ACTIONS.md](GITHUB-ACTIONS.md)** - CI/CD automation
- **[README-SAFE-USAGE.md](README-SAFE-USAGE.md)** - Safety guidelines

## ⚠️ Important Notes

- **Build time**: 30-60 minutes for complete toolchain
- **Disk space**: ~2GB for toolchain output
- **Memory**: 4GB+ RAM recommended for building  
- **Compatibility**: RHEL 7, CentOS 7, and compatible distributions
- **Safety**: Completely isolated - won't affect system libraries

## 🎉 Success Story

> *"Finally! VS Code Remote SSH works on our legacy RHEL 7 production servers. Python development is now a pleasure instead of a pain. The isolated sysroot means our legacy applications are completely safe."*

**Ready to develop Python on legacy servers with modern VS Code experience!** 🐍✨