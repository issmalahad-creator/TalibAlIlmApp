"""Shared helper: add 13-language keys + replace literals in one Dart file."""
P = 'lib/l10n/basic_translations.dart'
L = ['ar','en','am','fr','sw','ur','tr','id','bn','ha','so','fa','ms']


def add_keys(T, section):
    s = open(P, encoding='utf-8').read()
    anchor = "  'mushaf_go_to_page': {"
    lines = [f"  // ---- {section} (13-language retrofit, 2026-10-10 audit)"]
    for k, v in T.items():
        assert len(v) == 13, (k, len(v))
        assert f"  '{k}':" not in s, k
        lines.append(f"  '{k}': {{" + ', '.join(
            "'%s': '%s'" % (x, y.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")) for x, y in zip(L, v)) + "},")
    s = s.replace(anchor, "\n".join(lines) + "\n" + anchor, 1)
    open(P, 'w', encoding='utf-8').write(s)


HELPER = "\n/// This screen's strings — `basicText` in the current app language.\nString _t(String key) => basicText(key, LanguagePreferenceService.currentLanguage);\n"


def patch(path, R, helper=True):
    s = open(path, encoding='utf-8').read()
    for a, b in R:
        n = s.count(a)
        assert n >= 1, (path, a[:80])
        s = s.replace(a, b)
    if "l10n/basic_translations.dart'" not in s:
        s = s.replace("import 'package:flutter/material.dart';\n",
                      "import 'package:flutter/material.dart';\n\nimport '../l10n/basic_translations.dart';\n", 1)
    if "services/language_preference_service.dart'" not in s:
        s = s.replace("import '../l10n/basic_translations.dart';\n",
                      "import '../l10n/basic_translations.dart';\nimport '../services/language_preference_service.dart';\n", 1)
    if helper and 'String _t(String key)' not in s:
        # after the last import line
        lines = s.split('\n')
        last = max(i for i, l in enumerate(lines) if l.startswith('import '))
        lines.insert(last + 1, HELPER)
        s = '\n'.join(lines)
    open(path, 'w', encoding='utf-8').write(s)
