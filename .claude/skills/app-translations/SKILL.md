---
name: app-translations
description: >-
  Load before adding or editing any user-facing string in TalibAlIlmApp —
  new UI text, a new screen, a button label, a snackbar. The app has a
  hand-rolled i18n map (`lib/l10n/basic_translations.dart` + `basicText()`),
  13 languages, RTL. Ismail's standing rule: every new feature is
  translation-ready from the start, never hardcoded Arabic retrofitted
  later. This skill has the pattern, the 13 language codes, and the safe way
  to bulk-add keys.
---

# App translations (`basic_translations.dart` + `basicText()`)

## The mechanism

- One big `const Map<String, Map<String, String>>` in
  `lib/l10n/basic_translations.dart`. `basicText('key', lang)` returns
  `entry[lang] ?? entry['ar'] ?? key` — **Arabic is the fallback**, so a
  key with only `ar`+`en` still works everywhere (degrades to Arabic).
- Language selection: `LanguagePreferenceService.currentLanguage` /
  `.languageNotifier` (wrap screens in `ValueListenableBuilder<String>`).
- RTL is handled per-widget with `textDirection: TextDirection.rtl` on
  Arabic content; the app is RTL-first.

## The 13 language codes (in this order)

`ar, en, am, fr, sw, ur, tr, id, bn, ha, so, fa, ms`
(Arabic, English, Amharic, French, Swahili, Urdu, Turkish, Indonesian,
Bengali, Hausa, Somali, Persian, Malay).

## Rules

1. **Never ship hardcoded Arabic in a widget and retrofit `basicText()`
   later.** Wire `basicText()` from the first line. (Standing feedback from
   Ismail — see memory `feedback_new_features_must_be_translation_ready`.)
2. A brand-new key MAY start `ar`+`en` only if it follows an existing block
   that documents an ar-fallback (e.g. the `ql_*` learning-layer block did
   this originally) — but prefer full 13 for anything a non-Arabic user
   actually sees. The Turath / mushaf / home strings are all full-13; match
   the neighbours.
3. Key naming: `feature_thing` snake_case, grouped near related keys with a
   `// ---- section` comment. Reuse an existing key before inventing one
   (`grep "': {'ar'" | grep <arabic word>`).
4. Keep each entry a **single line** where it fits (one `'lang': 'text',`
   list) — the maintenance scripts below assume single-line entries.

## Bulk-adding / upgrading many keys — the safe script

`sed`/bash here-docs choke on the Arabic + apostrophes. Write a Python file
(via the Write tool, not a bash here-doc) and run it. Pattern:

```python
import re
P = 'lib/l10n/basic_translations.dart'
L = ['ar','en','am','fr','sw','ur','tr','id','bn','ha','so','fa','ms']
T = { 'key': ['ar text','en text', ...13 items...], ... }
s = open(P, encoding='utf-8').read()
for key, vals in T.items():
    body = ', '.join("'%s': '%s'" % (k, v.replace("\\","\\\\").replace("'","\\'"))
                     for k, v in zip(L, vals))
    pat = re.compile(r"(^\s*)'" + re.escape(key) + r"': \{[^\n]*\},", re.M)
    s = pat.sub(lambda m, b=body, k=key: m.group(1) + "'" + k + "': {" + b + "},", s)
open(P, 'w', encoding='utf-8').write(s)
```

**GOTCHA (cost me a rewrite):** with a **lambda** replacement in
`re.sub`, backreferences like `\g<1>` are NOT expanded — they land as the
literal string `\g<1>` in the file. Either build the replacement inside the
lambda from `m.group(1)` (as above), or use a plain replacement string (no
lambda) with `\g<1>`. Never mix `\g<1>` into a lambda's return value.

Multi-line entries won't match `\{[^\n]*\}` — fix those by hand with Edit.

## After editing

`flutter analyze lib/l10n/basic_translations.dart` (catches an unbalanced
brace / stray token instantly). Optionally sanity-check every touched key
has 13 distinct lang codes with a small regex loop. There is no
translation-completeness test in the suite — `basicText`'s ar-fallback is
the safety net.
