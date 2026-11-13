#!/usr/bin/env bash
# usage: train_pilot.sh <max_epochs> <batch>
set -eo pipefail
. /mnt/e/voice_train/venv/bin/activate
export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${LD_LIBRARY_PATH:-}
export PYTHONPATH=/mnt/d/_wt/piper-train/src/python TMPDIR=/tmp
cd /mnt/e/voice_train
python -m piper_train --dataset-dir /mnt/e/voice_train/pilot --accelerator gpu --devices 1 \
  --batch-size "$2" --validation-split 0.05 --num-test-examples 0 --max_epochs "$1" \
  --resume_from_checkpoint /mnt/d/_wt/piper-train/checkpoints/ar_JO-kareem-medium.ckpt \
  --checkpoint-epochs 50 --precision 32 --quality medium \
  --default_root_dir /mnt/e/voice_train/pilot
echo TRAIN-DONE
