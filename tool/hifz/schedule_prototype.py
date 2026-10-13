"""PROTOTYPE (planning only — docs/memorization/HIFZ_SCHEDULE_ARCHITECTURE.md §5).

Measures every ayah's share of mushaf text lines from assets/mushaf/mushaf_layout.json.gz
and simulates the day-by-day schedule generator for the 5 timelines × 2 directions,
solving for the daily new-memorization amount that fits each timeline.

    python3 tool/hifz/schedule_prototype.py

Not used by the app. The real generator will run on-device from mushaf_words.
"""
import gzip, collections, json

d = json.loads(gzip.decompress(open("assets/mushaf/mushaf_layout.json.gz", "rb").read()))
ay = collections.defaultdict(collections.Counter); lw = collections.Counter()
for p in d["pages"]:
    for w in p["words"]:
        if w.get("s") is None: continue
        ay[(w["s"], w["a"])][(p["page"], w["ln"])] += 1; lw[(p["page"], w["ln"])] += 1
L = {f"{s}:{a}": sum(n / lw[pl] for pl, n in c.items()) for (s, a), c in ay.items()}
ay=sorted(((int(k.split(':')[0]),int(k.split(':')[1]),v) for k,v in L.items()))
by_s=collections.defaultdict(list)
for s,a,v in ay: by_s[s].append((a,v))
# juz boundaries (start surah:ayah) — standard
JUZ=[(1,1),(2,142),(2,253),(3,93),(4,24),(4,148),(5,82),(6,111),(7,88),(8,41),(9,93),(11,6),(12,53),(15,1),(17,1),(18,75),(21,1),(23,1),(25,21),(27,56),(29,46),(33,31),(36,28),(39,32),(41,47),(46,1),(51,31),(58,1),(67,1),(78,1)]
juz_start=set(JUZ)
def order(direction):
    ss=range(1,115) if direction=='mushaf' else range(114,0,-1)
    return [(s,a,v) for s in ss for a,v in by_s[s]]
def build(direction,q,tol=0.35):
    seq=order(direction); days=[]; i=0; n=len(seq); day=0
    while i<n:
        day+=1
        if day%7==0: days.append(('week',)); continue
        acc=0; start=i
        while i<n and acc<q:
            acc+=seq[i][2]; i+=1
        # extend to surah end if close
        if i<n and seq[i-1][0]==seq[i][0]:
            s=seq[i-1][0]; rest=sum(v for (ss,a,v) in seq[i:] if ss==s)
            if rest<=q*tol: 
                while i<n and seq[i][0]==s: acc+=seq[i][2]; i+=1
        days.append(('new',seq[start][:2],seq[i-1][:2],acc))
        ended=seq[i-1][0]!=(seq[i][0] if i<n else None)
        s=seq[i-1][0]; slen=sum(v for a,v in by_s[s])
        if ended and slen>=2*q: days.append(('surah',s)); day+=1
        if i<n and (seq[i][0],seq[i][1]) in juz_start and direction=='mushaf': days.append(('juz',)); day+=1
        if direction=='reverse' and i<n:
            # reverse: juz review when crossing a juz start backwards (the surah we just finished began a juz region)
            pass
    return days
PRESETS=[('6m',182,21),('10m',301,35),('19m',574,56),('24m',728,70),('27m',819,84)]
res=[]
for name,D,F in PRESETS:
    for dirn in ['reverse','mushaf']:
        lo,hi=1.0,200.0
        for _ in range(40):
            mid=(lo+hi)/2
            if len(build(dirn,mid))<=D-F: hi=mid
            else: lo=mid
        days=build(dirn,hi); c=collections.Counter(d[0] for d in days)
        res.append((name,dirn,D,F,round(hi,1),round(hi/14.6,2),c['new'],c['surah']+c['juz'],c['week'],len(days)))
print('preset dir totalDays finalPhase linesPerNewDay pagesPerNewDay newDays reviewDays weekDays scheduleDays')
for r in res: print(*r)
