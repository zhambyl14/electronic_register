// node preview.mjs <id> t1 t2 ... -> out/<id>/sheet.png (contact sheet of given seconds)
import { createRequire } from 'node:module'; const { chromium } = createRequire(import.meta.url)('playwright');
import { execFileSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
const [id, ...ts] = process.argv.slice(2); const here = new URL('.', import.meta.url).pathname; const dir = `${here}../out/${id}/pv`; mkdirSync(dir, { recursive: true });
const b = await chromium.launch(); const p = await b.newPage({ viewport: { width: 1080, height: 1920 } }); const errs = []; p.on('pageerror', e => errs.push(String(e)));
await p.goto('file://' + `${here}../out/${id}/${id}.html`); await p.waitForFunction('window.ready===true', null, { timeout: 30000 });
const files = [];
for (const t of ts) { const f = Math.round(parseFloat(t) * 24) + 1; await p.evaluate(f => window.renderFrame(f), f); const fn = `${dir}/t${t}.png`; await p.screenshot({ path: fn }); files.push(fn); }
await b.close(); if (errs.length) { console.error(errs.join('\n')); process.exit(1); }
const n = files.length, cols = Math.min(n, 4), rows = Math.ceil(n / cols);
execFileSync('ffmpeg', ['-y', '-loglevel', 'error', ...files.flatMap(f => ['-i', f]), '-filter_complex', files.map((_, i) => `[${i}]scale=360:640[v${i}]`).join(';') + ';' + files.map((_, i) => `[v${i}]`).join('') + `xstack=inputs=${n}:layout=` + files.map((_, i) => `${(i % cols) * 360}_${Math.floor(i / cols) * 640}`).join('|') + (n < cols * rows ? ':fill=black' : ''), `${here}../out/${id}/sheet.png`]);
console.log('sheet ok');
