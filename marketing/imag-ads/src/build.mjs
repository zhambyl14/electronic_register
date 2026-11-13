// Builds one self-contained HTML per video and exports audio/doc metadata as JSON.
import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs';
import vm from 'node:vm';
const here = new URL('.', import.meta.url).pathname;
const engine = readFileSync(here + 'engine.js', 'utf8'), cast = readFileSync(here + 'cast.js', 'utf8');
const ids = process.argv.slice(2).length ? process.argv.slice(2) : readdirSync(here + 'videos').map(f => f.replace('.js', '')).sort();
const all = {};
for (const id of ids) {
  const src = readFileSync(here + `videos/${id}.js`, 'utf8');
  const out = here + `../out/${id}`; mkdirSync(out, { recursive: true });
  writeFileSync(`${out}/${id}.html`, `<!DOCTYPE html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#000}canvas{display:block}</style></head>
<body><canvas id="cv" width="1080" height="1920"></canvas><script>${engine}\n${cast}\n${src}\ndefinePlayer(VIDEOS['${id}']);</script></body></html>`);
  const ctx = { console, Math }; vm.createContext(ctx); vm.runInContext(engine.replace(/^'use strict';/, '') + '\n' + cast + '\n' + src + '\nthis.VIDEOS=VIDEOS;', ctx);
  const V = ctx.VIDEOS[id]; let t0 = 0; const sfx = [], vo = [], scenes = [];
  for (const s of V.scenes) { for (const [t, n, g] of (s.sfx || [])) sfx.push([+(t0 + t).toFixed(3), n, g ?? 1]);
    if (s.vo) vo.push({ t: +(t0 + (s.voAt ?? .15)).toFixed(2), text: s.vo, slot: +(s.d - (s.voAt ?? .15)).toFixed(2), voice: s.voice || 'm' });
    scenes.push({ t0: +t0.toFixed(2), t1: +(t0 + s.d).toFixed(2), shot: s.shot, text: s.text, vo: s.vo || '', sfxNames: [...new Set((s.sfx || []).map(x => x[1]))] }); t0 += s.d; }
  const meta = { id, title: V.title, feature: V.feature, setting: V.setting, cast: V.cast, problem: V.problem, music: V.music, duration: +t0.toFixed(2), sfx, vo, scenes, noVoice: !!V.noVoice };
  writeFileSync(`${out}/${id}.meta.json`, JSON.stringify(meta, null, 1)); all[id] = meta;
  // speech-fit check: ~13 chars/s for Kazakh neural TTS at +8% rate
  for (const v of vo) { const need = v.text.length / 13; if (need > v.slot + .3) console.warn(`[${id}] VO may not fit (${need.toFixed(1)}s > ${v.slot}s): ${v.text}`); }
  console.log(`built ${id}: ${t0.toFixed(1)}s, ${V.scenes.length} scenes, ${sfx.length} sfx, ${vo.length} vo lines`);
}
writeFileSync(here + '../out/all_meta.json', JSON.stringify(all, null, 1));
