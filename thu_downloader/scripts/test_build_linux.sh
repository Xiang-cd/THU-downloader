#!/bin/bash
set -e

echo "Testing Linux package building for THU Downloader"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "Error: This script must be run from the project root directory"
    exit 1
fi

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Build the Flutter application
echo "Building Flutter application..."
flutter clean
flutter pub get
flutter build linux --release

# Check if build was successful
if [ ! -d "build/linux/x64/release/bundle" ]; then
    echo "Error: Flutter build failed"
    exit 1
fi

# Test package building
echo "Testing package building..."

# Test DEB package
echo "Testing DEB package build..."
./scripts/build_linux_packages.sh 1.0.0test build/linux/x64/release/bundle "deb"

# Test RPM package
echo "Testing RPM package build..."
./scripts/build_linux_packages.sh 1.0.0test build/linux/x64/release/bundle "rpm"


echo "All package builds completed successfully!"
echo "Generated packages:"
ls -al *.deb || echo "no deb package"
ls -al *.rpm || echo "no rpm package"

# Clean up test packages
echo "Cleaning up test packages..."
rm *.deb *.rpm

echo "Test completed successfully!" 