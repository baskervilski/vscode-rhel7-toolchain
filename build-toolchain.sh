#!/bin/bash
# Build script for mounted toolchain output

set -e

# Ensure crosstool-ng is in PATH (Docker environment fix)
export PATH=/crosstool-ng-1.26.0/out/bin:/usr/local/bin:$PATH

echo "=== Crosstool-NG Build Script ==="
echo "PATH: $PATH"
echo "Checking ct-ng availability..."
which ct-ng || echo "❌ ct-ng not found in PATH"
echo "Output directory: /home/ctng/output"
echo "Configuration: x86_64-gcc-8.5.0-glibc-2.28.config"
echo ""

OUTPUT_DIRNAME=/home/ctng/output
# Load the configuration
echo "Loading configuration..."
cp x86_64-gcc-8.5.0-glibc-2.28.config $OUTPUT_DIRNAME/.config
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

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build completed successfully at $(date)"
    echo "🎉 Total time: $(printf "%02d:%02d" $((COUNTER / 60)) $((COUNTER % 60)))"
else
    echo ""
    echo "❌ Build failed with exit code $BUILD_EXIT_CODE at $(date)"
    echo "💥 Total time before failure: $(printf "%02d:%02d" $((COUNTER / 60)) $((COUNTER % 60)))"
    echo ""
    echo "📋 Last 100 lines of build output (filtered):"
    echo "================================================="
    
    # Show last 100 lines with timestamp filtering
    tail -n 100 "$BUILD_LOG" | grep -v '\[[0-9]{2}:[0-9]{2}\]' || {
        echo "No meaningful output found in last 100 lines."
        echo ""
        echo "📋 Raw last 20 lines (unfiltered):"
        tail -n 20 "$BUILD_LOG"
    }
    
    echo "================================================="
    echo ""
    echo "💡 Full build log available at: $BUILD_LOG"
    exit $BUILD_EXIT_CODE
fi

echo ""
echo "✅ Build completed successfully at: $(date)"
echo "Toolchain installed to: $OUTPUT_DIRNAME"
echo ""
echo "Contents:"
ls -la $OUTPUT_DIRNAME/

echo ""
echo "✅ Toolchain build completed successfully!"
echo "The toolchain is now available in the mounted output directory."