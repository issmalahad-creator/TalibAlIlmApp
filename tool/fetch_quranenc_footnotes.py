# Re-fetch every bundled QuranEnc.com tafsir/translation edition, this
# time capturing the "footnotes" field the original
# tool/fetch_quranenc_translations.dart discarded (see
# docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5). Output JSONL shape:
# {"surah": int, "ayah": int, "text": str, "footnote": str} — "footnote"
# is "" when QuranEnc has none for that ayah (never fabricated).
#
# Idempotent per language: if the existing bundled asset's first line
# already has a "footnote" key, that language is skipped (already
# upgraded). Each language is only written once ALL 114 suras succeeded
# for it, so a mid-run network failure never leaves a partially-upgraded
# asset. Run: `python tool/fetch_quranenc_footnotes.py`
import gzip
import json
import os
import time
import urllib.error
import urllib.request

OUT_DIR = "assets/quran"
SURA_COUNT = 114

# Same edition list as tool/fetch_quranenc_translations.dart (the file
# that first bundled these), so nothing here is invented.
EDITIONS = [
    ("english_rwwad", "tafsir-english_rwwad.jsonl.gz"),
    ("amharic_sadiq", "tafsir-amharic_sadiq.jsonl.gz"),
    ("french_rashid", "tafsir-french_rashid.jsonl.gz"),
    ("turkish_rwwad", "tafsir-turkish_rwwad.jsonl.gz"),
    ("indonesian_sabiq", "tafsir-indonesian_sabiq.jsonl.gz"),
    ("urdu_junagarhi", "tafsir-urdu_junagarhi.jsonl.gz"),
    ("bengali_zakaria", "tafsir-bengali_zakaria.jsonl.gz"),
    ("spanish_garcia", "tafsir-spanish_garcia.jsonl.gz"),
    ("portuguese_nasr", "tafsir-portuguese_nasr.jsonl.gz"),
    ("greek_rwwad", "tafsir-greek_rwwad.jsonl.gz"),
    ("german_rwwad", "tafsir-german_rwwad.jsonl.gz"),
    ("italian_rwwad", "tafsir-italian_rwwad.jsonl.gz"),
    ("bulgarian_translation", "tafsir-bulgarian_translation.jsonl.gz"),
    ("romanian_project", "tafsir-romanian_project.jsonl.gz"),
    ("dutch_center", "tafsir-dutch_center.jsonl.gz"),
    ("swedish_rwwad", "tafsir-swedish_rwwad.jsonl.gz"),
    ("azeri_musayev", "tafsir-azeri_musayev.jsonl.gz"),
    ("georgian_rwwad", "tafsir-georgian_rwwad.jsonl.gz"),
    ("macedonian_group", "tafsir-macedonian_group.jsonl.gz"),
    ("albanian_nahi", "tafsir-albanian_nahi.jsonl.gz"),
    ("bosnian_rwwad", "tafsir-bosnian_rwwad.jsonl.gz"),
    ("russian_rwwad", "tafsir-russian_rwwad.jsonl.gz"),
    ("belarusian_krivtsov", "tafsir-belarusian_krivtsov.jsonl.gz"),
    ("serbian_rwwad", "tafsir-serbian_rwwad.jsonl.gz"),
    ("croatian_rwwad", "tafsir-croatian_rwwad.jsonl.gz"),
    ("lithuanian_rwwad", "tafsir-lithuanian_rwwad.jsonl.gz"),
    ("ukrainian_yakubovych", "tafsir-ukrainian_yakubovych.jsonl.gz"),
    ("kazakh_altai", "tafsir-kazakh_altai.jsonl.gz"),
    ("uzbek_mansour", "tafsir-uzbek_mansour.jsonl.gz"),
    ("tajik_arifi", "tafsir-tajik_arifi.jsonl.gz"),
    ("kyrgyz_hakimov", "tafsir-kyrgyz_hakimov.jsonl.gz"),
    ("circassian_rwwad", "tafsir-circassian_rwwad.jsonl.gz"),
    ("tagalog_rwwad", "tafsir-tagalog_rwwad.jsonl.gz"),
    ("bisayan_rwwad", "tafsir-bisayan_rwwad.jsonl.gz"),
    ("iranun_sarro", "tafsir-iranun_sarro.jsonl.gz"),
    ("maguindanao_rwwad", "tafsir-maguindanao_rwwad.jsonl.gz"),
    ("malay_basumayyah", "tafsir-malay_basumayyah.jsonl.gz"),
    ("chinese_suliman", "tafsir-chinese_suliman.jsonl.gz"),
    ("uyghur_saleh", "tafsir-uyghur_saleh.jsonl.gz"),
    ("japanese_saeedsato", "tafsir-japanese_saeedsato.jsonl.gz"),
    ("somali_yacob", "tafsir-somali_yacob.jsonl.gz"),
    ("hindi_omari", "tafsir-hindi_omari.jsonl.gz"),
    ("luganda_foundation", "tafsir-luganda_foundation.jsonl.gz"),
    # New language (2026-09-12) — Ismail specifically asked about Oromo
    # (he is in Ethiopia); verified live on quranenc.com: "oromo_ababor",
    # translation by Ghali/Gali Ababor, complete (114 sūrahs), with real
    # footnotes (confirmed on 1:1 — a hadith on al-Fātiḥa's virtue, same
    # note as amharic_sadiq's). Not in the original 42-language batch.
    ("oromo_ababor", "tafsir-oromo_ababor.jsonl.gz"),
]


def fetch_json(url, tries=6, timeout=45):
    last_err = None
    for i in range(tries):
        try:
            req = urllib.request.Request(
                url, headers={"Accept": "application/json", "User-Agent": "curl/8.4.0"}
            )
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode("utf-8"))
        except Exception as e:  # noqa: BLE001 - network flakiness is expected here
            last_err = e
            time.sleep(3 + i * 2)
    raise RuntimeError(f"gave up after {tries} tries: {last_err}")


def already_upgraded(path):
    if not os.path.exists(path):
        return False
    try:
        with gzip.open(path, "rt", encoding="utf-8") as f:
            first = f.readline()
        return "footnote" in json.loads(first)
    except Exception:
        return False


def fetch_edition(key):
    lines = []
    for sura in range(1, SURA_COUNT + 1):
        url = f"https://quranenc.com/api/v1/translation/sura/{key}/{sura}"
        data = fetch_json(url)
        result = data.get("result")
        if not isinstance(result, list):
            raise RuntimeError(f"sura {sura}: unexpected shape {type(result)}")
        for item in result:
            row = {
                "surah": int(item["sura"]),
                "ayah": int(item["aya"]),
                "text": item.get("translation") or "",
                "footnote": item.get("footnotes") or "",
            }
            lines.append(json.dumps(row, ensure_ascii=False))
        print(f"  {key}: sura {sura}/{SURA_COUNT} ({len(lines)} ayat so far)", end="\r")
        time.sleep(0.12)
    print()
    return lines


def main():
    done, skipped, failed = [], [], []
    for key, filename in EDITIONS:
        path = os.path.join(OUT_DIR, filename)
        if already_upgraded(path):
            print(f"skip {key} — already has footnote field")
            skipped.append(key)
            continue
        print(f"fetching {key} ...")
        try:
            lines = fetch_edition(key)
        except Exception as e:  # noqa: BLE001
            print(f"  FAILED {key}: {e}")
            failed.append(key)
            continue
        jsonl = "\n".join(lines)
        compressed = gzip.compress(jsonl.encode("utf-8"), 9)
        with open(path, "wb") as f:
            f.write(compressed)
        print(f"  wrote {path} ({len(compressed)} bytes, {len(lines)} ayat)")
        done.append(key)

    print()
    print(f"done={len(done)} skipped(already upgraded)={len(skipped)} failed={len(failed)}")
    if failed:
        print("failed editions (rerun the script to retry just these):", failed)


if __name__ == "__main__":
    main()
