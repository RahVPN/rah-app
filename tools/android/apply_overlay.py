#!/usr/bin/env python3
"""Copy the Kotlin + manifest overlay into android/, using the project's REAL namespace.

`flutter create` only applies --org to a fresh project; if android/ already existed (or was
created without --org) the namespace is e.g. com.example.rah_app. The manifest resolves
".MainActivity" against that namespace, so our classes must live in it, otherwise the stock
MainActivity runs and the channels "rah/control" / "rah/events" have no handler
(MissingPluginException). Idempotent.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = ROOT / "android" / "app"
MAIN = APP / "src" / "main"
OVERLAY = ROOT / "android_overlay" / "app" / "src" / "main"
OUR_FILES = ("MainActivity.kt", "CoreService.kt")


def read_namespace() -> str:
    for name in ("build.gradle.kts", "build.gradle"):
        f = APP / name
        if f.exists():
            m = re.search(r'^\s*namespace\s*=?\s*["\']([\w.]+)["\']', f.read_text(), re.M)
            if m:
                return m.group(1)
    sys.exit("could not read `namespace` from android/app/build.gradle(.kts); run 'flutter create' first")


def prune_empty_dirs(base: pathlib.Path) -> None:
    dirs = sorted((p for p in base.rglob("*") if p.is_dir()), key=lambda p: len(p.parts), reverse=True)
    for d in dirs:
        if not any(d.iterdir()):
            d.rmdir()


def main() -> None:
    if not APP.exists():
        sys.exit("android/app not found; run 'flutter create' first")
    ns = read_namespace()
    target = MAIN / "kotlin" / pathlib.Path(*ns.split("."))
    target.mkdir(parents=True, exist_ok=True)

    # Remove the stock MainActivity and any stale copies of our classes in other packages.
    for root in ("kotlin", "java"):
        base = MAIN / root
        if not base.exists():
            continue
        for f in list(base.rglob("*")):
            if f.is_file() and f.parent != target and f.name in (
                "MainActivity.kt", "MainActivity.java", "CoreService.kt"
            ):
                print("removed:", f.relative_to(ROOT))
                f.unlink()
        prune_empty_dirs(base)
    target.mkdir(parents=True, exist_ok=True)

    src_dir = next((OVERLAY / "kotlin").rglob("MainActivity.kt"), None)
    if src_dir is None:
        sys.exit("overlay Kotlin sources not found under android_overlay/")
    src_dir = src_dir.parent
    for name in OUR_FILES:
        text = (src_dir / name).read_text()
        text, n = re.subn(r"^package .*$", f"package {ns}", text, count=1, flags=re.M)
        if n != 1:
            sys.exit(f"no package line in {name}")
        (target / name).write_text(text)
        print("wrote:", (target / name).relative_to(ROOT))

    manifest = (OVERLAY / "AndroidManifest.xml").read_text()
    (MAIN / "AndroidManifest.xml").write_text(manifest)
    print("wrote:", (MAIN / "AndroidManifest.xml").relative_to(ROOT))

    for name in OUR_FILES:
        assert (target / name).exists(), name
    print(f"OK - namespace {ns}; manifest classes .MainActivity/.CoreService resolve to {ns}.*")


if __name__ == "__main__":
    main()
