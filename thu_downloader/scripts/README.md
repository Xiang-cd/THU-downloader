# Linux Package Building

This directory contains scripts and configuration files for building Linux packages (DEB and RPM) for THU Downloader.

## Structure

```
scripts/
├── build_linux_packages.sh          # Main build script
├── linux_deb/                       # Debian package configuration
│   ├── DEBIAN/
│   │   ├── control                   # Package metadata
│   │   ├── postinst                  # Post-installation script
│   │   └── prerm                     # Pre-removal script
│   └── usr/
│       └── share/
│           └── applications/
│               └── thu-downloader.desktop  # Desktop entry
├── linux_rpm/
│   └── thu-downloader.spec          # RPM spec file
└── windows_installer/               # Windows installer files
```

## Usage

### Manual Build

To build packages manually:

```bash
cd thu_downloader
flutter build linux --release
scripts/build_linux_packages.sh 1.0.0 build/linux/x64/release/bundle
```

### GitHub Actions

The packages are automatically built when a new tag is pushed:

1. Push a tag: `git tag v1.0.0 && git push origin v1.0.0`
2. GitHub Actions will build and release DEB and RPM packages

## Package Details

### DEB Package
- **Name**: thu-downloader
- **Architecture**: amd64
- **Dependencies**: libc6, libgtk-3-0, libglib2.0-0
- **Installation path**: `/opt/thu-downloader/`
- **Desktop entry**: `/usr/share/applications/thu-downloader.desktop`

### RPM Package
- **Name**: thu-downloader
- **Architecture**: x86_64
- **Dependencies**: gtk3, glib2
- **Installation path**: `/opt/thu-downloader/`
- **Desktop entry**: `/usr/share/applications/thu-downloader.desktop`

## Installation

### Ubuntu/Debian
```bash
sudo dpkg -i thu-downloader_1.0.0_amd64.deb
sudo apt-get install -f  # Fix dependencies if needed
```

### CentOS/RHEL/Fedora
```bash
sudo rpm -i thu-downloader-1.0.0-1.x86_64.rpm
# or
sudo dnf install thu-downloader-1.0.0-1.x86_64.rpm
```

## Uninstallation

### Ubuntu/Debian
```bash
sudo apt-get remove thu-downloader
```

### CentOS/RHEL/Fedora
```bash
sudo rpm -e thu-downloader
# or
sudo dnf remove thu-downloader
```