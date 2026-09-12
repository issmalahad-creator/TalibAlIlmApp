# Periodic health check for every bundled QuranEnc.com tafsir/translation
# edition key (see docs/quran/TAFSIR_UNIFIED_ARCHITECTURE.md §5 item 8).
# quranenc.com sometimes deprecates a translation key from its public
# catalog while the old data endpoint keeps serving it (as happened with
# 'somali_abduh', 'albanian_rwwad', 'uzbek_rwwad' — all found footnote-less
# and swapped for a real current edition). This script re-runs that same
# check for every key currently in
# lib/repositories/quran_search_repository.dart's `tafsirSources` (kept
# duplicated here on purpose, same as the fetch tools — copy the current
# list from there before running if it has changed).
#
# For each key: (a) is it still listed in the live GET /api/v1/translations
# catalog? (b) does a 3-sūrah sample (1, 18, 112) carry any real footnotes?
# Run: `python tool/audit_quranenc_editions.py`. A key that is BOTH missing
# from the catalog AND footnote-less is worth searching the live catalog
# for a same-language replacement (see the two-step process that found
# 'albanian_nahi' and 'uzbek_mansour'). A key with footnotes but missing
# from the catalog is fine as-is — the data endpoint still serves it.
import json
import ssl
import sys
import time
import urllib.request

ctx = ssl.create_default_context()

# (source key, language code) — mirror of quran_search_repository.dart's
# tafsirSources, non-Arabic rows only.
KEYS = [
    ('english_rwwad', 'en'), ('amharic_sadiq', 'am'), ('french_rashid', 'fr'),
    ('turkish_rwwad', 'tr'), ('indonesian_sabiq', 'id'), ('urdu_junagarhi', 'ur'),
    ('bengali_zakaria', 'bn'), ('spanish_garcia', 'es'), ('portuguese_nasr', 'pt'),
    ('greek_rwwad', 'el'), ('german_rwwad', 'de'), ('italian_rwwad', 'it'),
    ('bulgarian_translation', 'bg'), ('romanian_project', 'ro'), ('dutch_center', 'nl'),
    ('swedish_rwwad', 'sv'), ('azeri_musayev', 'az'), ('georgian_rwwad', 'ka'),
    ('macedonian_group', 'mk'), ('albanian_nahi', 'sq'), ('bosnian_rwwad', 'bs'),
    ('russian_rwwad', 'ru'), ('belarusian_krivtsov', 'be'), ('serbian_rwwad', 'sr'),
    ('croatian_rwwad', 'hr'), ('lithuanian_rwwad', 'lt'), ('ukrainian_yakubovych', 'uk'),
    ('kazakh_altai', 'kk'), ('uzbek_mansour', 'uz'), ('tajik_arifi', 'tg'),
    ('kyrgyz_hakimov', 'ky'), ('circassian_rwwad', 'ady'), ('tagalog_rwwad', 'tl'),
    ('bisayan_rwwad', 'ceb'), ('iranun_sarro', 'iru'), ('maguindanao_rwwad', 'mdh'),
    ('malay_basumayyah', 'ms'), ('chinese_suliman', 'zh'), ('uyghur_saleh', 'ug'),
    ('japanese_saeedsato', 'ja'), ('hindi_omari', 'hi'), ('luganda_foundation', 'lg'),
    ('oromo_ababor', 'om'), ('somali_yacob', 'so'),
]


def fetch_json(url, tries=5, timeout=25):
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=timeout, context=ctx) as r:
                return json.load(r)
        except Exception as e:
            last = e
            time.sleep(1 + i)
    raise last


def main():
    catalog = fetch_json('https://quranenc.com/api/v1/translations')
    catalog_keys = {t['key'] for t in catalog.get('translations', catalog)}
    print(f"Live catalog has {len(catalog_keys)} editions.\n")

    results = []
    for key, lang in KEYS:
        in_catalog = key in catalog_keys
        footnote_count = 0
        try:
            for sura in (1, 18, 112):
                data = fetch_json(
                    f'https://quranenc.com/api/v1/translation/sura/{key}/{sura}')
                rows = data.get('result', [])
                footnote_count += sum(1 for r in rows if r.get('footnotes'))
        except Exception:
            footnote_count = -1
        status = "OK" if in_catalog else "MISSING-FROM-CATALOG"
        foot_status = (
            "HAS_FOOTNOTES" if footnote_count > 0
            else "NO_FOOTNOTES" if footnote_count == 0
            else "FETCH_FAILED")
        results.append((key, lang, status, foot_status, footnote_count))
        print(f"{key:28s} {lang:5s} catalog={status:22s} "
              f"sample_footnotes={foot_status:14s} count={footnote_count}")
        sys.stdout.flush()

    print("\n--- Summary ---")
    both_bad = [r for r in results if r[2] != "OK" and r[3] == "NO_FOOTNOTES"]
    print(f"Missing from catalog AND footnote-less (investigate a swap): "
          f"{len(both_bad)} -> {[r[0] for r in both_bad]}")


if __name__ == "__main__":
    main()
