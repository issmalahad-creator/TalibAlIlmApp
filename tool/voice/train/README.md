# Training Ismail's voice (Piper, fine-tuned from ar_JO-kareem-medium)

Runs in WSL Ubuntu; everything heavy lives on drive E (`/mnt/e/voice_train`), never on C.
Plan: `docs/audio-reader/MY_VOICE_PLAN_2026-11-13.md` §6, §11.

1. `setup_env.sh`: Python 3.10 venv on E, torch 1.13.1+cu117, piper-train deps, monotonic_align.
2. `check_env.sh`: installs `six`, verifies CUDA + the Arabic phonemizer.
3. `python tool/voice/build_dataset.py --studio D:/_wt/piper-recording-studio --out D:/_wt/voice_dataset/ismail-v1`
   (Windows side: clean, trimmed, diacritized LJSpeech set).
4. `preprocess_pilot.sh`: `piper_train.preprocess --language ar` (no `--tashkeel`: the text is
   already diacritized with ichkil, the same model the app uses).
5. `train_pilot.sh <max_epochs> <batch>`: resumes Kareem's checkpoint (epoch 5079), so max_epochs = 5079 + N.

Gotchas found on this machine (2026-11-13):
- Call WSL from Git Bash with `MSYS_NO_PATHCONV=1`, or `/mnt/e/...` gets rewritten to a Windows path.
- `TMPDIR` must be WSL's own `/tmp`: DataLoader workers bind a Unix socket there, and `/mnt/e` (drvfs) refuses it.
- `LD_LIBRARY_PATH=/usr/lib/wsl/lib`, or cuDNN can't find `libcuda.so`.
- No `--max-phoneme-ids 400`: it silently dropped more than half of Ismail's (long) sentences. Batch 8 fits in the RTX 3050's 4 GB without it.
- pip < 24.1 (pytorch-lightning 1.7 metadata).
