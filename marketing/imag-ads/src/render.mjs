// Fast deterministic renderer: renderFrame(f) -> canvas JPEG (q .95) -> ffmpeg pipe -> H.264 + AAC.
// Same contract as the animation-studio helper (frames 1..N, 24 fps), then verified with ffprobe.
// usage: node src/render.mjs <id> [<id> ...]
import { createRequire } from 'node:module';
import { spawn, spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, statSync } from 'node:fs';
const { chromium } = createRequire(import.meta.url)('playwright');
const ROOT = new URL('..', import.meta.url).pathname, FPS = 24;
const browser = await chromium.launch();
for (const id of process.argv.slice(2)) {
  const meta = JSON.parse(readFileSync(`${ROOT}out/${id}/${id}.meta.json`, 'utf8')), N = Math.round(meta.duration * FPS);
  const out = `${ROOT}out/${id}/iMag_${id}.mp4`, audio = `${ROOT}out/${id}/mix.wav`;
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } }); const errs = []; page.on('pageerror', e => errs.push(String(e)));
  await page.goto(`file://${ROOT}out/${id}/${id}.html`); await page.waitForFunction('window.ready===true', null, { timeout: 30000 });
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-c:v', 'mjpeg', '-framerate', String(FPS), '-i', '-', '-i', audio,
    '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k',
    '-t', String(N / FPS), '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
  const t0 = Date.now();
  for (let f = 1; f <= N; f++) {
    const b64 = await page.evaluate(f => { window.renderFrame(f); return document.getElementById('cv').toDataURL('image/jpeg', .95).split(',')[1]; }, f);
    if (errs.length) throw new Error(errs.join('\n'));
    if (!ff.stdin.write(Buffer.from(b64, 'base64'))) await new Promise(r => ff.stdin.once('drain', r));
  }
  ff.stdin.end(); await new Promise((ok, fail) => ff.on('close', c => c ? fail(new Error('ffmpeg ' + c)) : ok()));
  await page.close();
  // verify like the skill's contract: codec, size, fps, duration, audio
  const pr = JSON.parse(spawnSync('ffprobe', ['-v', 'error', '-show_streams', '-show_format', '-of', 'json', out], { encoding: 'utf8' }).stdout);
  const v = pr.streams.find(s => s.codec_type === 'video'), a = pr.streams.find(s => s.codec_type === 'audio'), dur = +pr.format.duration;
  const ok = v && v.codec_name === 'h264' && v.width === 1080 && v.height === 1920 && v.avg_frame_rate === '24/1' && a && Math.abs(dur - N / FPS) < .2 && statSync(out).size > 4096;
  const report = { id, output: out, frames: N, seconds: N / FPS, codec: v?.codec_name, size: `${v?.width}x${v?.height}`, fps: v?.avg_frame_rate, audio: a?.codec_name, duration: dur, bytes: statSync(out).size, verified: ok, render_s: (Date.now() - t0) / 1000 };
  writeFileSync(`${ROOT}out/${id}/render_report.json`, JSON.stringify(report, null, 1));
  console.log(`${ok ? 'VERIFIED' : 'FAILED'} ${id}: ${report.size} ${report.fps} ${dur.toFixed(2)}s h264+${a?.codec_name} ${(report.bytes / 1e6).toFixed(1)}MB in ${report.render_s.toFixed(0)}s`);
  if (!ok) process.exitCode = 1;
}
await browser.close();
