#!/usr/bin/env bash
# Renders every video: HTML frames -> H.264 MP4 with the synthesized music+SFX mix.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
RENDER="${RENDER:-/root/.claude/skills/synced/7366cc5b-bda1-437b-be04-195e85a07abf_f7ac5fc9-dfad-40c2-88a5-7900b9c49611/animation-studio/scripts/render_video.mjs}"
IDS="${@:-00 01 02 03 04 05 06 07 08 09 10}"
cd "$HERE"
for id in $IDS; do
  dur=$(python3 -c "import json;print(json.load(open('out/$id/$id.meta.json'))['duration'])")
  node "$RENDER" --html "$HERE/out/$id/$id.html" --seconds "$dur" --width 1080 --height 1920 --fps 24 \
    --audio "$HERE/out/$id/mix.wav" --audio-kind music --output "$HERE/out/$id/iMag_$id.mp4" --overwrite
done
