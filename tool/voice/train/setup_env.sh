#!/usr/bin/env bash
# Piper training environment for Ismail's voice (docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md §6).
set -euo pipefail
export PIP_CACHE_DIR=/mnt/e/voice_train/pipcache TMPDIR=/mnt/e/voice_train/tmp
mkdir -p "$PIP_CACHE_DIR" "$TMPDIR"
cd /mnt/e/voice_train
[ -d venv ] || python3.10 -m venv venv
. venv/bin/activate
python -m pip install --upgrade "pip<24.1" wheel "setuptools<70"
python -m pip install "torch==1.13.1+cu117" --extra-index-url https://download.pytorch.org/whl/cu117
python -m pip install "cython>=0.29,<1" "piper-phonemize~=1.1.0" "librosa>=0.9.2,<1" "numpy<1.24" onnxruntime "pytorch-lightning~=1.7.0" "torchmetrics<0.12" onnx
cd /mnt/d/_wt/piper-train/src/python && bash build_monotonic_align.sh
python - <<'PY'
import torch, pytorch_lightning, piper_phonemize
print('torch', torch.__version__, 'cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')
print('lightning', pytorch_lightning.__version__)
print(piper_phonemize.phonemize_espeak('السَّلَامُ عَلَيْكُمْ', 'ar'))
PY
echo SETUP-OK
