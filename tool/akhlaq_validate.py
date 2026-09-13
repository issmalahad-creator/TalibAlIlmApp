#!/usr/bin/env python3
"""Source-grounded automated validation for an AKHLAQ content slice.

Usage:  py -X utf8 tool/akhlaq_validate.py docs/akhlaq/alrifq/ar-rifq.json

Enforces (Ismail's list, AKHLAQ_EVIDENCE_MODEL §4-bis):
 1. no text without a source (or an explicit TARBAWI tag for pedagogical text)
 2. no translation without an original Arabic
 3. no attribution to a scholar without a source
 4. no pedagogical_interpretation attributed to a scholar
 5. every behavior has evidence OR [TARBAWI]
 6. every scenario is linked to a subskill AND has a difficulty
 7. no placeholder / fabricated text
 8. hadith_marfu @ source_confirmed has grader + grading + takhrij
 9. QURAN_MEANING translator is a licensed edition, never an automated one
Exit code 0 = all pass, 1 = any failure.
"""
import json, re, sys

PLACEHOLDERS = re.compile(r'lorem ipsum|todo|tbd|xxx|placeholder|\bfixme\b|\?\?\?', re.I)
SCHOLAR_HINT = re.compile(r'قال (الشيخ|العلامة|ابن|الإمام)|according to (shaykh|the imam)', re.I)
AUTOMATED = re.compile(r'claude|gpt|machine|آليّ|آلي|auto[- ]?translat', re.I)

def load(path):
    return json.load(open(path, encoding='utf-8'))

def check(doc):
    fails = []
    ev_by_id = {e['id']: e for e in doc['evidence']}

    # 1 + 3 : evidence text must have a real source; scholar/quran types need book+author
    for e in doc['evidence']:
        if not (e.get('text_ar') or '').strip():
            fails.append(f"[1] evidence {e['id']} has empty text_ar")
        if not (e.get('book') or '').strip() or not (e.get('edition') or '').strip():
            fails.append(f"[1/3] evidence {e['id']} missing book/edition")
        if e['source_type'] in ('qawl_alim', 'qawl_tabii', 'athar_sahabi') and not (e.get('author') or '').strip():
            fails.append(f"[3] scholar/athar evidence {e['id']} has no author/source")
        if e['source_status'] not in doc['policy']['source_status_values']:
            fails.append(f"[8] evidence {e['id']} bad source_status '{e['source_status']}'")
        # 8 : confirmed marfu' needs grader+grading+takhrij
        if e['source_type'] == 'hadith_marfu' and e['source_status'] == 'source_confirmed':
            for k in ('grader', 'grading', 'takhrij'):
                if not (e.get(k) or '').strip():
                    fails.append(f"[8] confirmed hadith {e['id']} missing {k}")

    # 4 : principle interpretation must be tarbawi, never a scholar
    for p in doc['principles']:
        if p.get('interpretation_by') != 'منهج التطبيق التربوي':
            fails.append(f"[4] principle {p['id']} interpretation_by != tarbawi")
        if SCHOLAR_HINT.search(p.get('statement_ar', '')):
            fails.append(f"[4] principle {p['id']} statement attributes to a scholar")
        for evid in p.get('evidence', []):
            if evid not in ev_by_id:
                fails.append(f"[1] principle {p['id']} cites unknown evidence {evid}")

    # 5 : every behavior -> evidence OR TARBAWI
    for b in doc['behaviors']:
        basis = b.get('basis', '')
        if basis == 'TARBAWI':
            continue
        if basis not in ev_by_id:
            fails.append(f"[5] behavior {b['id']} basis '{basis}' is neither evidence nor TARBAWI")

    # 6 : every scenario -> subskill + difficulty ; options sane
    sub_slugs = {s['slug'] for s in doc['subskills']}
    for sc in doc['scenarios']:
        if not sc.get('subskills'):
            fails.append(f"[6] scenario {sc['id']} has no subskill")
        for ss in sc.get('subskills', []):
            if ss not in sub_slugs:
                fails.append(f"[6] scenario {sc['id']} unknown subskill '{ss}'")
        d = sc.get('difficulty')
        if not isinstance(d, int) or not (1 <= d <= 8):
            fails.append(f"[6] scenario {sc['id']} bad difficulty {d!r}")
        verdicts = {o['verdict'] for o in sc.get('options', [])}
        if not sc.get('options'):
            fails.append(f"[6] scenario {sc['id']} has no options")
        if 'aqrab' not in verdicts:
            fails.append(f"[6] scenario {sc['id']} has no 'aqrab' option")
        for o in sc.get('options', []):
            for evid in o.get('evidence', []):
                if evid not in ev_by_id:
                    fails.append(f"[1] scenario {sc['id']} option {o['ord']} cites unknown evidence {evid}")

    # 2 + 7 + 9 : translations
    id_index = {
        'evidence': {e['id'] for e in doc['evidence']},
        'principle': {p['id'] for p in doc['principles']},
        'subskill': {s['slug'] for s in doc['subskills']},
        'scenario': {s['id'] for s in doc['scenarios']},
        'scenario_option': {f"{s['id']}:{o['ord']}" for s in doc['scenarios'] for o in s.get('options', [])},
        'stage': {str(c['stage']) for c in doc['curriculum']},
        'virtue': {doc['virtue']['slug']},
        'term_gloss': None,
    }
    for t in doc['translations']:
        rk, rid = t['ref_kind'], t['ref_id']
        if rk not in id_index:
            fails.append(f"[2] translation ref_kind '{rk}' unknown")
        elif id_index[rk] is not None and rid not in id_index[rk]:
            fails.append(f"[2] translation points at missing {rk} '{rid}'")
        # a *populated* translation must have an original (evidence text / principle / ...)
        if t.get('text', '').strip() and t['translation_status'] != 'pending':
            if rk == 'evidence' and not (ev_by_id.get(rid, {}).get('text_ar') or '').strip():
                fails.append(f"[2] translation for evidence {rid} has no Arabic original")
        if t['translation_status'] not in ('generated', 'machine_assisted', 'human_reviewed', 'approved', 'pending'):
            fails.append(f"[2] translation {rk}/{rid}/{t['lang']} bad status '{t['translation_status']}'")
        if t['translation_type'] == 'quran_meaning' and AUTOMATED.search(t.get('translator', '')):
            fails.append(f"[9] QURAN_MEANING {rk}/{rid} translator looks automated: {t['translator']!r}")

    # 7 : placeholders / fabricated markers anywhere
    def scan(obj, path=''):
        if isinstance(obj, str):
            if PLACEHOLDERS.search(obj):
                fails.append(f"[7] placeholder-looking text at {path}: {obj[:60]!r}")
        elif isinstance(obj, dict):
            for k, v in obj.items():
                scan(v, f"{path}.{k}")
        elif isinstance(obj, list):
            for i, v in enumerate(obj):
                scan(v, f"{path}[{i}]")
    scan(doc)

    return fails

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else 'docs/akhlaq/alrifq/ar-rifq.json'
    doc = load(path)
    fails = check(doc)
    print(f"AKHLAQ validation — {path}")
    print(f"  evidence={len(doc['evidence'])} principles={len(doc['principles'])} "
          f"subskills={len(doc['subskills'])} behaviors={len(doc['behaviors'])} "
          f"scenarios={len(doc['scenarios'])} stages={len(doc['curriculum'])} "
          f"translations={len(doc['translations'])}")
    tarbawi = sum(1 for b in doc['behaviors'] if b['basis'] == 'TARBAWI')
    print(f"  behaviors: {len(doc['behaviors'])-tarbawi} evidence-backed, {tarbawi} [TARBAWI]")
    diff = {}
    for s in doc['scenarios']:
        diff[s['difficulty']] = diff.get(s['difficulty'], 0) + 1
    print(f"  scenario difficulty: " + " · ".join(f"{k}:{diff[k]}" for k in sorted(diff)))
    if fails:
        print(f"\n  FAIL — {len(fails)} issue(s):")
        for f in fails:
            print(f"   - {f}")
        sys.exit(1)
    print("\n  PASS — all checks clean.")
    sys.exit(0)

if __name__ == '__main__':
    main()
