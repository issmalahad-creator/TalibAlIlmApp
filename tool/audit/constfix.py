"""Remove the nearest enclosing `const` for every const-evaluation error the
analyzer reports in the given files; repeat until clean (max 12 rounds)."""
import re, subprocess, sys

import os
FLUTTER = os.environ.get('FLUTTER', 'flutter')
CODES = ('const_eval_method_invocation', 'invalid_constant', 'non_constant_list_element',
         'const_with_non_constant_argument', 'const_eval_type_bool_num_string', 'non_constant_map_element',
         'const_constructor_param_type_mismatch', 'const_initialized_with_non_constant_value')
files = sys.argv[1:]
for rnd in range(12):
    out = subprocess.run([FLUTTER, 'analyze', *files], capture_output=True, text=True).stdout
    errs = []
    for ln in out.splitlines():
        if 'error •' in ln and any(c in ln for c in CODES):
            m = re.search(r'• (\S+\.dart):(\d+):(\d+) •', ln)
            if m:
                errs.append((m.group(1), int(m.group(2)), int(m.group(3))))
    if not errs:
        print(f'clean after {rnd} rounds')
        break
    # one fix per file per round (fixes shift nothing: we only delete 'const ' text)
    done = set()
    for f, l, c in errs:
        if f in done:
            continue
        lines = open(f, encoding='utf-8').read().split('\n')
        # search backwards from the error position for the nearest 'const '
        fixed = False
        for i in range(l - 1, max(-1, l - 40), -1):
            seg = lines[i] if i != l - 1 else lines[i][:c - 1]
            j = seg.rfind('const ')
            if j >= 0:
                lines[i] = lines[i][:j] + lines[i][j + 6:]
                fixed = True
                break
        if fixed:
            open(f, 'w', encoding='utf-8').write('\n'.join(lines))
            done.add(f)
else:
    print('still errors after 12 rounds')
print(subprocess.run([FLUTTER, 'analyze', *files], capture_output=True, text=True).stdout.splitlines()[-1])
