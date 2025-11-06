# Makefile for RHEL7 sysroot container

# Variables
IMAGE_NAME = rhel7-sysroot
CONTAINER_NAME = rhel7-sysroot-container
TEST_IMAGE_NAME = rhel7-vscode-test
TEST_CONTAINER_NAME = rhel7-vscode-test
EXPORT_DIR = ./exported-toolchain
TOOLCHAIN_ARCHIVE = rhel7-toolchain-$(shell date +%Y%m%d-%H%M%S).tar.gz
OUTPUT_DIR = $(shell pwd)/toolchain-output
DOCKERFILE_TEST = Dockerfile.test
TOOLCHAIN_PREFIX = x86_64-linux-gnu
GCC_BINARY = $(OUTPUT_DIR)/$(TOOLCHAIN_PREFIX)/bin/$(TOOLCHAIN_PREFIX)-gcc
SYSROOT_DIR = $(OUTPUT_DIR)/$(TOOLCHAIN_PREFIX)/$(TOOLCHAIN_PREFIX)/sysroot
PATCHELF_VERSION = 0.18.0
PATCHELF_URL = https://github.com/NixOS/patchelf/releases/download/$(PATCHELF_VERSION)/patchelf-$(PATCHELF_VERSION)-x86_64.tar.gz
INSTALL_SCRIPT = install-toolchain.sh
UNINSTALL_SCRIPT = uninstall-toolchain.sh
BUILD_SCRIPT = build-toolchain.sh
CONFIG_FILE ?= x86_64-gcc-8.5.0-glibc-2.28.config
SSH_PORT = 2222
TEST_USER = developer
SYSROOT_INSTALL_PATH = /opt/rhel7-sysroot

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build           - Build the container image using podman"
	@echo "  docker-build    - Build the container image using docker (CI/CD)"
	@echo "  run             - Start container with mounted output directory (interactive)"
	@echo "  build-toolchain - Build toolchain directly to mounted output (verbose mode)"
	@echo "  docker-toolchain - Build toolchain using docker (filtered mode, CI/CD compatible)"
	@echo "  package         - Package toolchain for distribution"
	@echo "  check           - Check if toolchain exists in mounted output"
	@echo "  verify          - Verify toolchain build completeness and functionality"
	@echo "  test-env        - Build and run VS Code Remote SSH test environment"
	@echo "  attach-test     - Attach to running test container with bash shell"
	@echo "  stop-test       - Stop the running test container"
	@echo "  install-sysroot - Install sysroot toolchain in running test container"
	@echo "  uninstall-sysroot - Remove sysroot toolchain from test container"
	@echo "  clean           - Remove the container image"
	@echo "  clean-output    - Remove mounted output directory" 
	@echo "  rebuild         - Clean and build the container image"

# Build the container image
.PHONY: build
build:
	podman build -t $(IMAGE_NAME) .

# Build the container image using Docker (CI/CD compatible)
.PHONY: docker-build
docker-build:
	docker build -t $(IMAGE_NAME) .

# Start container with mounted output directory (interactive)
.PHONY: run
run:
	@echo "Creating output directory: $(OUTPUT_DIR)"
	@mkdir -p $(OUTPUT_DIR)
	@echo "Setting proper permissions for output directory..."
	@chmod 755 $(OUTPUT_DIR)
	@echo "Starting container with mounted output directory..."
	@echo "Toolchain will be built directly to: $(OUTPUT_DIR)"
	podman run --rm -it --name $(CONTAINER_NAME) \
		-v $(OUTPUT_DIR):/home/ctng/output:Z \
		--userns=keep-id \
		$(IMAGE_NAME) /bin/bash

# Remove the container image
.PHONY: clean
clean:
	podman rmi $(IMAGE_NAME) || true

# Rebuild (clean + build)
.PHONY: rebuild
rebuild: clean build

# Check if toolchain exists in mounted output
.PHONY: check
check:
	@echo "Checking for toolchain in mounted output..."
	@if [ -d "$(OUTPUT_DIR)" ] && [ "$$(ls -A $(OUTPUT_DIR) 2>/dev/null)" ]; then \
		echo "✅ Found toolchain in: $(OUTPUT_DIR)"; \
		echo "📁 Contents:"; \
		ls -la $(OUTPUT_DIR) | head -10; \
		echo ""; \
		echo "Ready to package with: make package"; \
	else \
		echo "❌ No toolchain found in: $(OUTPUT_DIR)"; \
		echo ""; \
		echo "Build options:"; \
		echo "  Interactive: make run -> ./$(BUILD_SCRIPT)"; \
		echo "  Verbose:     make build-toolchain (full output)"; \
		echo "  Filtered:    make docker-toolchain (progress only)"; \
	fi

# Verify toolchain build completeness and functionality
.PHONY: verify
verify:
	@echo "🔍 Verifying toolchain build..."
	@if [ ! -d "$(OUTPUT_DIR)" ]; then \
		echo "❌ No toolchain output directory found: $(OUTPUT_DIR)"; \
		exit 1; \
	fi
	@echo "📁 Toolchain output contents:"
	@ls -la $(OUTPUT_DIR)/
	@echo ""
	@echo "🔍 Looking for GCC binary..."
	@if [ -f "$(GCC_BINARY)" ]; then \
		echo "✅ Found GCC binary"; \
		$(GCC_BINARY) --version; \
		echo ""; \
		echo "🔍 Testing basic compilation..."; \
		echo 'int main(){return 0;}' > /tmp/test.c; \
		$(GCC_BINARY) /tmp/test.c -o /tmp/test || { \
			echo "❌ Basic compilation test failed"; \
			exit 1; \
		}; \
		echo "✅ Basic compilation test passed"; \
		rm -f /tmp/test.c /tmp/test; \
	else \
		echo "❌ GCC binary not found"; \
		find $(OUTPUT_DIR)/ -name "*gcc*" -type f 2>/dev/null | head -5 || echo "No GCC files found"; \
		exit 1; \
	fi
	@echo ""
	@echo "🔍 Checking essential toolchain components..."
	@MISSING=""; \
	for tool in gcc g++ ld ar strip objdump; do \
		if [ ! -f "$(OUTPUT_DIR)/$(TOOLCHAIN_PREFIX)/bin/$(TOOLCHAIN_PREFIX)-$$tool" ]; then \
			MISSING="$$MISSING $(TOOLCHAIN_PREFIX)-$$tool"; \
		fi; \
	done; \
	if [ -n "$$MISSING" ]; then \
		echo "❌ Missing essential tools:$$MISSING"; \
		exit 1; \
	else \
		echo "✅ All essential toolchain components found"; \
	fi
	@echo ""
	@echo "🔍 Checking sysroot structure..."
	@if [ -d "$(SYSROOT_DIR)" ]; then \
		echo "✅ Sysroot directory found"; \
		echo "📂 Sysroot contents:"; \
		ls -la $(SYSROOT_DIR)/ | head -10; \
	else \
		echo "❌ Sysroot directory not found"; \
		exit 1; \
	fi
	@echo ""
	@echo "✅ Toolchain verification completed successfully!"
	@echo "🎉 Ready for packaging: make package"

# Build toolchain directly to mounted output directory
.PHONY: build-toolchain
build-toolchain:
	@echo "Creating output directory: $(OUTPUT_DIR)"
	@mkdir -p $(OUTPUT_DIR)
	@echo "Setting proper permissions for output directory..."
	@chmod 755 $(OUTPUT_DIR)
	@echo "Building toolchain using $(BUILD_SCRIPT) script..."
	@echo "This will take 30-60 minutes..."
	@echo "Using verbose mode for direct build..."
	@echo "Configuration: $(CONFIG_FILE)"
	podman run --rm --name $(CONTAINER_NAME) \
		-v $(OUTPUT_DIR):/home/ctng/output:Z \
		--userns=keep-id \
		$(IMAGE_NAME) ./$(BUILD_SCRIPT) --verbose --config "$(CONFIG_FILE)"
	@echo "🔧 Ensuring proper file permissions..."
	@find $(OUTPUT_DIR) -type d -exec chmod 755 {} \; 2>/dev/null || true
	@find $(OUTPUT_DIR) -type f ! -path "*/bin/*" ! -path "*/libexec/*" -exec chmod 644 {} \; 2>/dev/null || true
	@find $(OUTPUT_DIR) -type f \( -path "*/bin/*" -o -path "*/libexec/*" \) -exec chmod 755 {} \; 2>/dev/null || true

# Build toolchain using Docker (CI/CD compatible)
.PHONY: docker-toolchain
docker-toolchain:
	@echo "Creating output directory: $(OUTPUT_DIR)"
	@mkdir -p $(OUTPUT_DIR)
	@echo "Setting proper permissions for CI/CD environment..."
	@chmod 777 $(OUTPUT_DIR)
	@echo "Building toolchain using Docker (CI/CD mode)..."
	@echo "This will take 30-60 minutes..."
	@echo "🔧 Fixing permissions and running build script..."
	@docker run --rm --name $(CONTAINER_NAME) \
		-v $(OUTPUT_DIR):/home/ctng/output \
		--user root \
		$(IMAGE_NAME) bash -c "chown -R ctng:ctng /home/ctng/output"
	@echo "🚀 Starting filtered build process..."
	@echo "Configuration: $(CONFIG_FILE)"
	docker run --rm --name $(CONTAINER_NAME)-build \
		-v $(OUTPUT_DIR):/home/ctng/output \
		--user ctng \
		$(IMAGE_NAME) ./$(BUILD_SCRIPT) --config "$(CONFIG_FILE)"
	@echo "🔧 Fixing final file permissions after build..."
	@docker run --rm --name $(CONTAINER_NAME)-perms \
		-v $(OUTPUT_DIR):/home/ctng/output \
		--user root \
		$(IMAGE_NAME) bash -c "\
			find /home/ctng/output -type d -exec chmod 755 {} \; && \
			find /home/ctng/output -type f ! -path '*/bin/*' ! -path '*/libexec/*' -exec chmod 644 {} \; && \
			find /home/ctng/output -type f \( -path '*/bin/*' -o -path '*/libexec/*' \) -exec chmod 755 {} \;"

# Package mounted toolchain for distribution
.PHONY: package
package:
	@if [ ! -d "$(OUTPUT_DIR)" ]; then \
		echo "❌ Output directory not found: $(OUTPUT_DIR)"; \
		echo "Run 'make build-toolchain' first"; \
		exit 1; \
	fi
	@echo "Packaging toolchain from: $(OUTPUT_DIR)"
	@mkdir -p $(EXPORT_DIR)
	@echo "Fixing file permissions for packaging..."
	@find $(OUTPUT_DIR) -type d -exec chmod 755 {} + 2>/dev/null || true
	@find $(OUTPUT_DIR) -type f ! -path "*/bin/*" ! -path "*/libexec/*" -exec chmod 644 {} + 2>/dev/null || true
	@find $(OUTPUT_DIR) -type f \( -path "*/bin/*" -o -path "*/libexec/*" \) -exec chmod 755 {} + 2>/dev/null || true
	@echo "Ensuring export directory exists..."
	@mkdir -p $(EXPORT_DIR) || { echo "❌ Failed to create export directory: $(EXPORT_DIR)"; exit 1; }
	@echo "Creating portable archive..."
	tar -czf $(TOOLCHAIN_ARCHIVE) -C $(OUTPUT_DIR) .
	@echo "Preparing patchelf for offline installation..."
	@if [ ! -f "$(EXPORT_DIR)/patchelf-$(PATCHELF_VERSION)-x86_64.tar.gz" ]; then \
		echo "Downloading patchelf..."; \
		wget -q -P $(EXPORT_DIR) $(PATCHELF_URL); \
	else \
		echo "Using existing patchelf archive"; \
	fi
	@echo "Copying installation and uninstall scripts..."
	@cp $(INSTALL_SCRIPT) $(EXPORT_DIR)/
	@cp $(UNINSTALL_SCRIPT) $(EXPORT_DIR)/
	@chmod +x $(EXPORT_DIR)/$(INSTALL_SCRIPT)
	@chmod +x $(EXPORT_DIR)/$(UNINSTALL_SCRIPT)
	@mv $(TOOLCHAIN_ARCHIVE) $(EXPORT_DIR)/
	@echo ""
	@echo "✅ Toolchain packaged successfully!"
	@echo "📦 Archive: $(EXPORT_DIR)/$(TOOLCHAIN_ARCHIVE)"
	@echo "📋 Installer: $(EXPORT_DIR)/$(INSTALL_SCRIPT)"
	@echo "�️  Uninstaller: $(EXPORT_DIR)/$(UNINSTALL_SCRIPT)"
	@echo "�🔧 patchelf: $(EXPORT_DIR)/patchelf-$(PATCHELF_VERSION)-x86_64.tar.gz"
	@echo ""
	@echo "Transfer to RHEL 7 server:"
	@echo "  scp $(EXPORT_DIR)/* user@rhel7-server:"
	@echo ""

# Clean mounted output directory
.PHONY: clean-output
clean-output:
	@echo "Cleaning mounted output directory..."
	@rm -rf $(OUTPUT_DIR)
	@echo "Output cleanup complete."

# Build and run VS Code Remote SSH test environment
.PHONY: test-env
test-env:
	@echo "🧪 Building simple RHEL 7 VS Code Remote SSH test container..."
	@podman build -f $(DOCKERFILE_TEST) -t $(TEST_IMAGE_NAME) .
	@echo ""
	@echo "🚀 Starting RHEL 7 test container..."
	@echo ""
	@echo "� Expected Behavior:"
	@echo "   ❌ VS Code Remote SSH will FAIL initially (outdated glibc)"
	@echo "   ✅ Should work after sysroot installation"
	@echo ""
	@echo "🔌 VS Code Connection:"
	@echo "   Host: localhost:$(SSH_PORT)"
	@echo "   User: $(TEST_USER)"
	@echo "   Password: $(TEST_USER)"
	@echo ""
	@echo "🛠️  To install sysroot (in another terminal):"
	@echo "   podman cp $(EXPORT_DIR)/. $(TEST_CONTAINER_NAME):/home/$(TEST_USER)/"
	@echo "   podman exec -it $(TEST_CONTAINER_NAME) bash"
	@echo "   cd /home/$(TEST_USER) && ./$(INSTALL_SCRIPT)"
	@echo ""
	@echo "Press Ctrl+C to stop when done testing"
	@echo ""
	@podman run --rm -it \
		-p $(SSH_PORT):22 \
		--name $(TEST_CONTAINER_NAME) \
		$(TEST_IMAGE_NAME)

# Install sysroot toolchain in running test container
.PHONY: install-sysroot
install-sysroot:
	@echo "📦 Installing sysroot toolchain in test container..."
	@if ! podman ps --format "{{.Names}}" | grep -q "$(TEST_CONTAINER_NAME)"; then \
		echo "❌ Test container not running. Start it first with: make test-env"; \
		exit 1; \
	fi
	@if [ ! -d "$(EXPORT_DIR)" ]; then \
		echo "❌ No exported toolchain found. Build and package first:"; \
		echo "   make build && make build-toolchain && make package"; \
		exit 1; \
	fi
	@echo "🧹 Cleaning old archives from container..."
	@podman exec $(TEST_CONTAINER_NAME) bash -c "rm -f /home/$(TEST_USER)/rhel7-toolchain-*.tar.gz /home/$(TEST_USER)/patchelf-*.tar.gz /home/$(TEST_USER)/$(INSTALL_SCRIPT)"
	@echo "📋 Copying fresh toolchain files to container..."
	@podman cp $(EXPORT_DIR)/. $(TEST_CONTAINER_NAME):/home/$(TEST_USER)/
	@echo "🔧 Fixing file permissions..."
	@podman exec $(TEST_CONTAINER_NAME) chown -R $(TEST_USER):$(TEST_USER) /home/$(TEST_USER)/
	@echo "🔧 Installing toolchain as non-root user..."
	@podman exec -it --user $(TEST_USER) $(TEST_CONTAINER_NAME) bash -c "cd /home/$(TEST_USER) && chmod +x $(INSTALL_SCRIPT) && ./$(INSTALL_SCRIPT)"
	@echo ""
	@echo "✅ Sysroot toolchain installed successfully!"
	@echo "🔌 VS Code Remote SSH should now work with the container"
	@echo "📊 Test the installation:"
	@echo "   podman exec $(TEST_CONTAINER_NAME) $(SYSROOT_INSTALL_PATH)/x86_64-linux-gnu/bin/x86_64-linux-gnu-gcc --version"

# Remove sysroot toolchain from test container
.PHONY: uninstall-sysroot
uninstall-sysroot:
	@echo "🗑️  Uninstalling sysroot toolchain from test container..."
	@if ! podman ps --format "{{.Names}}" | grep -q "$(TEST_CONTAINER_NAME)"; then \
		echo "❌ Test container not running. Start it first with: make test-env"; \
		exit 1; \
	fi
	@echo "🧹 Removing sysroot installation..."
	@podman exec $(TEST_CONTAINER_NAME) bash -c "sudo rm -rf $(SYSROOT_INSTALL_PATH)"
	@echo "🧹 Removing patchelf installation..."
	@podman exec $(TEST_CONTAINER_NAME) bash -c "sudo rm -f /usr/local/bin/patchelf"
	@echo "🧹 Removing VS Code environment variables..."
	@podman exec $(TEST_CONTAINER_NAME) bash -c "rm -f ~/vscode-server-env.sh"
	@podman exec $(TEST_CONTAINER_NAME) bash -c "sed -i '/vscode-server-env.sh/d' ~/.bashrc"
	@echo "🧹 Removing installation files..."
	@podman exec $(TEST_CONTAINER_NAME) bash -c "cd /home/$(TEST_USER) && rm -f *.tar.gz $(INSTALL_SCRIPT)"
	@echo ""
	@echo "✅ Sysroot toolchain uninstalled successfully!"
	@echo "❌ VS Code Remote SSH will now fail again (back to glibc 2.17)"
	@echo "📊 Verify removal:"
	@echo "   podman exec $(TEST_CONTAINER_NAME) ls -la $(SYSROOT_INSTALL_PATH)  # Should not exist"

# Attach to running test container
.PHONY: attach-test
attach-test:
	@echo "🔗 Attaching to running test container..."
	@if ! podman ps --format "{{.Names}}" | grep -q "$(TEST_CONTAINER_NAME)"; then \
		echo "❌ Test container not running. Start it first with: make test-env"; \
		exit 1; \
	fi
	@echo "📋 Container info:"; \
	podman ps --filter "name=$(TEST_CONTAINER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "🚀 Attaching to container as $(TEST_USER)..."
	@echo "💡 Tip: Type 'exit' to detach from container"
	@echo ""
	podman exec -it --user $(TEST_USER) --workdir /home/$(TEST_USER) $(TEST_CONTAINER_NAME) bash -l

# Stop running test container
.PHONY: stop-test
stop-test:
	@echo "🛑 Stopping test container..."
	@if ! podman ps --format "{{.Names}}" | grep -q "$(TEST_CONTAINER_NAME)"; then \
		echo "ℹ️  Test container is not running"; \
		exit 0; \
	fi
	@echo "📋 Stopping container: $(TEST_CONTAINER_NAME)"
	podman stop $(TEST_CONTAINER_NAME)
	@echo "✅ Test container stopped successfully!"
	@echo "💡 Restart with: make test-env"