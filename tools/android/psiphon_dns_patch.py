#!/usr/bin/env python3
"""Give Psiphon DNS servers on Android. Run from the project root (the folder with pubspec.yaml).

Why: the psiphon-tunnel-core binary is a static Go build. Without a system DNS list it uses Go's own
resolver, which reads /etc/resolv.conf. Android has no such file, so Go asks 127.0.0.1:53 and the
lookup of the server list host fails with "connection refused". Psiphon accepts a fallback list in
its config (DNSResolverAlternateServers); this patch writes it to a JSON file and hands that file to
Aether through AETHER_PSIPHON_CONFIG.

Patches every CoreService.kt it finds (android_overlay/ and android/). Idempotent.
"""
import pathlib
import sys

MARK = "psiphon-dns-fix"
ROOT = pathlib.Path.cwd()

ENV_ANCHOR = 'put("AETHER_PSIPHON_MODE", cfg.shape)'
FUN_ANCHOR = "    private fun socksOpen(): Boolean = try {"

ENV_LINE = '                    put("AETHER_PSIPHON_CONFIG", writePsiphonOverride().absolutePath) // ' + MARK + "\n"

FUN = '''    /**
     * Prefer public resolvers so poisoned carrier DNS answers do not send Psiphon to bogon IPs.
     * // ''' + MARK + '''
     */
    private fun writePsiphonOverride(): File {
        val f = File(filesDir, "psiphon-override.json")
        f.writeText("{\\"DNSResolverAlternateServers\\":[\\"1.1.1.1\\",\\"8.8.8.8\\",\\"9.9.9.9\\"],\\"DNSResolverPreferredAlternateServers\\":[\\"1.1.1.1\\",\\"8.8.8.8\\",\\"9.9.9.9\\"],\\"DNSResolverPreferAlternateServerProbability\\":1.0}\\n")
        return f
    }

'''


def patch(path: pathlib.Path) -> str:
    text = path.read_text()
    if MARK in text:
        return "already patched"
    if text.count(ENV_ANCHOR) != 1:
        return f"SKIPPED: expected exactly one `{ENV_ANCHOR}` (found {text.count(ENV_ANCHOR)}); is this the Psiphon version?"
    if text.count(FUN_ANCHOR) != 1:
        return f"SKIPPED: expected exactly one `{FUN_ANCHOR.strip()}` (found {text.count(FUN_ANCHOR)})"

    # 1) env var: keep the indentation of the anchor line, add our line right after it
    lines = text.split("\n")
    out = []
    for line in lines:
        out.append(line)
        if ENV_ANCHOR in line:
            out.append(ENV_LINE.rstrip("\n"))
    text = "\n".join(out)

    # 2) helper function before socksOpen()
    text = text.replace(FUN_ANCHOR, FUN + FUN_ANCHOR, 1)

    path.write_text(text)
    return "patched"


def main() -> None:
    found = [
        p
        for base in ("android_overlay", "android")
        for p in (ROOT / base).rglob("CoreService.kt")
        if (ROOT / base).exists()
    ]
    if not found:
        sys.exit("no CoreService.kt found; run this from the project root")
    failed = False
    for p in found:
        result = patch(p)
        print(f"{p.relative_to(ROOT)}: {result}")
        failed |= result.startswith("SKIPPED")
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
