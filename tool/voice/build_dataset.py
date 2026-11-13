"""Ismail's recordings → a clean Piper training set (stage V1 of
docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §6).

    python tool/voice/build_dataset.py --studio D:/_wt/piper-recording-studio --out D:/_wt/voice_dataset/ismail-v1
    (needs: ffmpeg on PATH, `pip install onnxruntime numpy`, and the diacritizer
     model from tool/fetch_tashkeel_model.sh)

For every take the studio saved (never the Quran set — recitation is not
reading, and the app reads the Quran with real reciters):
  1. decode the original .webm → mono 22.05 kHz 16-bit (Piper "medium"),
     trim leading/trailing silence (keeping 0.15 s), normalise loudness;
  2. reject what would teach the voice wrong — too short, cut off (reading
     speed far outside Ismail's own), near-silent, clipped — with the reason;
  3. transcript: «ﷺ» etc. spelled out, then diacritized with the SAME
     model and rule as the app (ichkil v0.3.0; text already ≥60% voweled
     keeps its own marks), so what the voice learns matches what it will
     be given when it reads a book.
Writes  <out>/wavs/<id>.wav, <out>/metadata.csv (id|text, LJSpeech style),
<out>/rejected.csv and <out>/REPORT.md. The originals are never touched.
"""
import argparse
import csv
import json
import os
import re
import statistics
import subprocess
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parent.parent.parent
MODEL = ROOT / 'assets/tts/packs/tashkeel-ichkil-v0.3.0.onnx'
CONFIG = ROOT / 'assets/tts/tashkeel/ichkil_config.json'

# Studio groups used for the reading voice (folder name under output/<lang>/).
INCLUDE_LANGS = ('ar-SA', 'ar-SA-talib', 'ar-SA-books')
EXCLUDE_GROUP = re.compile(r'Quran', re.I)

# ---------------------------------------------------------------- diacritizer (ichkil pipeline.py)
LETTER = re.compile('[\u0621-\u063A\u0641-\u064A]')
DIAC = re.compile('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]')
HARAKA = re.compile('[\u064B-\u0652]')
COMBOS = ['', '', '\u064e', '\u064f', '\u0650', '\u0652', '\u0651', '\u0651\u064e', '\u0651\u064f', '\u0651\u0650',
          '\u064b', '\u064c', '\u064d', '\u0651\u064b', '\u0651\u064c', '\u0651\u064d']
LIGATURES = {'\uFDFA': 'صلى الله عليه وسلم', '\uFDFB': 'جل جلاله', '\uFD40': 'رحمه الله', '\uFD41': 'رضي الله عنه',
             '\uFD42': 'رضي الله عنها', '\uFD43': 'رضي الله عنهم', '\uFD44': 'رضي الله عنهما', '\uFD47': 'عليه السلام'}


class Diacritizer:
    def __init__(self):
        import numpy as np
        import onnxruntime as ort
        self.np = np
        cfg = json.loads(CONFIG.read_text(encoding='utf-8'))
        self.sym2id = cfg['sym2id']
        self.unk = self.sym2id.get('<unk>', 1)
        self.sess = ort.InferenceSession(str(MODEL), providers=['CPUExecutionProvider'])

    @staticmethod
    def normalize(t):
        import unicodedata
        t = unicodedata.normalize('NFC', t)
        for a, b in (('\u0671', '\u0627'), ('\u06cc', '\u064a'), ('\u06a9', '\u0643'), ('\u06c1', '\u0647'), ('\u00a0', ' ')):
            t = t.replace(a, b)
        t = re.sub('[\u200b-\u200f\ufeff]', '', t)
        return re.sub(r'\s+', ' ', t).strip()

    def piece(self, text):
        base = DIAC.sub('', self.normalize(text)).replace('\u0640', '')
        if not LETTER.search(base):
            return base
        ids = self.np.asarray([[self.sym2id.get(c, self.unk) for c in base]], dtype=self.np.int64)
        (logits,) = self.sess.run(['logits'], {'input_ids': ids})
        labels = logits[0].argmax(-1)
        return ''.join(c + (COMBOS[int(l)] if LETTER.fullmatch(c) else '') for c, l in zip(base, labels))

    def __call__(self, text):
        letters = len(LETTER.findall(text))
        if letters and len(HARAKA.findall(text)) >= 0.6 * letters:
            return text  # the book's own marks
        return self.piece(text)


def clean_text(t):
    for k, v in LIGATURES.items():
        t = t.replace(k, ' ' + v + ' ')
    t = t.replace('"', '').replace('“', '').replace('”', '').replace('|', ' ')
    return re.sub(r'\s+', ' ', t).strip()


# ---------------------------------------------------------------- audio
def probe_stats(path):
    log = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-af', 'volumedetect', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    peak = re.search(r'max_volume: (-?[\d.]+) dB', log)
    mean = re.search(r'mean_volume: (-?[\d.]+) dB', log)
    return (float(peak.group(1)) if peak else None, float(mean.group(1)) if mean else None)


def convert(src, dst):
    af = ('silenceremove=start_periods=1:start_silence=0.15:start_threshold=-45dB,'
          'areverse,silenceremove=start_periods=1:start_silence=0.15:start_threshold=-45dB,areverse,'
          'loudnorm=I=-20:TP=-2:LRA=11')
    r = subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(src), '-ac', '1', '-ar', '22050',
                        '-af', af, '-sample_fmt', 's16', str(dst)], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip()[:200])
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', str(dst)],
                         capture_output=True, text=True).stdout.strip()
    return float(out or 0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--studio', required=True)
    ap.add_argument('--out', required=True)
    a = ap.parse_args()
    studio, out = Path(a.studio), Path(a.out)
    (out / 'wavs').mkdir(parents=True, exist_ok=True)

    takes = []
    for lang in INCLUDE_LANGS:
        d = studio / 'output' / lang
        # the studio's original take: .webm (before 2026-11-13; its .wav is a
        # derived copy) or a lossless .wav with no .webm (since then)
        originals = list(d.glob('*/*.webm')) + [w for w in d.glob('*/*.wav') if not w.with_suffix('.webm').exists()]
        for webm in sorted(originals):
            if EXCLUDE_GROUP.search(webm.parent.name):
                continue
            txt = webm.with_suffix('.txt')
            if txt.exists():
                takes.append((lang, webm, txt.read_text(encoding='utf-8').strip()))
    print(f'{len(takes)} takes (Quran set excluded)')

    dia = Diacritizer()
    rows, rejected, durs = [], [], []
    for lang, webm, text in takes:
        tid = f'{lang}_{webm.parent.name.split("_")[-1]}_{webm.stem}'
        dst = out / 'wavs' / f'{tid}.wav'
        try:
            dur = convert(webm, dst)
        except Exception as e:
            rejected.append((tid, 'decode failed', str(e))); continue
        peak, mean = probe_stats(dst)
        text = clean_text(text)
        cps = len(text) / dur if dur else 0
        reason = None
        if dur < 1.0:
            reason = f'too short ({dur:.1f}s)'
        elif mean is not None and mean < -40:
            reason = f'near-silent (mean {mean} dB)'
        rows.append([tid, text, dur, cps, reason, webm])
    # reading speed outliers, judged against Ismail's own median
    med = statistics.median(r[3] for r in rows if not r[4])
    for r in rows:
        if not r[4] and not (med / 1.8 <= r[3] <= med * 1.8):
            r[4] = f'speed {r[3]:.1f} chars/s vs his {med:.1f} — likely cut off or wrong text'
    kept = []
    for tid, text, dur, cps, reason, webm in rows:
        if reason:
            rejected.append((tid, reason, str(webm)))
            (out / 'wavs' / f'{tid}.wav').unlink(missing_ok=True)
            continue
        kept.append((tid, dia(text), dur))
        durs.append(dur)

    with open(out / 'metadata.csv', 'w', encoding='utf-8', newline='\n') as f:
        for tid, text, _ in kept:
            f.write(f'{tid}|{text}\n')
    with open(out / 'rejected.csv', 'w', encoding='utf-8', newline='') as f:
        csv.writer(f).writerows([('id', 'reason', 'source'), *rejected])
    total = sum(durs)
    voweled_src = sum(1 for _, t, _ in kept if len(HARAKA.findall(t)) >= 0.6 * max(1, len(LETTER.findall(t))))
    report = [
        '# مجموعة تدريب صوت إسماعيل — تقرير', '',
        f'- التسجيلات المقبولة: **{len(kept)}**، مدتها **{total / 60:.1f} دقيقة** صافية بعد قصّ السكوت.',
        f'- المرفوضة: **{len(rejected)}** (الأسباب في `rejected.csv`).',
        f'- سرعة قراءتك الوسيطة: {med:.1f} حرفًا في الثانية.',
        f'- كل النصوص مشكولة الآن ({voweled_src}/{len(kept)})، بالنموذج نفسه الذي يشكّل الكتب في التطبيق.',
        '', '| المجموعة | المقبول |', '|---|---|',
    ] + [f'| {l} | {sum(1 for t, _, _ in kept if t.startswith(l + "_"))} |' for l in INCLUDE_LANGS]
    (out / 'REPORT.md').write_text('\n'.join(report) + '\n', encoding='utf-8')
    print('\n'.join(report))
    for r in rejected:
        print('  rejected:', r[0], '—', r[1])


if __name__ == '__main__':
    main()
