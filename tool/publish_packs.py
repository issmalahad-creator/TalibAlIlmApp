#!/usr/bin/env python3
"""Build and publish content packs to the `packs-v1` GitHub Release.

docs/architecture/CONTENT_PACKS_ARCHITECTURE.md §3.6 (CP2).

    python tool/publish_packs.py            # build manifest + snapshot only (no network)
    python tool/publish_packs.py --publish  # also upload new files + manifest via `gh`

Rules:
- A published file never changes. When a pack's bytes change, its version is
  bumped and it gets a new file name (`<id>.v<N>.<ext>`), so an installed
  copy can show «تحديث متاح» and a half-updated CDN can't mix versions.
- Every file carries its size and SHA-256; the app refuses anything else.
- Only data that is already public in this repo is packed (the repo is
  public); book PDFs / scans never are.
- The manifest snapshot is copied to assets/packs/ so sizes show offline.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TAG = "packs-v1"
REPO = "issmalahad-creator/TalibAlIlmApp"
BASE = f"https://github.com/{REPO}/releases/download/{TAG}/"
SNAPSHOT = ROOT / "assets/packs/packs_manifest.json"

# Heavy corpus datasets — seeded into DB tables by the `corpus_table` installer (CP4).
CORPUS = {
    "sayings": ({"ar": "أقوال السلف في الآيات", "en": "Sayings of the Salaf"},
                {"ar": "أقوال الصحابة والتابعين والأئمة على كل آية", "en": "Companions’ and early scholars’ sayings per verse"}),
    "notes": ({"ar": "فوائد وتدبرات", "en": "Reflections and benefits"},
              {"ar": "فوائد مستنبطة من الآيات", "en": "Benefits drawn from the verses"}),
    "similar": ({"ar": "المتشابهات اللفظية", "en": "Similar verses"},
                {"ar": "الآيات المتشابهة في اللفظ للحفظ والمراجعة", "en": "Verbally similar verses, for memorisation"}),
    "irab_books": ({"ar": "كتب إعراب القرآن", "en": "Quran grammar (iʿrāb) books"},
                   {"ar": "إعراب الآيات من كتب الإعراب", "en": "Grammatical analysis of each verse"}),
    "fatwas": ({"ar": "فتاوى متعلقة بالآيات", "en": "Verse-related fatwas"},
               {"ar": "فتاوى العلماء المرتبطة بالآيات", "en": "Scholars’ fatwas linked to verses"}),
}

# Tafsir editions that stay bundled in every build (the essentials).
CORE_TAFSIR = {"muyassar", "saadi", "almukhtasar"}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def tafsir_editions() -> list[tuple[str, str, str]]:
    """(asset path, source key, lang) — read from the app's own list."""
    src = (ROOT / "lib/services/quran_import_service.dart").read_text(encoding="utf-8")
    block = src[src.index("static const _tafsirEditions = ["):]
    block = block[: block.index("];")]
    return re.findall(r"\('(assets/quran/tafsir(?:-|_packs/tafsir-)[^']+)', '([^']+)', '([^']+)'\)", block)


def tafsir_titles() -> dict[str, str]:
    src = (ROOT / "lib/repositories/quran_search_repository.dart").read_text(encoding="utf-8")
    return {k: t for k, t, _ in re.findall(r"\('([a-z_]+)', '([^']+)', '([a-z]+)'\)", src)}


def candidates() -> list[dict]:
    """Every pack: id, kind, source file, titles, installer."""
    out = []
    for name, (title, summary) in CORPUS.items():
        out.append({"id": f"corpus.{name}", "kind": "corpus", "src": ROOT / f"assets/quran/corpus/packs/{name}.json.gz",
                    "ext": "json.gz", "title": title, "summary": summary, "installer": "corpus_table"})
    titles = tafsir_titles()
    for path, key, lang in tafsir_editions():
        if key in CORE_TAFSIR:
            continue
        label = titles.get(key, key)
        out.append({"id": f"tafsir.{key}", "kind": "tafsir" if lang == "ar" else "translation",
                    "src": ROOT / path, "ext": "jsonl.gz", "title": {"ar": label, "en": label},
                    "summary": {}, "installer": "legacy_tafsir", "lang": lang})
    return out


def published_manifest() -> dict | None:
    with tempfile.TemporaryDirectory() as d:
        r = subprocess.run(["gh", "release", "download", TAG, "--repo", REPO, "-p", "packs_manifest.json", "-D", d],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return None
        return json.loads((Path(d) / "packs_manifest.json").read_text(encoding="utf-8"))


def build(previous: dict | None) -> tuple[dict, list[tuple[Path, str]]]:
    prev = {p["id"]: p for p in (previous or {}).get("packs", [])}
    packs, uploads = [], []
    for c in candidates():
        src: Path = c["src"]
        if not src.exists():
            print(f"skip {c['id']}: {src} missing (stripped by a lite build? run restore_lite_backup)", file=sys.stderr)
            continue
        digest, size = sha256(src), src.stat().st_size
        old = prev.get(c["id"])
        same = old and old["files"][0]["sha256"] == digest
        version = old["version"] if same else (old["version"] + 1 if old else 1)
        name = f"{c['id']}.v{version}.{c['ext']}"
        pack = {"id": c["id"], "kind": c["kind"], "version": version, "title": c["title"],
                "files": [{"name": name, "bytes": size, "sha256": digest}], "installer": c["installer"]}
        if c["summary"]:
            pack["summary"] = c["summary"]
        if "lang" in c:
            pack["lang"] = c["lang"]
        packs.append(pack)
        if not same:
            uploads.append((src, name))
    manifest = {"schema": 1, "generated": date.today().isoformat(), "base": BASE, "packs": packs}
    return manifest, uploads


def gh(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["gh", *args, "--repo", REPO], capture_output=True, text=True)


def publish(manifest: dict, uploads: list[tuple[Path, str]]) -> None:
    if gh("release", "view", TAG).returncode != 0:
        r = gh("release", "create", TAG, "--title", "Content packs v1",
               "--notes", "Downloadable content packs for Talib al-Ilm (see docs/architecture/CONTENT_PACKS_ARCHITECTURE.md). "
                          "Files never change; packs_manifest.json lists sizes and SHA-256.",
               "--latest=false")
        if r.returncode != 0:
            sys.exit(f"cannot create release: {r.stderr}")
    listing = json.loads(gh("release", "view", TAG, "--json", "assets").stdout or '{"assets": []}')
    existing = {a["name"] for a in listing.get("assets", [])}
    with tempfile.TemporaryDirectory() as d:
        for src, name in uploads:
            if name in existing:
                continue
            staged = Path(d) / name
            shutil.copyfile(src, staged)
            r = gh("release", "upload", TAG, str(staged))
            if r.returncode != 0:
                sys.exit(f"upload failed for {name}: {r.stderr}")
            print(f"uploaded {name} ({src.stat().st_size / 1e6:.1f} MB)")
        mf = Path(d) / "packs_manifest.json"
        mf.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
        r = gh("release", "upload", TAG, str(mf), "--clobber")
        if r.returncode != 0:
            sys.exit(f"manifest upload failed: {r.stderr}")
    print("manifest published")


def verify(manifest: dict) -> None:
    """Re-download every file's first bytes? No — sizes via the API are enough
    to catch a truncated upload; SHA is re-checked by the app on download."""
    assets = {a["name"]: a["size"] for a in json.loads(gh("release", "view", TAG, "--json", "assets").stdout)["assets"]}
    bad = [f["name"] for p in manifest["packs"] for f in p["files"] if assets.get(f["name"]) != f["bytes"]]
    if bad:
        sys.exit(f"size mismatch on the release: {bad}")
    print(f"verified {sum(len(p['files']) for p in manifest['packs'])} files on {TAG}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--publish", action="store_true")
    args = ap.parse_args()
    # Versions are decided against what is really on GitHub, never against the
    # local snapshot (which a partial run could have left stale).
    previous = published_manifest()
    if previous is None and SNAPSHOT.exists() and not args.publish:
        previous = json.loads(SNAPSHOT.read_text(encoding="utf-8"))
    manifest, uploads = build(previous)
    total = sum(f["bytes"] for p in manifest["packs"] for f in p["files"])
    print(f"{len(manifest['packs'])} packs, {total / 1e6:.1f} MB; {len(uploads)} new/changed file(s)")
    if args.publish:
        publish(manifest, uploads)
        verify(manifest)
    SNAPSHOT.parent.mkdir(parents=True, exist_ok=True)
    SNAPSHOT.write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"snapshot -> {SNAPSHOT.relative_to(ROOT)} ({SNAPSHOT.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
