#!/usr/bin/env python3
"""Patch android/app/build.gradle(.kts) for the native pieces. Idempotent; fails loudly."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = ROOT / "android" / "app"
MARK = "rah-patched"

kts = APP / "build.gradle.kts"
groovy = APP / "build.gradle"
if kts.exists():
    path, is_kts = kts, True
elif groovy.exists():
    path, is_kts = groovy, False
else:
    sys.exit("android/app/build.gradle(.kts) not found - run 'flutter create' first")

text = path.read_text()

if MARK in text:
    # Migrate a file patched by an older version of this script:
    #  - drop the ndk { abiFilters } line (conflicts with `flutter build apk --split-per-abi`)
    #  - hev-socks5-tunnel.aar declares minSdk 29 (an older version wrote 24)
    new = re.sub(r"^[ \t]*ndk \{ abiFilters[^\n]*\n", "", text, flags=re.M)
    new = new.replace("minSdk = 24", "minSdk = 29").replace("minSdkVersion 24", "minSdkVersion 29")
    if new != text:
        path.write_text(new)
        print("migrated:", path.name)
    else:
        print("already patched:", path.name)
    sys.exit(0)

if is_kts:
    packaging = f"    packaging {{ jniLibs {{ useLegacyPackaging = true }} }} // {MARK}\n"
    deps = '\ndependencies {\n    implementation(files("libs/hev-socks5-tunnel.aar"))\n}\n'
    min_sdk_re = r"minSdk\s*=\s*[^\n]+"
    min_sdk_new = "minSdk = 29"
else:
    packaging = f"    packaging {{ jniLibs {{ useLegacyPackaging = true }} }} // {MARK}\n"
    deps = "\ndependencies {\n    implementation files('libs/hev-socks5-tunnel.aar')\n}\n"
    min_sdk_re = r"minSdk(?:Version)?\s*(?:=\s*)?[^\n]+"
    min_sdk_new = "minSdkVersion 29"


def insert_after(pattern: str, snippet: str, what: str) -> None:
    global text
    m = re.search(pattern, text, flags=re.M)
    if not m:
        sys.exit(f"could not find {what} in {path.name}; apply it manually (see README)")
    text = text[: m.end()] + "\n" + snippet.rstrip("\n") + text[m.end():]


insert_after(r"^android\s*\{", packaging, "the android { } block")
if not re.search(min_sdk_re, text):
    sys.exit("could not find minSdk in defaultConfig; set it to 29 manually")
text = re.sub(min_sdk_re, min_sdk_new, text, count=1)

if re.search(r"^dependencies\s*\{", text, flags=re.M):
    dep_line = deps.strip().splitlines()[1]
    insert_after(r"^dependencies\s*\{", dep_line, "dependencies { }")
else:
    text = text.rstrip("\n") + "\n" + deps

path.write_text(text)
print("patched:", path)
