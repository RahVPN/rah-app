#!/usr/bin/env bash
# One-shot setup. Run inside the project directory (where this tools/ folder lives).
#   ./tools/android/setup.sh
# To repair a project where `flutter create` was already run (any org / package name):
#   python3 tools/android/apply_overlay.py && python3 tools/android/patch_gradle.py && bash tools/android/fetch_deps.sh && flutter clean
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

command -v flutter >/dev/null || { echo "flutter not found in PATH" >&2; exit 1; }

# 1. generate the Android project shell; keep our own lib/ and pubspec.yaml untouched
BK="$(mktemp -d)"; trap 'rm -rf "$BK"' EXIT
cp -R lib "$BK/lib"; cp pubspec.yaml "$BK/pubspec.yaml"
flutter create --org app.rah --project-name rah_app --platforms android .
rm -rf lib && cp -R "$BK/lib" lib && cp "$BK/pubspec.yaml" pubspec.yaml
rm -f test/widget_test.dart   # template test refers to the template app

# 2. Kotlin + manifest, adapted to the project's real namespace (see apply_overlay.py)
python3 tools/android/apply_overlay.py

# 3. gradle: legacy native-lib packaging, arm64 + x86_64 (emulator), minSdk 29, hev AAR
python3 tools/android/patch_gradle.py

# 4. native binaries
bash tools/android/fetch_deps.sh

echo
echo "Next: flutter clean && flutter run   (best on a physical arm64 device)"
