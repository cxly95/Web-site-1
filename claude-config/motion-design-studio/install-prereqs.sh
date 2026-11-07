#!/usr/bin/env bash
# Heavy prerequisites of the motion design method, installed on demand (about 2-3 min):
# Whisper for word timings (CPU build of torch) and Python Playwright for style frames.
set -e
python3 -c "import torch" 2>/dev/null || pip install -q torch --index-url https://download.pytorch.org/whl/cpu
python3 -c "import whisper" 2>/dev/null || pip install -q openai-whisper
python3 -c "import playwright" 2>/dev/null || pip install -q playwright
python3 -m playwright install chromium-headless-shell >/dev/null
echo "motion design prerequisites ready"
