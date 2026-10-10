"""Heuristic Flutter bug-pattern audit over lib/.

1. setState after an await (same function, before any mounted check)
2. Controllers/notifiers/timers held in a State field but never disposed/cancelled
"""
import re, sys, pathlib

root = pathlib.Path(sys.argv[1])
findings = {'setstate_after_await': [], 'undisposed': []}

func_re = re.compile(r'(?:Future<[^>]*>|void|FutureOr<[^>]*>)\s+(\w+)\s*\([^)]*\)\s*async\s*\{')

def body_from(src, start):
    depth = 0
    for i in range(start, len(src)):
        c = src[i]
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                return src[start:i + 1]
    return src[start:]

for f in sorted(root.rglob('*.dart')):
    src = f.read_text(encoding='utf-8')
    if 'extends State<' not in src:
        continue
    # 1
    for m in func_re.finditer(src):
        body = body_from(src, m.end() - 1)
        lines = body.split('\n')
        seen_await = False
        guarded = False
        for k, ln in enumerate(lines):
            s = ln.strip()
            if s.startswith('//'):
                continue
            if 'mounted' in s:
                guarded = True
            if re.search(r'\bawait\b', s):
                seen_await = True
                guarded = 'mounted' in s
                continue
            if seen_await and not guarded and re.search(r'\bsetState\s*\(', s):
                line_no = src[:m.start()].count('\n') + k + 1
                findings['setstate_after_await'].append(f'{f}:{line_no}: {m.group(1)}()')
                break
    # 2 — per State class
    for cm in re.finditer(r'class (\w+) extends State<[^>]+>[^{]*\{', src):
        body = body_from(src, cm.end() - 1)
        fields = re.findall(
            r'^\s*(?:final|late final|late)?\s*(TextEditingController|AnimationController|ScrollController|PageController|TabController|FocusNode|StreamSubscription<[^>]*>\??|Timer\??|ValueNotifier<[^>]*>)\s+(_\w+)',
            body, re.M)
        for typ, name in fields:
            disposed = re.search(re.escape(name) + r'\??\.(dispose|cancel|close)\(', body)
            # also: list-loop disposal / helper
            if not disposed:
                line_no = src[:cm.start()].count('\n') + body[:body.find(name)].count('\n') + 1
                findings['undisposed'].append(f'{f}:{line_no}: {cm.group(1)}.{name} ({typ})')

for k, v in findings.items():
    print(f'== {k}: {len(v)}')
    for x in v:
        print('  ', x)
