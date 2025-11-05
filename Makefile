# Makefile for RHEL7 sysroot container

# Variables
IMAGE_NAME = rhel7-sysroot
CONTAINER_NAME = rhel7-sysroot-container
EXPORT_DIR = ./exported-toolchain
TOOLCHAIN_ARCHIVE = rhel7-toolchain-$(shell date +%Y%m%d-%H%M%S).tar.gz
OUTPUT_DIR = $(shell pwd)/toolchain-output

# Default target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build           - Build the container image using podman"
	@echo "  docker-build    - Build the container image using docker (CI/CD)"
	@echo "  run             - Start container with mounted output directory (interactive)"
	@echo "  build-toolchain - Build toolchain directly to mounted output (automated)"
	@echo "  docker-toolchain - Build toolchain using docker (CI/CD compatible)"
	@echo "  package         - Package toolchain for distribution"
	@echo "  check           - Check if toolchain exists in mounted output"
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
		echo "  Interactive: make run -> ./build-toolchain.sh"; \
		echo "  Automated:   make build-toolchain"; \
	fi



# Build toolchain directly to mounted output directory
.PHONY: build-toolchain
build-toolchain:
	@echo "Creating output directory: $(OUTPUT_DIR)"
	@mkdir -p $(OUTPUT_DIR)
	@echo "Setting proper permissions for output directory..."
	@chmod 755 $(OUTPUT_DIR)
	@echo "Building toolchain using build-toolchain.sh script..."
	@echo "This will take 30-60 minutes..."
	podman run --rm --name $(CONTAINER_NAME) \
		-v $(OUTPUT_DIR):/home/ctng/output:Z \
		--userns=keep-id \
		$(IMAGE_NAME) ./build-toolchain.sh

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
	docker run --rm --name $(CONTAINER_NAME)-build \
		-v $(OUTPUT_DIR):/home/ctng/output \
		--user ctng \
		$(IMAGE_NAME) ./build-toolchain.sh

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
	@echo "Creating portable archive..."
	@tar -czf $(TOOLCHAIN_ARCHIVE) -C $(OUTPUT_DIR) .
	@echo "Downloading patchelf for offline installation..."
	@wget -q -P $(EXPORT_DIR) https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0-x86_64.tar.gz
	@echo "Copying installation script..."
	@cp install-toolchain.sh $(EXPORT_DIR)/
	@chmod +x $(EXPORT_DIR)/install-toolchain.sh
	@mv $(TOOLCHAIN_ARCHIVE) $(EXPORT_DIR)/
	@echo ""
	@echo "✅ Toolchain packaged successfully!"
	@echo "📦 Archive: $(EXPORT_DIR)/$(TOOLCHAIN_ARCHIVE)"
	@echo "📋 Installer: $(EXPORT_DIR)/install-toolchain.sh"
	@echo "🔧 patchelf: $(EXPORT_DIR)/patchelf-0.18.0-x86_64.tar.gz"
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