#!/usr/bin/env bash
# Build the Flutter Linux release and package it as tar.gz, deb, and/or rpm.
# Usage: tools/linux/package_linux.sh [tar|deb|rpm|all] (default: tar)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

TARGET="${1:-tar}"
case "$TARGET" in tar|deb|rpm|all) ;; *)
  echo "usage: $0 [tar|deb|rpm|all]" >&2
  exit 2
  ;;
esac

if [[ "$TARGET" == deb || "$TARGET" == all ]] && ! command -v dpkg-deb >/dev/null; then
  echo "dpkg-deb is required for .deb packages (install dpkg)." >&2
  exit 1
fi
if [[ "$TARGET" == rpm || "$TARGET" == all ]] && ! command -v rpmbuild >/dev/null; then
  echo "rpmbuild is required for .rpm packages (install rpm-build or rpm)." >&2
  exit 1
fi

[ -f linux/aether/aether ] || bash tools/linux/fetch_deps_linux.sh
flutter build linux --release

case "$(uname -m)" in
  x86_64|amd64) FLUTTER_ARCH=x64; TAR_ARCH=x86_64; DEB_ARCH=amd64; RPM_ARCH=x86_64 ;;
  aarch64|arm64) FLUTTER_ARCH=arm64; TAR_ARCH=arm64; DEB_ARCH=arm64; RPM_ARCH=aarch64 ;;
  *) echo "unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

VERSION="$(sed -n 's/^version: *\([^+ ]*\).*/\1/p' pubspec.yaml | head -n 1)"
[ -n "$VERSION" ] || { echo "could not read version from pubspec.yaml" >&2; exit 1; }
BUNDLE="build/linux/$FLUTTER_ARCH/release/bundle"
[ -x "$BUNDLE/rahvpn" ] || { echo "$BUNDLE/rahvpn not found" >&2; exit 1; }

rm -rf "$BUNDLE/aether"
cp -R linux/aether "$BUNDLE/aether"
install -m 755 tools/linux/install_linux_tun.sh "$BUNDLE/install_linux_tun.sh"

mkdir -p dist
if [[ "$TARGET" == tar || "$TARGET" == all ]]; then
  OUT="dist/rahvpn-linux-$TAR_ARCH.tar.gz"
  tar -czf "$OUT" --transform 's,^bundle,rahvpn,' -C "$(dirname "$BUNDLE")" bundle
  echo "created $OUT"
fi

if [[ "$TARGET" == deb || "$TARGET" == rpm || "$TARGET" == all ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  STAGE="$TMP/stage"
  mkdir -p "$STAGE/opt/rahvpn" \
    "$STAGE/usr/bin" \
    "$STAGE/usr/share/applications" \
    "$STAGE/usr/share/icons/hicolor/256x256/apps"
  cp -R "$BUNDLE/." "$STAGE/opt/rahvpn/"
  cat > "$STAGE/usr/bin/rahvpn" <<'LAUNCHER'
#!/bin/sh
exec /opt/rahvpn/rahvpn "$@"
LAUNCHER
  chmod 755 "$STAGE/usr/bin/rahvpn"
  install -m 644 assets/icon/rahvpn.png \
    "$STAGE/usr/share/icons/hicolor/256x256/apps/rahvpn.png"
  cat > "$STAGE/usr/share/applications/com.rahvpn.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=RahVPN
Comment=Connect using Aether and Psiphon
Exec=rahvpn
Icon=rahvpn
Terminal=false
Categories=Network;Security;
StartupWMClass=com.rahvpn
DESKTOP

  if [[ "$TARGET" == deb || "$TARGET" == all ]]; then
    command -v dpkg-deb >/dev/null || {
      echo "dpkg-deb is required for .deb packages (install dpkg)." >&2
      exit 1
    }
    DEBROOT="$TMP/deb-root"
    cp -a "$STAGE/." "$DEBROOT/"
    mkdir -p "$DEBROOT/DEBIAN"
    cat > "$DEBROOT/DEBIAN/control" <<CONTROL
Package: rahvpn
Version: $VERSION
Section: net
Priority: optional
Architecture: $DEB_ARCH
Depends: libc6, libstdc++6, libgtk-3-0, libayatana-appindicator3-1, iproute2, util-linux, pkexec, polkitd, iptables
Maintainer: RahVPN
Description: Desktop VPN client with system TUN support
 Flutter client for Aether and Psiphon.
CONTROL
    OUT="dist/rahvpn_${VERSION}_${DEB_ARCH}.deb"
    dpkg-deb --root-owner-group --build "$DEBROOT" "$OUT"
    echo "created $OUT"
  fi

  if [[ "$TARGET" == rpm || "$TARGET" == all ]]; then
    command -v rpmbuild >/dev/null || {
      echo "rpmbuild is required for .rpm packages (install rpm-build or rpm)." >&2
      exit 1
    }
    RPMTOP="$TMP/rpmbuild"
    mkdir -p "$RPMTOP/BUILD" "$RPMTOP/BUILDROOT" "$RPMTOP/RPMS" \
      "$RPMTOP/SOURCES" "$RPMTOP/SPECS" "$RPMTOP/SRPMS"
    tar -czf "$RPMTOP/SOURCES/rahvpn-stage.tar.gz" -C "$STAGE" .
    cat > "$RPMTOP/SPECS/rahvpn.spec" <<SPEC
Name:           rahvpn
Version:        $VERSION
Release:        1%{?dist}
Summary:        Desktop VPN client with system TUN support
License:        Proprietary
BuildArch:      $RPM_ARCH
Requires:       glibc, libstdc++, gtk3, libayatana-appindicator-gtk3, iproute, util-linux, polkit, iptables
Source0:        rahvpn-stage.tar.gz

%description
Flutter desktop client for Aether and Psiphon VPN protocols.

%prep

%build

%install
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}

%files
/opt/rahvpn
/usr/bin/rahvpn
/usr/share/applications/com.rahvpn.desktop
/usr/share/icons/hicolor/256x256/apps/rahvpn.png
SPEC
    rpmbuild --define "_topdir $RPMTOP" -bb "$RPMTOP/SPECS/rahvpn.spec"
    RPMFILE="$(find "$RPMTOP/RPMS/$RPM_ARCH" -maxdepth 1 -type f \
      -name "rahvpn-$VERSION-1*.$RPM_ARCH.rpm" -print -quit)"
    [ -f "$RPMFILE" ] || {
      echo "rpmbuild completed but did not produce the expected file: $RPMFILE" >&2
      exit 1
    }
    OUT="dist/$(basename "$RPMFILE")"
    cp "$RPMFILE" "$OUT"
    echo "created $OUT"
  fi
fi
