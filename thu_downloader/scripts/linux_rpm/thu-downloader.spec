Name:           thu-downloader
Version:        VERSION_PLACEHOLDER
Release:        1%{?dist}
Summary:        THU Downloader - A Flutter application for downloading files

License:        MIT
URL:            https://github.com/Xiang-cd/THU-downloader
Source0:        %{name}-%{version}.tar.gz

Requires:       gtk3, glib2, desktop-file-utils

%description
THU Downloader is a cross-platform application built with Flutter
for downloading files from Tsinghua University resources.

%prep
%setup -q

%build
# Nothing to build, pre-compiled binary

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/thu-downloader
mkdir -p $RPM_BUILD_ROOT/usr/share/applications
mkdir -p $RPM_BUILD_ROOT/usr/share/icons/hicolor/256x256/apps

# Copy application files
cp -r bundle/* $RPM_BUILD_ROOT/opt/thu-downloader/

# Install desktop file
cat > $RPM_BUILD_ROOT/usr/share/applications/thu-downloader.desktop << EOF
[Desktop Entry]
Version=VERSION_PLACEHOLDER
Type=Application
Name=THU Downloader
Comment=A Flutter application for downloading files
Exec=/opt/thu-downloader/thu_downloader
Icon=thu-downloader
Terminal=false
Categories=Utility;Network;
StartupWMClass=thu_downloader
MimeType=application/x-thu-downloader;
EOF

%files
/opt/thu-downloader/*
/usr/share/applications/thu-downloader.desktop

%post
# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

# Update icon cache
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t /usr/share/icons/hicolor
fi

# Make the binary executable
chmod +x /opt/thu-downloader/thu_downloader

%postun
# Update desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database /usr/share/applications
fi

%changelog
* Mon Jan 01 2024 Builder <builder@example.com> - %{version}-%{release}
- Initial package 