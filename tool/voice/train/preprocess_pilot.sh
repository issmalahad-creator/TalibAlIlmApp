#!/usr/bin/env bash
set -eo pipefail
. /mnt/e/voice_train/venv/bin/activate
export PYTHONPATH=/mnt/d/_wt/piper-train/src/python TMPDIR=/mnt/e/voice_train/tmp
python - <<'PY'
import torch
ck = torch.load('/mnt/d/_wt/piper-train/checkpoints/ar_JO-kareem-medium.ckpt', map_location='cpu')
print('kareem checkpoint epoch', ck.get('epoch'), 'step', ck.get('global_step'))
PY
python -m piper_train.preprocess --language ar --input-dir /mnt/d/_wt/voice_dataset/ismail-v1 \
  --output-dir /mnt/e/voice_train/pilot --dataset-format ljspeech --single-speaker --sample-rate 22050 --max-workers 4
ls /mnt/e/voice_train/pilot; wc -l /mnt/e/voice_train/pilot/dataset.jsonl
head -c 400 /mnt/e/voice_train/pilot/dataset.jsonl; echo; echo PRE-OK
