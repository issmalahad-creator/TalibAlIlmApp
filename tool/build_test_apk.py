"""Build a phone-test APK for TalibAlIlmApp on Windows or any Flutter host."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-full-debug.apk"
DIST = ROOT / "dist" / "TalibAlIlm-full-debug.apk"


def find_flutter() -> str:
    configured = os.environ.get("FLUTTER_BIN")
    if configured:
        return configured

    flutter = shutil.which("flutter")
    if flutter:
        return flutter

    common_paths = (
        Path("C:/src/flutter/bin/flutter.bat"),
        Path("C:/flutter/bin/flutter.bat"),
    )
    for path in common_paths:
        if path.exists():
            return str(path)

    raise FileNotFoundError(
        "Flutter was not found. Add Flutter to PATH or set FLUTTER_BIN to flutter.bat."
    )


def run(command: list[str], *, dry_run: bool = False) -> None:
    print("+", " ".join(command))
    if not dry_run:
        subprocess.run(command, cwd=ROOT, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build a full debug APK ready to install on a phone."
    )
    parser.add_argument(
        "--skip-pub-get",
        action="store_true",
        help="Skip flutter pub get when dependencies are already installed.",
    )
    parser.add_argument(
        "--skip-analyze",
        action="store_true",
        help="Skip flutter analyze before building.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the commands without running them.",
    )
    args = parser.parse_args()

    try:
        flutter = find_flutter()
        if not args.skip_pub_get:
            run([flutter, "pub", "get"], dry_run=args.dry_run)
        if not args.skip_analyze:
            run([flutter, "analyze", "--no-fatal-infos"], dry_run=args.dry_run)
        run(
            [flutter, "build", "apk", "--debug", "--flavor", "full"],
            dry_run=args.dry_run,
        )

        if args.dry_run:
            print(f"Would copy: {OUTPUT}")
            print(f"Would create: {DIST}")
            return 0

        if not OUTPUT.exists():
            raise FileNotFoundError(f"Flutter finished but APK was not found: {OUTPUT}")

        DIST.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OUTPUT, DIST)
        print()
        print("APK ready:")
        print(DIST)
        print(f"Size: {DIST.stat().st_size / (1024 * 1024):.1f} MB")
        print("Install it on the phone, then test the requested feature.")
        return 0
    except (FileNotFoundError, subprocess.CalledProcessError) as error:
        print(f"Build failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())