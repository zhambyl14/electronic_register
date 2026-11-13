"""Procedural, royalty-free music beds + sound effects for the iMag ads.

Everything is synthesized from scratch with numpy (no samples, no downloads), so the
audio is original and free to use. For each video it writes out/<id>/music.wav,
out/<id>/sfx.wav and out/<id>/mix.wav (music + sfx, used when there is no voice-over).

usage: python3 synth.py [ids...]
"""
import json, sys, wave
from pathlib import Path
import numpy as np

SR = 44100
OUT = Path(__file__).resolve().parent.parent / "out"
rng = np.random.default_rng(1234)

# ── basic dsp ───────────────────────────────────────────────────────────────
def t_(d): return np.arange(int(SR * d)) / SR
def env(n, a=.005, d=.1, s=0., r=.05, sus_len=None):
    a_n, d_n, r_n = int(a * SR), int(d * SR), int(r * SR)
    e = np.zeros(n); i = 0
    e[:min(a_n, n)] = np.linspace(0, 1, min(a_n, n)); i = a_n
    if i < n: k = min(d_n, n - i); e[i:i + k] = np.linspace(1, s, k); i += k
    if i < n: e[i:] = s
    if r_n and n > r_n: e[-r_n:] *= np.linspace(1, 0, r_n)
    return e
def expdec(n, tau): return np.exp(-np.arange(n) / (SR * tau))
def lp(x, fc):  # one-pole low-pass
    a = np.exp(-2 * np.pi * fc / SR); y = np.empty_like(x); acc = 0.
    # vectorised via lfilter-like recursion in chunks
    from itertools import accumulate
    y = np.array(list(accumulate(x * (1 - a), lambda p, v: p * a + v)))
    return y
def hp(x, fc): return x - lp(x, fc)
def noise(n): return rng.uniform(-1, 1, n)
def mtof(m): return 440. * 2 ** ((m - 69) / 12)
def sine(f, d, ph=0): return np.sin(2 * np.pi * f * t_(d) + ph)
def sweep(f0, f1, d, curve=1.):
    tt = t_(d); k = (tt / d) ** curve; f = f0 + (f1 - f0) * k
    return np.sin(2 * np.pi * np.cumsum(f) / SR)
def saw(f, d):
    tt = t_(d); return 2 * ((tt * f) % 1) - 1
def tri(f, d):
    return 2 * np.abs(saw(f, d)) - 1
def ks(f, d, bright=.5, decay=.996):  # Karplus-Strong plucked string (vectorised per period)
    n = int(SR * d); N = max(2, int(SR / f)); y = np.zeros(n + N)
    y[:N] = lp(noise(N), 800 + 6000 * bright)
    for s in range(N, n + N, N):
        e = min(s + N, n + N); prev = y[s - N:e - N]; prev2 = y[s - N - 1:e - N - 1] if s - N - 1 >= 0 else np.concatenate([[0], y[s - N:e - N - 1]])
        y[s:e] = decay * .5 * (prev + prev2[:len(prev)])
    return y[N:N + n]
def pad(x, n): return np.pad(x, (0, max(0, n - len(x))))[:n]

# ── sound effects library ───────────────────────────────────────────────────
def S_pop(): d = .12; return sweep(900, 300, d, .5) * expdec(int(SR * d), .03)
def S_tap(): d = .05; return (sine(1800, d) * .5 + noise(int(SR * d)) * .3) * expdec(int(SR * d), .008)
def S_ding(): d = 1.0; x = sine(1318, d) + .5 * sine(2637, d) + .25 * sine(3951, d); return x * expdec(int(SR * d), .25) * .6
def S_whoosh(): d = .5; n = int(SR * d); x = noise(n); x = lp(x, 2500) * np.sin(np.linspace(0, np.pi, n)) ** 2; return hp(x, 300) * 1.4
def S_swoosh_out(): x = S_whoosh()[::-1].copy(); return x
def S_riser(): d = 1.4; n = int(SR * d); return (sweep(200, 1400, d, 2) * .3 + lp(noise(n), 3000) * .4) * np.linspace(0, 1, n) ** 2
def S_success():
    x = np.zeros(int(SR * .7))  # C-E-G-C arpeggio
    for i, m in enumerate([72, 76, 79, 84]): s = (sine(mtof(m), .35) + .3 * sine(2 * mtof(m), .35)) * expdec(int(SR * .35), .12); o = int(i * .08 * SR); x[o:o + len(s)] += s * .5
    return x
def S_sparkle():
    x = np.zeros(int(SR * .9))
    for i in range(9): m = 88 + (i * 5) % 12; s = sine(mtof(m), .25) * expdec(int(SR * .25), .06); o = int(i * .07 * SR); x[o:o + len(s)] += s * .3
    return x
def S_blip(): d = .08; return sine(1500, d) * env(int(SR * d), .002, .07) * .5
def S_phone_buzz():
    d = .9; n = int(SR * d); x = (sine(170, d) + .5 * saw(170, d)) * .4; gate = ((np.arange(n) / SR) % .3 < .2).astype(float); return lp(x * gate, 900)
def S_stamp(): d = .35; n = int(SR * d); return (sweep(160, 50, d, .4) * 1.0 + lp(noise(n), 1500) * .6) * expdec(n, .06)
def S_logo_hit():
    d = 1.6; n = int(SR * d); x = sweep(110, 45, d, .3) * expdec(n, .25) * .9
    for m in [60, 64, 67, 72]: x += (sine(mtof(m), d) + .3 * sine(mtof(m) * 2, d)) * expdec(n, .5) * .18
    return x + lp(noise(n), 6000) * expdec(n, .04) * .3
def S_rewind(): d = .8; n = int(SR * d); return (saw(1, d) * 0 + sweep(1200, 200, d, .7) * .3 + hp(noise(n), 2000) * .2) * np.sin(np.linspace(0, np.pi, n))
def S_pencil(): d = .6; n = int(SR * d); x = hp(noise(n), 2500) * .4; g = (np.sin(2 * np.pi * 9 * t_(d)) > 0).astype(float); return x * g * env(n, .01, .5, 0)
def S_calc(): d = .06; return sine(2400, d) * expdec(int(SR * d), .015) * .5
def S_tick(): d = .04; return hp(noise(int(SR * d)), 3000) * expdec(int(SR * d), .005) * .9
def S_sigh(): d = .9; n = int(SR * d); x = lp(noise(n), 1400) * np.sin(np.linspace(0, np.pi, n)) ** 1.5; return x * .5 + sweep(300, 180, d) * .05 * np.sin(np.linspace(0, np.pi, n))
def S_ring():
    x = np.zeros(int(SR * 1.2))
    for k in range(2):
        s = (sine(1100, .4) + sine(1400, .4)) * ((np.arange(int(SR * .4)) / SR * 25) % 1 < .5) * .25; o = int(k * .55 * SR); x[o:o + len(s)] += s
    return x
def S_thud(): d = .3; n = int(SR * d); return (sweep(120, 40, d, .3) + lp(noise(n), 400) * .5) * expdec(n, .07)
def S_plug(): d = .15; n = int(SR * d); return (hp(noise(n), 1500) * .6 + sine(400, d) * .3) * expdec(n, .02)
def S_scale_beep(): d = .18; return sine(2000, d) * env(int(SR * d), .002, .15, .8, .02) * .5
def S_scan(): d = .14; return (sine(2900, d) * .8 + sine(5800, d) * .1) * env(int(SR * d), .002, .1, .9, .02) * .6
def S_kaching():
    d = 1.0; n = int(SR * d); x = lp(noise(int(SR * .08)), 3000); x = pad(x * expdec(len(x), .02), n) * .6
    for f in [2093, 2637, 3136, 4186]: x += sine(f, d) * expdec(n, .3) * .18
    o = int(.12 * SR); y = np.zeros(n); y[o:] = x[:n - o]; return x * .4 + y
def S_print():
    d = 1.6; n = int(SR * d); tt = t_(d); motor = saw(52, d) * .25 + hp(noise(n), 2000) * .15
    return lp(motor, 1800) * (0.6 + .4 * (np.sin(2 * np.pi * 18 * tt) > 0)) * env(n, .03, .1, .9, .1)
def S_laugh():  # cartoon "ha-ha-ha" bounce
    x = np.zeros(int(SR * .9))
    for i, f in enumerate([520, 480, 440, 400]): s = (saw(f, .14) * .3 + sine(f, .14) * .4) * env(int(SR * .14), .01, .12, 0); s = lp(s, 2500); o = int(i * .18 * SR); x[o:o + len(s)] += s
    return x
def S_buzz(): d = .45; n = int(SR * d); return lp(saw(110, d) + saw(116, d), 1200) * env(n, .005, .3, .7, .05) * .35
def S_error(): x = np.concatenate([S_buzz()[:int(SR * .15)], np.zeros(int(SR * .05)), S_buzz()[:int(SR * .2)]]); return x
def S_record_scratch(): d = .5; n = int(SR * d); return (sweep(1500, 200, d, .5) * .3 + hp(noise(n), 1500) * .3) * expdec(n, .12)
def S_confetti():
    x = np.zeros(int(SR * 1.2)); x[:int(SR * .1)] += lp(noise(int(SR * .1)), 4000) * expdec(int(SR * .1), .02)
    for i in range(14): o = int((.05 + i * .06) * SR); s = sine(2000 + i * 230, .05) * expdec(int(SR * .05), .01) * .25; x[o:o + len(s)] += s
    return x
def S_type(): d = .035; n = int(SR * d); return (hp(noise(n), 1500) * .6 + sine(900, d) * .3) * expdec(n, .006)
def S_impact(): d = .9; n = int(SR * d); return sweep(90, 35, d, .3) * expdec(n, .2) + lp(noise(n), 2500) * expdec(n, .05) * .6
def S_doorbell(): x = np.zeros(int(SR * 1.3)); a = (sine(1319, .8) + .4 * sine(2638, .8)) * expdec(int(SR * .8), .3) * .4; b = (sine(1047, .9) + .4 * sine(2094, .9)) * expdec(int(SR * .9), .35) * .4; x[:len(a)] += a; o = int(.3 * SR); x[o:o + len(b)] += b; return x
def S_shake(): d = .5; n = int(SR * d); return hp(noise(n), 4000) * (np.sin(2 * np.pi * 14 * t_(d)) > .3) * .35
def S_lock(): x = np.zeros(int(SR * .4)); a = S_tap() * 2; x[:len(a)] += a; o = int(.12 * SR); x[o:o + len(a)] += a * 1.2; return x
def S_coin_down():
    x = np.zeros(int(SR * .8))
    for i in range(5):
        s = sine(mtof(84 - i * 3), .12) * expdec(int(SR * .12), .04) * .4; o = int(i * .1 * SR); x[o:o + len(s)] += s
    return x
def S_coin(): d = .5; n = int(SR * d); return (sine(1976, d) + sine(2637, d) * .6) * expdec(n, .1) * .4
def S_alarm(): d = .8; n = int(SR * d); return sine(1000, d) * (((np.arange(n) / SR) * 8) % 1 < .5) * env(n, .005, .7, .9, .05) * .3
def S_question(): d = .45; return sweep(400, 900, d, 1.5) * env(int(SR * d), .01, .4, 0) * .4
def S_hmm(): d = .7; tt = t_(d); return np.sin(2 * np.pi * (180 + 6 * np.sin(2 * np.pi * 5 * tt)) * tt) * env(int(SR * d), .05, .6, .5, .1) * .35
def S_crowd(): d = 1.6; n = int(SR * d); return lp(noise(n), 700) * (0.6 + .4 * np.sin(2 * np.pi * 3 * t_(d))) * env(n, .2, 1, .8, .3) * .5
def S_paper(): d = .3; n = int(SR * d); return hp(noise(n), 2500) * np.sin(np.linspace(0, np.pi, n)) * .5
def S_crumple(): d = .5; n = int(SR * d); return hp(noise(n), 1800) * ((noise(n) > .6).astype(float) * .8 + .2) * env(n, .01, .45, 0) * .6
def S_tear(): d = .35; n = int(SR * d); return hp(noise(n), 1200) * np.linspace(1, .2, n) * .6
def S_bin(): d = .5; n = int(SR * d); return (sine(240, d) + sine(380, d) * .5) * expdec(n, .12) * .4 + lp(noise(n), 900) * expdec(n, .04) * .4
def S_power_on(): d = .6; n = int(SR * d); return sweep(80, 800, d, .7) * env(n, .01, .5, .3, .1) * .3
def S_counter():
    x = np.zeros(int(SR * 1.0))
    for i in range(15):
        s = sine(1800, .03) * .2; o = int(i * .06 * SR); x[o:o + len(s)] += s
    return x
def S_message(): x = np.zeros(int(SR * .5)); a = sine(1568, .12) * expdec(int(SR * .12), .05) * .4; b = sine(2093, .2) * expdec(int(SR * .2), .07) * .4; x[:len(a)] += a; o = int(.1 * SR); x[o:o + len(b)] += b; return x
def S_wobble(): d = .7; tt = t_(d); return np.sin(2 * np.pi * (200 + 60 * np.sin(2 * np.pi * 7 * tt)) * tt) * env(int(SR * d), .02, .6, 0) * .3
def S_unroll(): d = 1.1; n = int(SR * d); return lp(noise(n), 1800) * (0.5 + .5 * (np.sin(2 * np.pi * 22 * t_(d)) > 0)) * env(n, .02, 1, .2, .1) * .4
def S_camera(): x = np.zeros(int(SR * .3)); a = S_tap() * 1.5; x[:len(a)] += a; o = int(.08 * SR); b = hp(noise(int(SR * .1)), 3000) * expdec(int(SR * .1), .03) * .5; x[o:o + len(b)] += b; return x
def S_gulp(): d = .35; return sweep(500, 120, d, .5) * env(int(SR * d), .01, .3, 0) * .45
def S_fanfare():
    x = np.zeros(int(SR * 1.5))
    for i, m in enumerate([67, 72, 76, 79]): dd = .25 if i < 3 else .9; s = lp(saw(mtof(m), dd) * .4 + saw(mtof(m) * 1.005, dd) * .3, 3000) * env(int(SR * dd), .01, .1, .7, .1); o = int(i * .14 * SR); x[o:o + len(s)] += s
    return x * .6
SFX = {k[2:]: v for k, v in globals().items() if k.startswith("S_")}
_cache = {}
def sfx(name):
    if name not in _cache: _cache[name] = np.asarray(SFX[name](), dtype=float)
    return _cache[name]

# ── music ───────────────────────────────────────────────────────────────────
KEYS = {'C': 60, 'C#': 61, 'D': 62, 'Eb': 63, 'E': 64, 'F': 65, 'F#': 66, 'G': 67, 'A': 69, 'Bb': 70, 'B': 71}
MAJ, MIN, DOR = [0, 2, 4, 5, 7, 9, 11], [0, 2, 3, 5, 7, 8, 10], [0, 2, 3, 5, 7, 9, 10]
def chord(root, scale, deg, n=3, ext=False):
    idx = [deg, deg + 2, deg + 4] + ([deg + 6] if ext else [])
    return [root + scale[i % 7] + 12 * (i // 7) for i in idx]
def kick(): d = .35; n = int(SR * d); return sweep(150, 45, d, .25) * expdec(n, .09)
def snare(): d = .2; n = int(SR * d); return (hp(noise(n), 1200) * .7 + sine(190, d) * .3) * expdec(n, .05)
def clap(): d = .18; n = int(SR * d); x = hp(noise(n), 900) * expdec(n, .04); return x * (1 + .5 * (np.arange(n) < SR * .02))
def hat(open_=False): d = .25 if open_ else .05; n = int(SR * d); return hp(noise(n), 7000) * expdec(n, .08 if open_ else .012) * .35
def shaker(): d = .08; n = int(SR * d); return hp(noise(n), 5000) * np.sin(np.linspace(0, np.pi, n)) * .15
def tom(f=110): d = .3; n = int(SR * d); return sweep(f * 1.5, f, d, .3) * expdec(n, .1)
def epiano(m, d): f = mtof(m); n = int(SR * d); return (sine(f, d) + .25 * sine(f * 2, d) + .12 * sine(f * 7.01, d) * expdec(n, .05)) * expdec(n, .7) * .5
def marimba(m, d=.5): f = mtof(m); n = int(SR * d); return (sine(f, d) + .3 * sine(f * 4, d) * expdec(n, .03)) * expdec(n, .18) * .5
def bell(m, d=.8): f = mtof(m); n = int(SR * d); return (sine(f, d) + .4 * sine(f * 2.76, d) + .2 * sine(f * 5.4, d)) * expdec(n, .3) * .3
def synpluck(m, d=.3): f = mtof(m); n = int(SR * d); return lp(saw(f, d) + saw(f * 1.006, d), 2500) * expdec(n, .09) * .3
def bassnote(m, d, kind='sine'):
    f = mtof(m); n = int(SR * d)
    x = sine(f, d) + (.3 * tri(f * 2, d) if kind == 'slap' else .15 * sine(f * 2, d))
    if kind == 'saw': x = lp(saw(f, d) + saw(f * 1.01, d), 600)
    return x * env(n, .005, d * .6, .5, .04) * .55
def padchord(ms, d):
    n = int(SR * d); x = np.zeros(n)
    for m in ms: f = mtof(m); x += saw(f, d) + saw(f * 1.004, d)
    return lp(x, 1200) * env(n, .4, .5, .8, .5) * .08

STYLES = {  # bpm/key come from the video meta; these describe arrangement
  'pop':       dict(scale=MAJ, prog=[0, 4, 5, 3], drums='four', lead='synpluck', arp=16, bass='sine', padded=True),
  'dombra':    dict(scale=DOR, prog=[0, 0, 6, 3], drums='dabyl', lead='dombra', bass=None),
  'funk':      dict(scale=MIN, prog=[0, 3, 0, 4], drums='funk', lead='stab', bass='slap', swing=.08),
  'electro':   dict(scale=MIN, prog=[0, 5, 2, 6], drums='four', lead='synpluck', arp=8, bass='saw', padded=True),
  'lofi':      dict(scale=MAJ, prog=[0, 5, 1, 4], drums='lofi', lead='marimba', arp=8, bass='sine', ext=True, swing=.12, vinyl=True),
  'acoustic':  dict(scale=MAJ, prog=[0, 4, 5, 3], drums='light', lead='guitar', bass='sine'),
  'chill':     dict(scale=MAJ, prog=[0, 3, 5, 4], drums='lofi', lead='epiano', bass='sine', ext=True),
  'lofinight': dict(scale=MAJ, prog=[0, 5, 3, 4], drums='lofi', lead='epiano', bass='sine', ext=True, swing=.14, vinyl=True),
  'brightpop': dict(scale=MAJ, prog=[0, 3, 4, 0], drums='four', lead='marimba', arp=16, bass='sine'),
  'energetic': dict(scale=MAJ, prog=[0, 4, 5, 3], drums='drive', lead='synpluck', arp=16, bass='saw', padded=True),
  'sea':       dict(scale=MAJ, prog=[0, 3, 0, 4], drums='light', lead='uke', bass='sine', waves=True),
}
def place(buf, x, t, g=1.):
    o = int(t * SR)
    if o >= len(buf): return
    k = min(len(x), len(buf) - o); x = x[:k].copy(); f = min(220, k // 4)
    if f > 0: x[-f:] *= np.linspace(1, 0, f)  # de-click: every note ends at zero
    buf[o:o + k] += x * g

def music(style, bpm, key, dur):
    st = STYLES[style]; root = KEYS[key] - 12 if KEYS[key] > 64 else KEYS[key]
    n = int(SR * (dur + 1)); L = np.zeros(n); D = np.zeros(n); B = np.zeros(n)
    beat = 60 / bpm; bar = beat * 4; sw = st.get('swing', 0)
    nb = int(dur / bar) + 2
    for b in range(nb):
        t0 = b * bar; deg = st['prog'][b % 4]; ch = chord(root, st['scale'], deg, ext=st.get('ext'))
        # drums
        for s in range(16):
            ts = t0 + s * beat / 4 + (sw * beat / 4 if s % 2 else 0)
            dr = st['drums']
            if dr in ('four', 'drive'):
                if s % 4 == 0: place(D, kick(), ts, .9)
                if s in (4, 12): place(D, clap() if dr == 'four' else snare(), ts, .55)
                if s % 2 == 0: place(D, hat(s % 4 == 2 and dr == 'four'), ts, .35)
                if dr == 'drive' and s % 2: place(D, hat(), ts, .2)
            elif dr == 'funk':
                if s in (0, 3, 8, 10): place(D, kick(), ts, .8)
                if s in (4, 12): place(D, clap(), ts, .6)
                place(D, hat(), ts, .22 if s % 2 else .32)
            elif dr == 'lofi':
                if s in (0, 7, 10): place(D, kick(), ts, .7)
                if s in (4, 12): place(D, snare(), ts, .35)
                if s % 2 == 0: place(D, hat(), ts, .18)
            elif dr == 'light':
                if s in (0, 8): place(D, kick(), ts, .5)
                if s % 2 == 0: place(D, shaker(), ts, .5)
            elif dr == 'dabyl':
                if s in (0, 6, 8, 14): place(D, tom(90 if s in (0, 8) else 130), ts, .55)
                if s % 2: place(D, shaker(), ts, .35)
        # bass
        if st.get('bass'):
            kind = st['bass']; bm = ch[0] - 12
            pattern = [0, 6, 8, 11, 14] if kind == 'slap' else ([0, 4, 8, 12] if kind == 'saw' else [0, 8])
            for s in pattern: place(B, bassnote(bm + (12 if (kind == 'slap' and s == 11) else 0), beat * (1 if kind != 'sine' else 1.8), kind), t0 + s * beat / 4, .9)
        # pad
        if st.get('padded'): place(L, padchord(ch, bar), t0, 1.)
        # lead / harmony
        ld = st['lead']
        if ld in ('synpluck', 'marimba'):
            step = 16 // st.get('arp', 8); notes = ch + [ch[0] + 12]
            for i, s in enumerate(range(0, 16, step)):
                m = notes[(i * (1 if b % 2 == 0 else 3)) % len(notes)] + 12
                place(L, synpluck(m) if ld == 'synpluck' else marimba(m), t0 + s * beat / 4 + (sw * beat / 4 if s % 2 else 0), .55 if ld == 'synpluck' else .7)
        elif ld == 'epiano':
            for m in ch: place(L, epiano(m + 12, bar), t0, .55)
            if b % 2: place(L, bell(ch[-1] + 24), t0 + beat * 2.5, .5)
        elif ld == 'stab':
            for s in (2, 9):
                x = sum(lp(saw(mtof(m + 12), .12), 3000) for m in ch) * env(int(SR * .12), .005, .1, 0) * .12; place(L, x, t0 + s * beat / 4)
        elif ld in ('guitar', 'uke', 'dombra'):
            pat = {'guitar': [0, 3, 4, 6, 8, 11, 12, 14], 'uke': [0, 2, 4, 6, 8, 10, 12, 14], 'dombra': [0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, 15]}[ld]
            for s in pat:
                ts = t0 + s * beat / 4
                if ld == 'dombra':  # two-string: drone (root/5th) + melody tone from pentatonic
                    drone = [ch[0] + 12, ch[0] + 19]; mel = root + 24 + [0, 3, 5, 7, 10][(b * 3 + s) % 5]
                    for j, m in enumerate(drone + ([mel] if s % 4 == 0 else [])): place(L, ks(mtof(m), .45, .6, .993), ts + j * .006, .35)
                else:
                    down = s % 4 == 0; ms = (ch + [ch[0] + 12]) if down else ch[1:]
                    for j, m in enumerate(ms): place(L, ks(mtof(m + (12 if ld == 'uke' else 0)), .6, .5 if ld == 'guitar' else .7, .994), ts + j * .012, .28)
    x = L * .9 + D * .8 + B * .9
    if st.get('vinyl'): x += lp(noise(n), 3000) * .01 + (rng.random(n) > .9995) * noise(n) * .2
    if st.get('waves'): tt = np.arange(n) / SR; x += lp(noise(n), 500) * (0.5 + .5 * np.sin(2 * np.pi * tt / 5)) * .12
    x = x[:int(SR * dur)]
    fade = int(SR * 1.0); x[-fade:] *= np.linspace(1, 0, fade)
    x[:int(SR * .05)] *= np.linspace(0, 1, int(SR * .05))
    return x / (np.max(np.abs(x)) + 1e-9) * .8

def write(path, x):
    x = np.tanh(x * 1.1) / np.tanh(1.1)
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    st = np.stack([pcm, pcm], axis=1)
    with wave.open(str(path), 'wb') as w: w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(st.tobytes())

def build(vid):
    meta = json.loads((OUT / vid / f"{vid}.meta.json").read_text())
    dur = meta['duration']; m = meta['music']; n = int(SR * dur)
    mus = music(m['style'], m['bpm'], m['key'], dur)
    fx = np.zeros(n)
    for t, name, g in meta['sfx']: place(fx, sfx(name), t, .55 * g)
    fx = fx / max(1., np.max(np.abs(fx)) / .9)
    write(OUT / vid / "music.wav", mus); write(OUT / vid / "sfx.wav", fx)
    mus_gain = .55 if meta.get('noVoice') else .42
    write(OUT / vid / "mix.wav", mus * mus_gain + fx * .85)
    print(f"audio {vid}: {dur}s, style={m['style']}, {len(meta['sfx'])} sfx")

if __name__ == '__main__':
    ids = sys.argv[1:] or sorted(p.name for p in OUT.iterdir() if p.is_dir())
    missing = {n for i in ids for _, n, _ in json.loads((OUT / i / f"{i}.meta.json").read_text())['sfx']} - set(SFX)
    if missing: sys.exit(f"missing sfx: {missing}")
    for i in ids: build(i)
