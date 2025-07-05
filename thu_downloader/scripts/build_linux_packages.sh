#!/bin/bash
set -e
set -x

VERSION="$1"
BUILD_DIR="$2"
PACKAGE_TYPES="$3"  # Optional: comma-separated list of package types (deb,rpm)

if [ -z "$VERSION" ] || [ -z "$BUILD_DIR" ]; then
    echo "Usage: $0 <version> <build_dir> [package_types]"
    echo "  package_types: deb,rpm (default: all)"
    exit 1
fi

# Default to all package types if not specified
if [ -z "$PACKAGE_TYPES" ]; then
    PACKAGE_TYPES="deb,rpm"
fi

SCRIPT_DIR="$(dirname "$0")"
echo "Building Linux packages for version $VERSION"
echo "BUILD_DIR: $BUILD_DIR"
echo "Package types: $PACKAGE_TYPES"

# Create working directories
WORK_DIR="./linux-packages-build"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

# Function to build DEB package
build_deb() {
    echo "Building DEB package..."
    DEB_DIR="$WORK_DIR/deb"
    echo "DEB_DIR: $DEB_DIR"
    mkdir -p "$DEB_DIR"
    mkdir -p "$DEB_DIR/opt/thu-downloader"
    mkdir -p "$DEB_DIR/usr/share/applications"
    mkdir -p "$DEB_DIR/usr/share/icons/hicolor/scalable/apps"
    mkdir -p "$DEB_DIR/usr/share/metainfo"
    mkdir -p "$DEB_DIR/DEBIAN"

    # Copy application files
    cp -r "$BUILD_DIR"/* "$DEB_DIR/opt/thu-downloader/"

    # Copy DEB control files
    cp -r "$SCRIPT_DIR/linux_deb/DEBIAN"/* "$DEB_DIR/DEBIAN/"
    if [ -d "$SCRIPT_DIR/linux_deb/usr" ]; then
        cp -r "$SCRIPT_DIR/linux_deb/usr"/* "$DEB_DIR/usr/"
    fi

    # Copy desktop file and icon
    cp "$SCRIPT_DIR/linux_deb/thu-downloader.desktop" "$DEB_DIR/usr/share/applications/"
    cp "$SCRIPT_DIR/packaging/thu-downloader.svg" "$DEB_DIR/usr/share/icons/hicolor/scalable/apps/"
    cp "$SCRIPT_DIR/packaging/io.thu-downloader.metainfo.xml" "$DEB_DIR/usr/share/metainfo/"

    # Update version in control file
    sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$DEB_DIR/DEBIAN/control"

    # Set permissions
    chmod 755 "$DEB_DIR/DEBIAN/postinst" "$DEB_DIR/DEBIAN/prerm"
    chmod 755 "$DEB_DIR/opt/thu-downloader/thu_downloader"

    # Build DEB package
    dpkg-deb --build "$DEB_DIR" "thu-downloader_${VERSION}_amd64.deb"
    echo "DEB package built: thu-downloader_${VERSION}_amd64.deb"
}

# Function to build RPM package
build_rpm() {
    echo "Building RPM package..."
    RPM_DIR="$WORK_DIR/rpm"
    mkdir -p "$RPM_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

    # Create source tarball
    TAR_NAME="thu-downloader-$VERSION"
    mkdir -p "$RPM_DIR/$TAR_NAME/bundle"
    cp -r "$BUILD_DIR"/* "$RPM_DIR/$TAR_NAME/bundle/"
    cd "$RPM_DIR"
    tar -czf "SOURCES/thu-downloader-$VERSION.tar.gz" "$TAR_NAME"
    cd - > /dev/null
    
    rm -rf "$RPM_DIR/$TAR_NAME"

    # # Copy and update spec file
    cp "$SCRIPT_DIR/linux_rpm/thu-downloader.spec" "$RPM_DIR/SPECS/"
    sed -i "s/VERSION_PLACEHOLDER/$VERSION/g" "$RPM_DIR/SPECS/thu-downloader.spec"

    # # Build RPM package
    rpmbuild --define "_topdir $(pwd)/$RPM_DIR" -bb "$RPM_DIR/SPECS/thu-downloader.spec"
    
    # # Copy built RPM to current directory
    find "$RPM_DIR/RPMS" -name "*.rpm" -exec cp {} . \;
    echo "RPM package built successfully"
}


# Build requested package types
IFS=',' read -ra PACKAGE_ARRAY <<< "$PACKAGE_TYPES"
for package_type in "${PACKAGE_ARRAY[@]}"; do
    case "$package_type" in
        "deb")
            build_deb
            ;;
        "rpm")
            build_rpm
            ;;
        *)
            echo "Unknown package type: $package_type"
            echo "Supported types: deb, rpm"
            exit 1
            ;;
    esac
done

# Clean up
# rm -rf "$WORK_DIR"

echo "Linux packages built successfully!"
ls -la *.deb *.rpm 2>/dev/null || echo "Check for package files in current directory"