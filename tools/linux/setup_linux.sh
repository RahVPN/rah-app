#!/usr/bin/env bash
# One-shot Linux setup. Run from the project root:  ./tools/linux/setup_linux.sh
# Needs: flutter (>= 3.35, linux desktop enabled), and the build deps:
#   Debian/Ubuntu: sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libayatana-appindicator3-dev liblzma-dev
#   Fedora:        sudo dnf install clang cmake ninja-build gtk3-devel libayatana-appindicator-gtk3-devel xz-devel
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
command -v flutter >/dev/null || { echo "flutter not found in PATH" >&2; exit 1; }

flutter config --enable-linux-desktop >/dev/null
if [ ! -f linux/CMakeLists.txt ]; then
  # Adds only the missing linux/ shell; existing lib/, pubspec.yaml and android/ are left alone.
  flutter create --org app.rah --project-name rah_app --platforms linux .
fi
bash tools/linux/fetch_deps_linux.sh "$@"
flutter pub get
echo
echo "Next: flutter run -d linux     (dev: finds the core in ./linux/aether)"
echo "Full-system TUN: run ./tools/linux/install_linux_tun.sh to check prerequisites; one polkit authorization starts each VPN session."
echo "      tools/linux/package_linux.sh   (release tarball in dist/)"
