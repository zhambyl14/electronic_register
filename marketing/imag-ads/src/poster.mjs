// Overview poster: one representative frame from each video (out/overview.png)
import { execFileSync } from 'node:child_process';
const ROOT = new URL('..', import.meta.url).pathname;
const picks = [['00', 1.6], ['01', 30], ['02', 13], ['03', 16.5], ['04', 15], ['05', 11], ['06', 13], ['07', 1.8], ['08', 13.5], ['09', 13], ['10', 13]];
const files = picks.map(([id, t]) => { const f = `${ROOT}out/${id}/poster.png`;
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-ss', String(t), '-i', `${ROOT}out/${id}/iMag_${id}.mp4`, '-frames:v', '1', '-vf', `scale=360:640,drawtext=text='${id}':x=16:y=16:fontsize=40:fontcolor=white:box=1:boxcolor=0x0F172AAA:boxborderw=10`, f]); return f; });
const cols = 6, layout = files.map((_, i) => `${(i % cols) * 360}_${Math.floor(i / cols) * 640}`).join('|');
execFileSync('ffmpeg', ['-y', '-loglevel', 'error', ...files.flatMap(f => ['-i', f]), '-filter_complex', `xstack=inputs=${files.length}:layout=${layout}:fill=0x0F172A`, `${ROOT}out/overview.png`]);
console.log('out/overview.png');
