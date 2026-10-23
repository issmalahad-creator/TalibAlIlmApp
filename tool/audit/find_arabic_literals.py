import re,sys
for f in sys.argv[1:]:
    for i,l in enumerate(open(f,encoding='utf-8'),1):
        s=l.strip()
        if s.startswith('//'): continue
        code=l.split('//')[0] if "'//" not in l and '"//' not in l else l
        if re.search(r"""(['"])[^'"\n]*[؀-ۿ][^'"\n]*\1""",code):
            print(f'{f}:{i}: {s[:170]}')
