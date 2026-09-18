#!/usr/bin/env sh
# tool/fetch_tts_voice.sh — القارئ الصوتي العام (docs/audio-reader/TODO.md 1.1).
#
# ينزّل، من commit مثبَّت (pinned)، ملفات صوت Piper العربي المُعاد تعبئته
# رسميًا لصيغة sherpa_onnx (لا صيغة Piper الخام — sherpa_onnx يحتاج
# tokens.txt + espeak-ng-data بهذا الشكل تحديدًا):
#
#   المصدر: https://huggingface.co/csukuangfj/vits-piper-ar_JO-kareem-medium
#   الترخيص: MIT (النموذج الأصلي rhasspy/piper-voices، صوت ar_JO-kareem-medium).
#
# المُخرَج → assets/tts/  (مُستبعَد من git عمدًا — .gitignore، ~62 م.ب، نفس
# سياسة هذا المشروع مع أي أصل خام كبير: انظر tool/fetch_tajweed_source.sh).
# pubspec.yaml يُدرِج هذه المسارات كأصول Flutter بافتراض وجودها محليًا وقت
# البناء فقط — لا وقت commit.
#
#   sh tool/fetch_tts_voice.sh          # يتخطّى ما هو موجود فعلًا بالحجم الصحيح
#   sh tool/fetch_tts_voice.sh --force  # إعادة تنزيل كل شيء

set -eu

SHA="d05103ccf42f2b625d36c406da2646edd95ea353"   # HF repo HEAD وقت التحقّق، 2026-09-17
BASE="https://huggingface.co/csukuangfj/vits-piper-ar_JO-kareem-medium/resolve/${SHA}"
DEST="assets/tts"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

mkdir -p "$DEST/espeak-ng-data"

fetch() {
  path="$1"; min_bytes="$2"
  out="$DEST/$path"
  if [ "$FORCE" -eq 0 ] && [ -f "$out" ]; then
    size=$(wc -c < "$out")
    if [ "$size" -ge "$min_bytes" ]; then
      echo "skip (exists, ${size}B): $path"
      return
    fi
  fi
  echo "fetching: $path"
  curl -fL --create-dirs -o "$out" "${BASE}/${path}"
  size=$(wc -c < "$out")
  if [ "$size" -lt "$min_bytes" ]; then
    echo "ERROR: $path only ${size}B, expected >= ${min_bytes}B — أعد المحاولة أو تحقّق من الاتصال" >&2
    exit 1
  fi
}

fetch "ar_JO-kareem-medium.onnx" 60000000
fetch "ar_JO-kareem-medium.onnx.json" 500
fetch "tokens.txt" 500

# الحد الأدنى فقط: العربية + الملفات المشتركة (~1.2 م.ب) — لا كل اللغات
# (~19 م.ب في حزمة pip piper-tts). أسماء الملفات مطابقة صراحةً لِما
# tts_voice_registry.dart يذكره في espeakDataFiles.
for f in ar_dict intonations phondata phondata-manifest phonindex phontab; do
  fetch "espeak-ng-data/$f" 100
done

# تعريف صوت "ar" الفعلي (اسم + رمز اللغة + قواعد النبر) — بدونه يفشل
# espeak-ng بصمت في "تعيين" الصوت رغم وجود القاموس الصوتي (ar_dict) نفسه.
# اكتُشِف فقط بتشغيل فعلي على جهاز حقيقي (2026-09-18)، ليس بديهيًا من توثيق
# espeak-ng نفسه.
mkdir -p "$DEST/espeak-ng-data/lang/sem"
fetch "espeak-ng-data/lang/sem/ar" 20

# النموذج المُنزَّل من HF لا يحمل بيانات وصفية (metadata_props) داخل ملف
# ONNX نفسه — sherpa_onnx يحتاجها (sample_rate تحديدًا) ويفشل التشغيل
# بصمت (exit code 255) بدونها. رقعة تُضيفها بعد كل تنزيل جديد.
if [ "$FORCE" -eq 1 ] || ! py -c "
import onnx
m = onnx.load('$DEST/ar_JO-kareem-medium.onnx')
assert any(p.key == 'sample_rate' for p in m.metadata_props)
" 2>/dev/null; then
  echo "patching ONNX metadata (sample_rate, etc.) — see tool/patch_tts_model_metadata.py"
  py tool/patch_tts_model_metadata.py
fi

echo "done: $DEST"
