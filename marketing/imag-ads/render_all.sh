#!/usr/bin/env bash
# Rebuild everything: HTML + meta -> music/SFX -> MP4 (verified) -> SCRIPTS.md
set -e
cd "$(dirname "$0")"
(cd src && node build.mjs "$@")
python3 audio/synth.py "$@"
node src/render.mjs ${@:-00 01 02 03 04 05 06 07 08 09 10}
python3 gen_doc.py
