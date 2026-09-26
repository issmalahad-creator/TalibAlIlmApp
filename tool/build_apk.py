"""The one release/debug APK builder for TalibAlIlmApp (SIZE-1).

    python tool/build_apk.py --flavor lite                 # release, split per ABI
    python tool/build_apk.py --flavor full --mode debug --no-split
    python tool/build_apk.py --flavor lite --abi arm64-v8a # only the phone ABI

Why this exists (docs/APP_PERFORMANCE_AND_SIZE_ROADMAP.md §8.5):
- A universal APK carries native libs for 3 ABIs (~200 MB of the old
  459 MB lite). Distribution size is only meaningful per ABI.
- The lite flavor must physically strip corpus text from `assets/` before
  the Gradle build (flavors don't control the Flutter asset bundle). This
  does it in Python with try/finally, and first recovers a backup left
  behind by a killed earlier run — no CRLF/trap fragility on Windows.
- Every build writes a size report next to the APK, so the size cost of any
  new feature is a measured number, not a guess. Size work must never block
  features; it has to make their cost visible.

Outputs in dist/: talib-<flavor>-<mode>-<abi>.apk, a .sha256 per APK, and
talib-<flavor>-<mode>-size.md (per-ABI breakdown). Public builds only — a
build containing an Anthropic key is deleted and the script fails.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import zipfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build" / "app" / "outputs" / "flutter-apk"
DIST = ROOT / "dist"
BACKUP = ROOT / ".lite_build_backup"
ABIS = ("arm64-v8a", "armeabi-v7a", "x86_64")
_ABI_TARGET = {
    "arm64-v8a": "android-arm64",
    "armeabi-v7a": "android-arm",
    "x86_64": "android-x64",
}
_KEY_NEEDLE = b"sk-ant-api03"

# Same list as tool/build_lite_apk.sh — lite downloads these on demand via
# QuranCorpusDownloadService. assets/tts stays bundled in both flavors
# (Ismail 2026-09-19) until the §8.5 S7 decision says otherwise.
LITE_STRIP = (
    Path("assets/quran/corpus/translations"),
    Path("assets/quran/corpus/tafsir"),
)

MB = 1024 * 1024


def find_flutter() -> str:
    for candidate in (
        os.environ.get("FLUTTER_BIN"),
        shutil.which("flutter"),
        "C:/src/flutter/bin/flutter.bat",
    ):
        if candidate and Path(candidate).exists():
            return candidate
    raise FileNotFoundError("Flutter not found — add it to PATH or set FLUTTER_BIN.")


def restore_lite_backup() -> None:
    """Moves stripped corpus dirs back. Safe to call any number of times."""
    for rel in LITE_STRIP:
        saved = BACKUP / rel.name
        target = ROOT / rel
        if saved.is_dir() and not target.exists():
            shutil.move(str(saved), str(target))
    if BACKUP.is_dir() and not any(BACKUP.iterdir()):
        BACKUP.rmdir()


def strip_for_lite() -> None:
    BACKUP.mkdir(exist_ok=True)
    for rel in LITE_STRIP:
        src = ROOT / rel
        if src.is_dir():
            shutil.move(str(src), str(BACKUP / rel.name))


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(MB), b""):
            h.update(chunk)
    return h.hexdigest()


def contains_key(apk: Path) -> bool:
    with zipfile.ZipFile(apk) as z:
        for name in z.namelist():
            if name.endswith(".dex") or name.endswith("kernel_blob.bin") or name.endswith("libapp.so"):
                if _KEY_NEEDLE in z.read(name):
                    return True
    return False


def breakdown(apk: Path) -> Counter:
    """Compressed bytes per bucket: lib/<abi>, assets/<top>[/<sub>], other."""
    buckets: Counter = Counter()
    with zipfile.ZipFile(apk) as z:
        for info in z.infolist():
            parts = info.filename.split("/")
            if parts[0] == "lib" and len(parts) > 2:
                key = f"native {parts[1]}"
            elif parts[:2] == ["assets", "flutter_assets"] and len(parts) > 4 and parts[2] == "assets":
                key = "/".join(parts[3:5]) if parts[3] in ("quran", "mushaf") and len(parts) > 5 else parts[3]
                key = f"assets/{key}"
            else:
                key = "code + resources"
            buckets[key] += info.compress_size
    return buckets


def lite_leaks(apk: Path) -> list[str]:
    prefixes = tuple(f"assets/flutter_assets/{rel.as_posix()}/" for rel in LITE_STRIP)
    with zipfile.ZipFile(apk) as z:
        return [n for n in z.namelist() if n.startswith(prefixes)][:3]


def produced_apks(flavor: str, mode: str, split: bool) -> dict[str, Path]:
    if not split:
        return {"universal": OUT / f"app-{flavor}-{mode}.apk"}
    return {abi: OUT / f"app-{abi}-{flavor}-{mode}.apk" for abi in ABIS}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--flavor", choices=("full", "lite"), required=True)
    ap.add_argument("--mode", choices=("release", "debug"), default="release")
    ap.add_argument("--no-split", action="store_true", help="one universal APK")
    ap.add_argument("--abi", choices=ABIS, help="build only this ABI (faster)")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    split = not args.no_split
    cmd = [find_flutter(), "build", "apk", f"--{args.mode}", "--flavor", args.flavor]
    if args.abi:
        cmd += ["--target-platform", _ABI_TARGET[args.abi]]
    if split:
        cmd.append("--split-per-abi")
    print("+", " ".join(cmd))
    if args.dry_run:
        return 0

    os.environ.setdefault("ANDROID_HOME", r"C:\Users\ismail\AppData\Local\Android\Sdk")
    os.environ.setdefault("ANDROID_SDK_ROOT", os.environ["ANDROID_HOME"])

    restore_lite_backup()  # a previous run may have been killed mid-build
    expected = produced_apks(args.flavor, args.mode, split)
    if args.abi:
        expected = {k: v for k, v in expected.items() if k in (args.abi, "universal")}
    for path in expected.values():
        path.unlink(missing_ok=True)  # never report a stale APK as this build
    try:
        if args.flavor == "lite":
            strip_for_lite()
        subprocess.run(cmd, cwd=ROOT, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Build failed: {e}", file=sys.stderr)
        return 1
    finally:
        restore_lite_backup()
        missing = [rel for rel in LITE_STRIP if not (ROOT / rel).is_dir()]
        if missing:
            print(f"WARNING: not restored: {missing} — check {BACKUP}", file=sys.stderr)

    DIST.mkdir(exist_ok=True)
    report = [f"# APK size — {args.flavor} {args.mode}", "", "Compressed size inside the APK.", ""]
    for abi, src in expected.items():
        if not src.exists():
            print(f"Missing expected output: {src}", file=sys.stderr)
            return 1
        dst = DIST / f"talib-{args.flavor}-{args.mode}-{abi}.apk"
        shutil.copy2(src, dst)
        if contains_key(dst):
            dst.unlink()
            print(f"FATAL: {dst.name} contained an API key — deleted.", file=sys.stderr)
            return 1
        if args.flavor == "lite" and (leaks := lite_leaks(dst)):
            print(f"FATAL: lite APK still contains stripped corpus: {leaks}", file=sys.stderr)
            return 1
        digest = sha256(dst)
        (DIST / f"{dst.name}.sha256").write_text(f"{digest}  {dst.name}\n", encoding="utf-8")
        size = dst.stat().st_size / MB
        print(f"{dst}  {size:.1f} MB  sha256 {digest[:16]}…")
        report += [f"## {abi} — {size:.1f} MB", "", f"`{dst.name}` · sha256 `{digest}`", "",
                   "| bucket | MB |", "|---|---:|"]
        for key, n in breakdown(dst).most_common():
            if n >= MB // 10:
                report.append(f"| {key} | {n / MB:.1f} |")
        report.append("")
    (DIST / f"talib-{args.flavor}-{args.mode}-size.md").write_text("\n".join(report), encoding="utf-8")
    print(f"Size report: {DIST / f'talib-{args.flavor}-{args.mode}-size.md'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
