#!/bin/bash
# Build script for mounted toolchain output

set -e

# Default values
VERBOSE_MODE=false
CONFIG_FILE="x86_64-gcc-8.5.0-glibc-2.28.config"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE_MODE=true
            shift
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Build crosstool-ng toolchain"
            echo ""
            echo "Options:"
            echo "  -v, --verbose           Enable verbose output (show full build log)"
            echo "  -c, --config CONFIG     Use specific config file (default: x86_64-gcc-8.5.0-glibc-2.28.config)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Use default config, filtered output"
            echo "  $0 --verbose                          # Use default config, verbose output"
            echo "  $0 --config my-config.config         # Use custom config, filtered output"
            echo "  $0 --verbose --config my-config.config # Use custom config, verbose output"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Ensure crosstool-ng is in PATH (Docker environment fix)
export PATH=/crosstool-ng-1.26.0/out/bin:/usr/local/bin:$PATH

echo "=== Crosstool-NG Build Script ==="
echo "PATH: $PATH"
echo "Verbose mode: $VERBOSE_MODE"
echo "Configuration file: $CONFIG_FILE"
echo "Checking ct-ng availability..."
which ct-ng || echo "❌ ct-ng not found in PATH"
echo "Output directory: /home/ctng/output"
echo ""

OUTPUT_DIRNAME=/home/ctng/output
# Load the configuration
echo "Loading configuration: $CONFIG_FILE"
if [ -f "configs/$CONFIG_FILE" ]; then
    cp "configs/$CONFIG_FILE" $OUTPUT_DIRNAME/.config
elif [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" $OUTPUT_DIRNAME/.config
else
    echo "❌ Configuration file not found: $CONFIG_FILE"
    echo "Available configs:"
    ls -la configs/ 2>/dev/null || echo "No configs directory found"
    exit 1
fi
cd $OUTPUT_DIRNAME

# Show configuration summary
echo ""
echo "=== Build Configuration ==="
echo "Target: $(grep CT_TARGET .config | cut -d= -f2 | tr -d '"')"
echo "GCC Version: $(grep CT_GCC_VERSION .config | cut -d= -f2 | tr -d '"')"
echo "Glibc Version: $(grep CT_GLIBC_VERSION .config | cut -d= -f2 | tr -d '"')"
echo "Output Directory: $(grep CT_PREFIX_DIR .config | cut -d= -f2 | tr -d '"')"
echo ""

echo "Starting build (this will take 30-60 minutes)..."
echo "Build started at: $(date)"
echo ""

if [ "$VERBOSE_MODE" = "true" ]; then
    echo "🔨 Building toolchain with FULL OUTPUT (verbose mode)..."
    echo "📋 All build output will be displayed in real-time..."
    echo ""
    
    # Build with full output displayed
    ct-ng build
    BUILD_EXIT_CODE=$?
    
else
    echo "🔨 Building toolchain with suppressed output..."
    echo "⏳ Status updates every 10 seconds, full output only on error..."
    echo ""

    # Build with completely suppressed output and periodic status updates
    BUILD_LOG="/tmp/ctng-build.log"

    # Start the build in background with all output redirected
    ct-ng build > "$BUILD_LOG" 2>&1 &
    BUILD_PID=$!

    echo "🚀 Build started at $(date) (PID: $BUILD_PID)"

    # Monitor progress every 10 seconds
    COUNTER=0
    while kill -0 $BUILD_PID 2>/dev/null; do
        sleep 10
        COUNTER=$((COUNTER + 10))
        MINUTES=$((COUNTER / 60))
        SECONDS=$((COUNTER % 60))
        printf "⏳ Build running: %02d:%02d elapsed ($(date))\n" $MINUTES $SECONDS
    done

    # Wait for build to complete and check exit status
    wait $BUILD_PID
    BUILD_EXIT_CODE=$?
fi

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully at $(date)"
    if [ "$VERBOSE_MODE" = "true" ]; then
        END_TIME=$(date +%s)
        TOTAL_SECONDS=$((END_TIME - START_TIME))
        echo "🎉 Total time: $(printf "%02d:%02d" $((TOTAL_SECONDS / 60)) $((TOTAL_SECONDS % 60)))"
    else
        echo "🎉 Total time: $(printf "%02d:%02d" $((COUNTER / 60)) $((COUNTER % 60)))"
    fi
else
    echo ""
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE at $(date)"
    if [ "$VERBOSE_MODE" = "true" ]; then
        END_TIME=$(date +%s)
        TOTAL_SECONDS=$((END_TIME - START_TIME))
        echo "💥 Total time before failure: $(printf "%02d:%02d" $((TOTAL_SECONDS / 60)) $((TOTAL_SECONDS % 60)))"
        echo ""
        echo "� Check the output above for build errors."
    else
        echo "�💥 Total time before failure: $(printf "%02d:%02d" $((COUNTER / 60)) $((COUNTER % 60)))"
        echo ""
        echo "📋 Last 100 lines of build output (filtered):"
        echo "================================================="
    fi
    
    # Show last 100 lines with timestamp filtering (only for filtered mode)
    if [ "$VERBOSE_MODE" != "true" ]; then
        tail -n 100 "$BUILD_LOG" | grep -v '\[[0-9]{2}:[0-9]{2}\]' || {
            echo "No meaningful output found in last 100 lines."
            echo ""
            echo "📋 Raw last 20 lines (unfiltered):"
            tail -n 20 "$BUILD_LOG"
        }
    fi
    
    echo "================================================="
    echo ""
    echo "💡 Full build log available at: $BUILD_LOG"
    exit $BUILD_EXIT_CODE
fi

# Ensure all binaries in the sysroot directory are executable
find $OUTPUT_DIRNAME -type f -exec chmod +x {} \;

echo ""
echo "Toolchain installed to: $OUTPUT_DIRNAME"
echo ""
echo "Contents:"
ls -la $OUTPUT_DIRNAME/

echo ""
echo "✅ Toolchain build completed successfully!"
echo "The toolchain is now available in the mounted output directory."