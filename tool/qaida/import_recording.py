"""Cuts ONE lesson recording into its sounds for the Noorani Qaida.

    python tool/qaida/import_recording.py q04 path/to/q04.m4a [--noise -35] [--gap 0.6] [--dry-run]

The recording reads the lesson's NEW sounds (docs/qaida/RECORDING_LIST.md)
in order, with about a second of silence between them. The tool finds the
silences with ffmpeg, checks that the number of sounds is exactly what the
lesson expects, and only then writes each one to
assets/qaida/audio/<audio id>.m4a (mono AAC, loudness-normalized, 80 ms of
padding each side). A wrong count writes nothing and prints what it heard,
so a skipped or doubled sound is never silently mis-labelled.

Any format ffmpeg reads works (phone .m4a / .mp3 / .ogg / .wav / .opus).
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PAD = 0.08


def expected_ids(lesson_id):
    data = json.load(open(os.path.join(ROOT, 'assets/qaida/qaida_lessons.json'), encoding='utf-8'))
    seen, order = set(), {}
    for les in data['lessons']:
        new = []
        for it in les['items']:
            if it['a'] not in seen:
                seen.add(it['a'])
                new.append(it['a'])
        order[les['id']] = new
    if lesson_id not in order:
        sys.exit(f'unknown lesson {lesson_id}; lessons: {", ".join(order)}')
    return order[lesson_id]


def duration(path):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', path],
                         capture_output=True, text=True, check=True).stdout
    return float(out.strip())


def speech_segments(path, noise, gap):
    log = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', path, '-af',
                          f'silencedetect=noise={noise}dB:d={gap}', '-f', 'null', '-'],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r'silence_start: (-?[\d.]+)', log)]
    ends = [float(x) for x in re.findall(r'silence_end: ([\d.]+)', log)]
    total = duration(path)
    # speech = the gaps between silences
    segs, cursor = [], 0.0
    for i, s in enumerate(starts):
        if s - cursor > 0.12:
            segs.append((max(cursor, 0.0), s))
        cursor = ends[i] if i < len(ends) else total
    if total - cursor > 0.12:
        segs.append((cursor, total))
    return [(a, b) for a, b in segs if b - a >= 0.15]  # drop clicks


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('lesson')
    ap.add_argument('recording')
    ap.add_argument('--noise', type=float, default=-35, help='silence threshold in dB (raise to -30 in a noisy room)')
    ap.add_argument('--gap', type=float, default=0.6, help='shortest pause between two sounds, seconds')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()
    if not shutil.which('ffmpeg'):
        sys.exit('ffmpeg is needed on PATH')

    ids = expected_ids(a.lesson)
    if not ids:
        sys.exit(f'{a.lesson} needs no recording: its sounds were recorded in an earlier lesson')
    segs = speech_segments(a.recording, a.noise, a.gap)
    print(f'{a.lesson}: heard {len(segs)} sounds, expected {len(ids)}')
    if len(segs) != len(ids):
        for i, (s, e) in enumerate(segs, 1):
            print(f'  {i:3d}. {s:7.2f}s – {e:7.2f}s  ({e - s:.2f}s)')
        sys.exit('count mismatch — nothing written. Re-record, or adjust --noise / --gap.')
    if a.dry_run:
        return
    out_dir = os.path.join(ROOT, 'assets/qaida/audio')
    os.makedirs(out_dir, exist_ok=True)
    for (s, e), audio_id in zip(segs, ids):
        start = max(0.0, s - PAD)
        length = e - s + 2 * PAD
        subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-ss', f'{start:.3f}', '-t', f'{length:.3f}',
                        '-i', a.recording, '-ac', '1', '-ar', '44100',
                        '-af', 'loudnorm=I=-18:TP=-2:LRA=7', '-c:a', 'aac', '-b:a', '64k',
                        os.path.join(out_dir, f'{audio_id}.m4a')], check=True)
    size = sum(os.path.getsize(os.path.join(out_dir, f'{i}.m4a')) for i in ids)
    print(f'wrote {len(ids)} files to assets/qaida/audio ({size // 1024} KB)')


if __name__ == '__main__':
    main()
