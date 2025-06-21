#!/bin/bash
set -e

VERSION="$1"
BUILD_DIR="$2"
SCRIPT_DIR="$(dirname "$0")"

if [ -z "$VERSION" ] || [ -z "$BUILD_DIR" ]; then
    echo "Usage: $0 <version> <build_dir>"
    exit 1
fi

echo "Building Linux packages for version $VERSION"

# Create working directories in current directory to avoid permission issues
WORK_DIR="./linux-packages-build"
DEB_DIR="$WORK_DIR/deb"
RPM_DIR="$WORK_DIR/rpm"

rm -rf "$WORK_DIR"
mkdir -p "$DEB_DIR" "$RPM_DIR"

# Build DEB package
echo "Building DEB package..."
mkdir -p "$DEB_DIR/opt/thu-downloader"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/DEBIAN"

# Copy application files
cp -r "$BUILD_DIR"/* "$DEB_DIR/opt/thu-downloader/"

# Copy DEB control files
cp -r "$SCRIPT_DIR/linux_deb/DEBIAN"/* "$DEB_DIR/DEBIAN/"
if [ -d "$SCRIPT_DIR/linux_deb/usr" ]; then
    cp -r "$SCRIPT_DIR/linux_deb/usr"/* "$DEB_DIR/usr/"
fi

# Update version in control file
sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$DEB_DIR/DEBIAN/control"

# Set permissions
chmod 755 "$DEB_DIR/DEBIAN/postinst" "$DEB_DIR/DEBIAN/prerm"
chmod 755 "$DEB_DIR/opt/thu-downloader/thu_downloader"

# Build DEB package
dpkg-deb --build "$DEB_DIR" "thu-downloader_${VERSION}_amd64.deb"

# Build RPM package
echo "Building RPM package..."
mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
TAR_NAME="thu-downloader-$VERSION"
mkdir -p "$WORK_DIR/$TAR_NAME/bundle"
cp -r "$BUILD_DIR"/* "$WORK_DIR/$TAR_NAME/bundle/"
cd "$WORK_DIR"
tar -czf "$RPM_DIR/SOURCES/thu-downloader-$VERSION.tar.gz" "$TAR_NAME"
rm -rf "$TAR_NAME"
cd ..

# Copy and update spec file
cp "$SCRIPT_DIR/linux_rpm/thu-downloader.spec" "$RPM_DIR/SPECS/"
sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$RPM_DIR/SPECS/thu-downloader.spec"

# Build RPM package
rpmbuild --define "_topdir $(pwd)/$RPM_DIR" -bb "$RPM_DIR/SPECS/thu-downloader.spec"

# Copy built packages to current directory
cp "thu-downloader_${VERSION}_amd64.deb" .
find "$RPM_DIR/RPMS" -name "*.rpm" -exec cp {} . \;

# Clean up
rm -rf "$WORK_DIR"

echo "Linux packages built successfully!"
ls -la *.deb *.rpm 2>/dev/null || echo "Check for package files in current directory" 