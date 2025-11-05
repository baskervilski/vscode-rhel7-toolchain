# VS Code Remote SSH Test Environment

This container provides a complete RHEL 7 environment for testing VS Code Remote SSH with the custom sysroot toolchain designed for **Python development** on legacy servers.

## 🚀 Quick Start

1. **Build the toolchain** (if not done already):
   ```bash
   make build && make build-toolchain && make verify && make package
   ```

2. **Start the test environment**:
   ```bash
   make test-env
   ```

3. **Install sysroot toolchain** (in another terminal):
   ```bash
   make install-sysroot
   ```

4. **Connect VS Code Remote SSH**:
   - Host: `localhost:2222`
   - User: `developer`
   - Password: `developer`

## 📋 Available Make Commands

### **Build Commands:**
- `make build` - Build the crosstool-ng container image
- `make build-toolchain` - Build the complete sysroot toolchain (30-60 minutes)
- `make verify` - Verify toolchain build completeness and functionality
- `make package` - Package toolchain for distribution with patchelf

### **Test Environment Commands:**
- `make test-env` - Build and run RHEL 7 VS Code Remote SSH test container
- `make attach-test` - Attach to running test container with bash shell
- `make stop-test` - Stop the running test container

### **Sysroot Management Commands:**
- `make install-sysroot` - Install sysroot toolchain in running test container  
- `make uninstall-sysroot` - Remove sysroot toolchain from test container

### **Utility Commands:**
- `make help` - Show all available commands
- `make check` - Check if toolchain exists in output directory
- `make clean` - Remove container images
- `make clean-output` - Remove toolchain output directory

## 📋 What's Included

### **Container Features:**
- ✅ **RHEL 7 UBI base** with glibc 2.17 (simulates production servers)
- ✅ **SSH daemon** configured for Remote SSH connections
- ✅ **Developer user** with sudo privileges and proper temp directory
- ✅ **Python development ready** (no C/C++ bloat for Python workflows)

### **Sysroot Toolchain:**
- ✅ **Modern glibc 2.28** for VS Code server compatibility
- ✅ **GCC 8.5.0** toolchain (crosstool-ng 1.26.0)
- ✅ **patchelf 0.18.0** for dynamic library patching
- ✅ **Environment variables** for VS Code server integration
- ✅ **Isolated installation** that won't affect system libraries

## 🔧 Complete Testing Workflow

### **1. Build and Verify Toolchain**
```bash
# Build everything from scratch
make build && make build-toolchain && make verify && make package
```

### **2. Start Test Environment**
```bash
# Start RHEL 7 container (Terminal 1)
make test-env

# Container info will show:
# 🔌 VS Code Connection:
#    Host: localhost:2222
#    User: developer  
#    Password: developer
```

### **3. Install Sysroot (Automated)**
```bash
# In another terminal (Terminal 2)
make install-sysroot

# This automatically:
# ✅ Copies toolchain files to container
# ✅ Fixes file permissions for developer user
# ✅ Installs sysroot to /opt/rhel7-sysroot
# ✅ Installs patchelf for VS Code server
# ✅ Sets up environment variables
```

### **4. VS Code Remote SSH Setup**
1. Install "Remote - SSH" extension in VS Code
2. Add SSH configuration:
   ```
   Host rhel7-test
       HostName localhost
       Port 2222
       User developer
   ```
3. Connect to `rhel7-test` - should work now with glibc 2.28!

### **5. Container Management**
```bash
# Attach to container for debugging
make attach-test

# Remove sysroot to test failure again  
make uninstall-sysroot

# Reinstall sysroot
make install-sysroot

# Stop container when done
make stop-test
```

## 🎯 Testing Scenarios

### **Python Development Testing:**
1. **Connect VS Code Remote SSH** to the container
2. **Install Python extension** in the remote environment
3. **Create Python projects** and verify they work correctly
4. **Test debugging** with Python debugger
5. **Verify terminal** and integrated shell work properly

### **VS Code Server Compatibility:**
- **Without sysroot**: VS Code Remote SSH fails with glibc errors
- **With sysroot**: VS Code Remote SSH connects successfully
- **Environment**: All VS Code features work (terminal, debugger, extensions)

### **Command Testing:**
```bash
# Test glibc versions
podman exec --user developer rhel7-vscode-test bash -c "ldd --version"
# Output: ldd (GNU libc) 2.17

# Test sysroot toolchain  
podman exec rhel7-vscode-test /opt/rhel7-sysroot/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version
# Output: x86_64-linux-gnu-gcc (crosstool-NG 1.26.0) 8.5.0

# Test environment variables
podman exec --user developer rhel7-vscode-test bash -c "source ~/.bashrc && env | grep VSCODE"
```

### **Make Command Testing:**
```bash
# Build workflow
make build            # ✅ Build crosstool-ng container
make build-toolchain  # ✅ Build sysroot (30-60 min)  
make verify          # ✅ Verify all components work
make package         # ✅ Create distribution package

# Test workflow  
make test-env        # ✅ Start RHEL 7 container
make install-sysroot # ✅ Install sysroot as developer user
make attach-test     # ✅ Attach to container for debugging
make uninstall-sysroot # ✅ Remove sysroot
make stop-test       # ✅ Stop container
```

## 📊 Expected Results

### **Before Sysroot Installation:**
```bash
# VS Code Remote SSH connection fails
❌ VS Code Remote SSH will FAIL to connect initially
❌ Due to outdated glibc 2.17

# System info
OS: Red Hat Enterprise Linux Server release 7.9 (Maipo)
glibc: ldd (GNU libc) 2.17
```

### **After Sysroot Installation:**
```bash
# VS Code Remote SSH works perfectly
✅ VS Code Remote SSH connects successfully
✅ All VS Code features available for Python development

# Toolchain available
/opt/rhel7-sysroot/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version
# x86_64-linux-gnu-gcc (crosstool-NG 1.26.0) 8.5.0

# Environment configured
VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf
VSCODE_SERVER_CUSTOM_GLIBC_LINKER=/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2
VSCODE_SERVER_CUSTOM_GLIBC_PATH=/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib:/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/usr/lib
```

### **Python Development:**
- ✅ **Full VS Code experience** on RHEL 7 servers
- ✅ **Python debugging** and IntelliSense work perfectly
- ✅ **Terminal integration** with proper environment
- ✅ **Extension support** for Python development
- ✅ **No system impact** - isolated sysroot installation

## 🔧 Advanced Usage

### **Make Variables (Customizable):**
```makefile
IMAGE_NAME = rhel7-sysroot
TEST_IMAGE_NAME = rhel7-vscode-test  
SSH_PORT = 2222
TEST_USER = developer
SYSROOT_INSTALL_PATH = /opt/rhel7-sysroot
PATCHELF_VERSION = 0.18.0
```

### **Environment Variables (Auto-configured):**
VS Code server automatically uses:
```bash
export TMPDIR=/home/developer/.tmp          # Proper temp directory
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2
export VSCODE_SERVER_CUSTOM_GLIBC_PATH=/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/lib:/opt/rhel7-sysroot/x86_64-linux-gnu/x86_64-linux-gnu/sysroot/usr/lib
```

### **Manual Container Management:**
```bash
# Use make commands instead of manual podman commands:
make test-env        # Automated container startup
make attach-test     # Attach as developer user  
make install-sysroot # Automated sysroot installation
make stop-test       # Clean container shutdown
```

### **Production Deployment:**
```bash
# Transfer to real RHEL 7/CentOS 7 server
scp exported-toolchain/* user@production-server:
ssh user@production-server
./install-toolchain.sh

# VS Code Remote SSH now works on production server!
```

## 🐛 Troubleshooting

### **Make Command Issues:**
```bash
# Check container status
make stop-test && make test-env  # Restart container

# Verify toolchain build
make verify

# Check package contents
ls -la exported-toolchain/

# Test individual steps
make attach-test  # Debug inside container
```

### **VS Code Connection Issues:**
```bash
# Test container connectivity
podman ps | grep rhel7-vscode-test
ss -tlnp | grep 2222

# Verify sysroot installation
make attach-test
ls -la /opt/rhel7-sysroot/
env | grep VSCODE
```

### **Installation Issues:**
```bash
# Check file permissions
make attach-test
ls -la ~/        # Files should be owned by developer

# Test temp directory
echo $TMPDIR     # Should be /home/developer/.tmp
touch $TMPDIR/test && rm $TMPDIR/test  # Should work

# Reinstall if needed
make uninstall-sysroot && make install-sysroot
```

### **Python Development Issues:**
- **Restart VS Code** after sysroot installation
- **Reload window** if extensions don't load
- **Check Python interpreter** path in VS Code
- **Verify terminal** works in integrated terminal

## 🎯 Perfect for Python Development

This toolchain is specifically optimized for **Python developers** who need VS Code Remote SSH to work on legacy RHEL 7/CentOS 7 servers. No C/C++ configuration needed - just install and code Python! 🐍

### **Key Benefits:**
- ✅ **VS Code Remote SSH works** on old servers
- ✅ **Python development ready** out of the box  
- ✅ **No system impact** - isolated sysroot
- ✅ **Easy automation** with make commands
- ✅ **Production safe** for legacy environments