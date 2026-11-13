"""Add the Kazakh voice-over to the rendered iMag videos (run on your own computer).

Voice: Microsoft neural TTS via edge-tts (free, no key):
  kk-KZ-DauletNeural (male, narrator)   kk-KZ-AigulNeural (female, character lines)

Setup (once):
  pip install edge-tts
  ffmpeg must be on PATH (Windows: winget install ffmpeg)

Usage (from this folder):
  python make_voice.py                 # all videos with voice-over
  python make_voice.py 01 02           # selected videos
  python make_voice.py 01 --rate +12%  # faster/slower speech
  python make_voice.py 01 --test-tones # no internet: checks the mixing with beeps instead of speech

Result: out/<id>/iMag_<id>_voice.mp4 (music is ducked automatically under the voice).
"""
import argparse, asyncio, json, shutil, subprocess, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE / "out"
# role -> (voice, rate offset %, pitch). m = narrator, m2 = male character, f = female, f2 = grandmother
VOICES = {"m": ("kk-KZ-DauletNeural", 0, "+0Hz"), "m2": ("kk-KZ-DauletNeural", -4, "-6Hz"),
          "f": ("kk-KZ-AigulNeural", 0, "+0Hz"), "f2": ("kk-KZ-AigulNeural", -10, "-12Hz")}
# How the TTS should pronounce brand words / abbreviations. Edit if you prefer another reading.
SAY = {"iMag Kassa": "Ай Маг Касса", "iMag-та": "Ай Маг-та", "iMag": "Ай Маг", "PLU": "пи-эл-ю", "PDF": "пи-ди-эф", "«": "", "»": ""}

def speakable(text):
    for k, v in SAY.items():
        text = text.replace(k, v)
    return text

def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode:
        sys.exit(f"command failed: {' '.join(map(str, cmd))}\n{r.stderr[-1500:]}")
    return r.stdout

def duration(path):
    return float(run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)]).strip())

async def tts(text, role, rate, path):
    import os, edge_tts  # pip install edge-tts
    voice, off, pitch = VOICES.get(role, VOICES["m"])
    r = int(rate.rstrip("%")) + off
    proxy = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy")
    await edge_tts.Communicate(text, voice, rate=f"{r:+d}%", pitch=pitch, proxy=proxy).save(str(path))

def make(vid, rate, test_tones):
    meta = json.loads((OUT / vid / f"{vid}.meta.json").read_text(encoding="utf-8"))
    video = OUT / vid / f"iMag_{vid}.mp4"
    if meta.get("noVoice"):
        print(f"{vid}: text-only video (no voice-over by design) — skipped"); return
    if not video.exists():
        sys.exit(f"{video} not found — render the video first")
    tmp = OUT / vid / "vo"; tmp.mkdir(exist_ok=True)
    lines = []
    for i, v in enumerate(meta["vo"]):
        p = tmp / f"line{i:02d}.mp3"
        if test_tones:
            secs = max(1.0, len(v["text"]) / 13)
            run(["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi", "-i", f"sine=frequency=440:duration={secs:.2f}", str(p)])
        else:
            asyncio.run(tts(speakable(v["text"]), v.get("voice", "m"), rate, p))
        d = duration(p); slot = v["slot"] + 0.25
        if d > slot:  # speed the line up a little (max 15 %) so it fits its scene
            tempo = min(1.15, d / slot); q = tmp / f"line{i:02d}_fit.mp3"
            run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(p), "-filter:a", f"atempo={tempo:.3f}", str(q)]); p = q
            if d / tempo > slot + 0.05:
                print(f"  ! {vid} line {i} is {d:.1f}s for a {slot:.1f}s slot even at {tempo:.2f}x — consider shortening: {v['text']}")
        lines.append((v["t"], p))
        print(f"  {vid} line {i}: {d:.2f}s (slot {slot:.2f}s)")
    # mix: voice lines at their timestamps; music ducked under voice (sidechain), sfx on top
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", str(video), "-i", str(OUT / vid / "music.wav"), "-i", str(OUT / vid / "sfx.wav")]
    for _, p in lines:
        cmd += ["-i", str(p)]
    VOX = "highpass=f=80,acompressor=threshold=0.08:ratio=3:attack=5:release=90:makeup=2,equalizer=f=200:t=q:w=1:g=-1.5,equalizer=f=3200:t=q:w=1.2:g=2.5,equalizer=f=9000:t=q:w=1:g=-1"
    parts = [f"[{3 + i}:a]aformat=sample_rates=44100:channel_layouts=stereo,{VOX},adelay={int(t * 1000)}|{int(t * 1000)},volume=1.5[v{i}]" for i, (t, _) in enumerate(lines)]
    parts.append("".join(f"[v{i}]" for i in range(len(lines))) + f"amix=inputs={len(lines)}:normalize=0[vo]")
    parts.append("[vo]asplit=2[vo1][vo2]")
    parts.append("[1:a]volume=0.42[mus];[mus][vo1]sidechaincompress=threshold=0.03:ratio=8:attack=20:release=350[duck]")
    parts.append("[2:a]volume=0.8[fx];[duck][fx][vo2]amix=inputs=3:normalize=0,loudnorm=I=-14:TP=-1.0:LRA=11,aresample=44100[a]")
    cmd += ["-filter_complex", ";".join(parts), "-map", "0:v:0", "-map", "[a]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-t", str(meta["duration"]), "-movflags", "+faststart", str(OUT / vid / f"iMag_{vid}_voice.mp4")]
    run(cmd)
    print(f"{vid}: {OUT / vid / f'iMag_{vid}_voice.mp4'}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("ids", nargs="*")
    ap.add_argument("--rate", default="+8%", help="speech rate for edge-tts, e.g. +0%%, +8%%, +15%%")
    ap.add_argument("--test-tones", action="store_true")
    a = ap.parse_args()
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg not found on PATH")
    ids = a.ids or sorted(p.name for p in OUT.iterdir() if (p / f"{p.name}.meta.json").exists())
    for vid in ids:
        make(vid, a.rate, a.test_tones)
