# VS Code Remote SSH Test Environment

This container provides a complete RHEL 7 environment for testing VS Code Remote SSH with the custom sysroot toolchain.

## 🚀 Quick Start

1. **Build the toolchain** (if not done already):
   ```bash
   make build && make build-toolchain && make package
   ```

2. **Start the test environment**:
   ```bash
   make test-env
   ```

3. **Connect VS Code Remote SSH**:
   - Host: `localhost:2222`
   - User: `developer`
   - Password: `developer`

## 📋 What's Included

### **Container Features:**
- ✅ **RHEL 7 base** (Red Hat UBI)
- ✅ **SSH daemon** for remote connections
- ✅ **Test user** with sudo access
- ✅ **Development tools** (git, make, nodejs, python3)

### **Sample Project:**
- ✅ **Modern C++17 code** with structured bindings
- ✅ **VS Code workspace** with IntelliSense configuration
- ✅ **Build tasks** for both system and sysroot compilers
- ✅ **Debug configurations** for GDB debugging
- ✅ **Makefile** with multiple targets

## 🔧 Testing Workflow

### **1. Install Sysroot Toolchain**
```bash
# In another terminal, copy files to the running container
podman cp exported-toolchain/. rhel7-vscode-test:/home/developer/

# Connect to the container
podman exec -it rhel7-vscode-test bash

# Install the toolchain
cd /home/developer
./install-toolchain.sh
```

### **2. VS Code Remote SSH Setup**
1. Install "Remote - SSH" extension in VS Code
2. Add SSH configuration:
   ```
   Host rhel7-test
       HostName localhost
       Port 2222
       User developer
   ```
3. Connect to `rhel7-test`
4. Open folder: `/home/developer/test-project`

### **3. Test the Toolchain**
```bash
# Check available toolchains
make info

# Build with system compiler (RHEL 7 default)
make all
make test

# Build with custom sysroot toolchain
make sysroot  
make test
```

## 🎯 Testing Scenarios

### **IntelliSense Testing:**
- Open `main.cpp` in VS Code
- Verify syntax highlighting
- Test code completion
- Check error detection

### **Build System Testing:**
- Use **Ctrl+Shift+P** → "Tasks: Run Task"
- Try different build tasks:
  - `build-system` - Uses RHEL 7 system compiler
  - `build-sysroot` - Uses custom sysroot toolchain
  - `toolchain-info` - Shows compiler information

### **Debugging Testing:**
- Set breakpoints in `main.cpp`
- Use **F5** to start debugging
- Test both debug configurations:
  - "Debug with System GCC"
  - "Debug with Sysroot GCC"

### **C++17 Features Testing:**
The sample code tests:
- ✅ Structured bindings: `auto [size, hasItems] = test->getStats()`
- ✅ Smart pointers: `std::make_unique<TestClass>()`
- ✅ Range-based for loops
- ✅ Auto type deduction
- ✅ STL containers

## 📊 Expected Results

### **System Compiler (RHEL 7 default):**
```bash
$ make info
System compiler: /usr/bin/g++
System compiler version: g++ (GCC) 4.8.5 20150623 (Red Hat 4.8.5-44)
```

### **Sysroot Compiler (After installation):**
```bash
$ make info  
Sysroot compiler: /opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-g++
Sysroot compiler version: x86_64-unknown-linux-gnu-g++ (crosstool-NG 1.26.0) 8.5.0
```

### **VS Code Integration:**
- ✅ IntelliSense uses sysroot headers
- ✅ Error detection with modern C++ standards
- ✅ Debugging works with both toolchains
- ✅ Build tasks execute correctly

## 🔧 Advanced Usage

### **Custom Toolchain Path:**
Edit `.vscode/c_cpp_properties.json` to use sysroot toolchain:
```json
{
    "configurations": [{
        "name": "RHEL7-Sysroot",
        "compilerPath": "/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-gcc",
        "includePath": ["/opt/rhel7-sysroot/x86_64-unknown-linux-gnu/sysroot/usr/include/**"]
    }]
}
```

### **Environment Variables:**
VS Code server will automatically use:
```bash
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf
export VSCODE_SERVER_CUSTOM_GLIBC_LINKER=/opt/rhel7-sysroot/x86_64-unknown-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2
```

### **Container Management:**
```bash
# Start in background
podman run -d -p 2222:22 --name rhel7-vscode-test rhel7-vscode-test

# Copy files to running container
podman cp exported-toolchain/. rhel7-vscode-test:/home/developer/

# Execute commands in container
podman exec -it rhel7-vscode-test bash

# Stop container
podman stop rhel7-vscode-test
```

## 🐛 Troubleshooting

### **SSH Connection Issues:**
```bash
# Check if container is running
podman ps

# Check SSH daemon status  
podman exec rhel7-vscode-test systemctl status sshd

# Check port forwarding
ss -tlnp | grep 2222
```

### **Toolchain Issues:**
```bash
# Verify installation
ls -la /opt/rhel7-sysroot/bin/

# Test compilation manually
/opt/rhel7-sysroot/bin/x86_64-unknown-linux-gnu-g++ --version

# Check environment variables
env | grep VSCODE_SERVER
```

### **VS Code Issues:**
- Reload VS Code window after toolchain installation
- Check VS Code Remote SSH logs
- Verify `.vscode/c_cpp_properties.json` configuration

This test environment provides a comprehensive way to validate that your RHEL7 sysroot toolchain works correctly with VS Code Remote SSH development!