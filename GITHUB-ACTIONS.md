# GitHub Actions CI/CD

This repository includes automated GitHub Actions workflows for building and distributing the RHEL7 sysroot toolchain.

## 🚀 Workflows

### 1. **Build Toolchain** (`.github/workflows/build-toolchain.yml`)
**Triggers:**
- Push to `main`/`master` branch
- Push tags (`v*`)
- Pull requests
- Manual trigger (`workflow_dispatch`)

**What it does:**
- Builds the container image
- Compiles the complete toolchain (30-60 minutes)
- Packages everything for distribution
- Creates GitHub release (on tags)
- Uploads artifacts for 30 days

**Outputs:**
- `rhel7-toolchain-YYYYMMDD-HHMMSS.tar.gz` - Complete toolchain
- `patchelf-0.18.0-x86_64.tar.gz` - VS Code dependency
- `install-toolchain.sh` - Installation script

### 2. **Quick Test** (`.github/workflows/quick-test.yml`)
**Triggers:**
- Manual only (`workflow_dispatch`)

**What it does:**
- Tests container build (fast)
- Optionally tests toolchain build start (10min timeout)
- Validates packaging process
- Checks all required files exist

## 📦 Release Process

### Automatic Releases
1. **Tag your commit:** `git tag v1.0.0 && git push origin v1.0.0`
2. **GitHub Actions runs** automatically (45-60 minutes)
3. **Release created** with downloadable packages
4. **Install anywhere:** Download and run `install-toolchain.sh`

### Development Testing
1. **Push to main branch** → Artifacts available for 30 days
2. **Pull request** → Build status comment added
3. **Manual trigger** → Use "Quick Test" for faster validation

## 🏗️ Build Environment

**GitHub Runner Specs:**
- **OS:** Ubuntu 22.04
- **CPU:** 4 cores (x86_64)
- **RAM:** 16 GB
- **Disk:** ~14 GB available
- **Network:** High-speed internet

**Build Performance:**
- **Container build:** ~5 minutes
- **Toolchain build:** 45-60 minutes (crosstool-ng compilation)
- **Packaging:** ~2 minutes
- **Total:** ~50-65 minutes

## 📋 Artifacts

### On Every Build
- **Artifacts section:** Available for 30 days
- **Build logs:** Full compilation output
- **Verification:** GCC version test included

### On Tag Release
- **GitHub Releases:** Permanent download links
- **Release notes:** Auto-generated with install instructions
- **Checksums:** Could be added if needed

## 🔧 Customization

### Modify Build
Edit `build-toolchain.yml`:
```yaml
# Change timeout (default 90 minutes)
timeout 120m make build-toolchain

# Add custom build steps
- name: Custom validation
  run: |
    # Your custom tests here
```

### Add More Triggers
```yaml
on:
  schedule:
    - cron: '0 2 * * 0'  # Weekly Sunday 2 AM
  repository_dispatch:   # External trigger
```

### Environment Variables
```yaml
env:
  CUSTOM_BUILD_FLAG: "value"
  TOOLCHAIN_VERSION: "8.5.0"
```

## 🎯 Usage Examples

### Download Latest Release
```bash
# Get latest release info
LATEST=$(curl -s https://api.github.com/repos/YOUR_USERNAME/rhel7_sysroot/releases/latest)

# Download all files
wget $(echo $LATEST | jq -r '.assets[].browser_download_url')

# Install
chmod +x install-toolchain.sh
./install-toolchain.sh
```

### Development Workflow
```bash
# 1. Make changes locally
git add .
git commit -m "Update toolchain config"

# 2. Test with quick build (optional)
# Go to GitHub → Actions → Quick Test → Run workflow

# 3. Push for full build
git push origin main

# 4. Check artifacts in ~60 minutes
# GitHub → Actions → Latest run → Artifacts

# 5. Create release when ready
git tag v1.1.0
git push origin v1.1.0
```

## ⚠️ Important Notes

- **Build time:** Full builds take 45-60 minutes
- **Disk usage:** ~8GB for complete toolchain
- **Network:** Downloads CentOS packages and dependencies
- **Timeout:** 90-minute limit to prevent stuck builds
- **Concurrent builds:** GitHub Actions handles queuing

The CI/CD system makes it easy to maintain and distribute updated toolchains without manual build processes!