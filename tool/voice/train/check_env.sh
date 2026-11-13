#!/usr/bin/env bash
set -eo pipefail
export PIP_CACHE_DIR=/mnt/e/voice_train/pipcache TMPDIR=/mnt/e/voice_train/tmp
. /mnt/e/voice_train/venv/bin/activate
python -m pip install -q six
cd /mnt/d/_wt/piper-train/src/python
ls piper_train/vits/monotonic_align/monotonic_align/core*.so >/dev/null 2>&1 || bash build_monotonic_align.sh
export PYTHONPATH=/mnt/d/_wt/piper-train/src/python
python - <<'PY'
import torch, pytorch_lightning, piper_phonemize
from piper_train.vits import monotonic_align
print('torch', torch.__version__, 'cuda', torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')
print('lightning', pytorch_lightning.__version__)
print(piper_phonemize.phonemize_espeak('السَّلَامُ عَلَيْكُمْ', 'ar'))
print('ENV-OK')
PY
