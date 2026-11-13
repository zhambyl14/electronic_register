/* iMag Kassa ad engine — deterministic Flat Vector / 2.5D canvas renderer.
 * Every frame is a pure function of time: renderFrame(f) can be called in any order.
 * Canvas: 1080x1920 (9:16), 24 fps. No network, no random without seed. */
'use strict';
const W = 1080, H = 1920, FPS = 24;
const FONT = 'Inter, "DejaVu Sans", sans-serif';
const BRAND = { blue: '#2563EB', blueD: '#1D4ED8', blueL: '#DBEAFE', green: '#22C55E', pay: '#10B981',
  amber: '#F59E0B', navy: '#0F172A', ink: '#1A2332', bg: '#F3F5F9', red: '#EF4444', white: '#FFFFFF' };

// ── math / easing ───────────────────────────────────────────────────────────
const clamp = (x, a = 0, b = 1) => Math.max(a, Math.min(b, x));
const lerp = (a, b, t) => a + (b - a) * t;
const P = (t, a, b) => clamp((t - a) / (b - a));
const E = {
  lin: t => t,
  out: t => 1 - Math.pow(1 - t, 3),
  in: t => t * t * t,
  io: t => (t < .5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2),
  back: t => { const c1 = 1.70158, c3 = c1 + 1; return 1 + c3 * Math.pow(t - 1, 3) + c1 * Math.pow(t - 1, 2); },
  el: t => (t === 0 || t === 1) ? t : Math.pow(2, -10 * t) * Math.sin((t * 10 - .75) * (2 * Math.PI / 3)) + 1,
};
const ease = (t, a, b, fn = E.out) => fn(P(t, a, b));
function rng(seed) { let s = (seed * 9301 + 49297) % 233280; return () => (s = (s * 9301 + 49297) % 233280) / 233280; }
const osc = (t, f = 1, a = 1, ph = 0) => Math.sin((t * f + ph) * Math.PI * 2) * a;
function shade(hex, k) { // k<0 darker, k>0 lighter
  const n = parseInt(hex.slice(1), 16); let r = n >> 16, g = (n >> 8) & 255, b = n & 255;
  const f = v => Math.round(k < 0 ? v * (1 + k) : v + (255 - v) * k);
  return '#' + ((1 << 24) + (f(r) << 16) + (f(g) << 8) + f(b)).toString(16).slice(1);
}
const money = v => { const s = Math.round(v * 100) / 100; const [i, d] = String(s).split('.');
  return i.replace(/\B(?=(\d{3})+(?!\d))/g, ' ') + (d ? '.' + d : ''); };

// ── primitives ──────────────────────────────────────────────────────────────
function rr(c, x, y, w, h, r, fill) {
  r = Math.min(r, w / 2, h / 2); c.beginPath(); c.moveTo(x + r, y); c.arcTo(x + w, y, x + w, y + h, r);
  c.arcTo(x + w, y + h, x, y + h, r); c.arcTo(x, y + h, x, y, r); c.arcTo(x, y, x + w, y, r); c.closePath();
  if (fill) { c.fillStyle = fill; c.fill(); }
}
function circ(c, x, y, r, fill) { c.beginPath(); c.arc(x, y, Math.max(0, r), 0, Math.PI * 2); if (fill) { c.fillStyle = fill; c.fill(); } }
function ell(c, x, y, rx, ry, fill) { c.beginPath(); c.ellipse(x, y, Math.max(0, rx), Math.max(0, ry), 0, 0, Math.PI * 2); if (fill) { c.fillStyle = fill; c.fill(); } }
function poly(c, pts, fill) { c.beginPath(); pts.forEach((p, i) => i ? c.lineTo(p[0], p[1]) : c.moveTo(p[0], p[1])); c.closePath(); if (fill) { c.fillStyle = fill; c.fill(); } }
function line(c, x1, y1, x2, y2, col, w = 6, cap = 'round') { c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.strokeStyle = col; c.lineWidth = w; c.lineCap = cap; c.stroke(); }
function txt(c, s, x, y, o = {}) {
  const { size = 48, weight = 700, color = BRAND.ink, align = 'center', base = 'middle', alpha = 1, mono = false, ls = 0 } = o;
  c.save(); c.globalAlpha *= alpha; c.font = `${weight} ${size}px ${mono ? '"JetBrains Mono", monospace' : FONT}`;
  c.fillStyle = color; c.textAlign = align; c.textBaseline = base;
  if (ls && 'letterSpacing' in c) c.letterSpacing = ls + 'px';
  c.fillText(s, x, y); c.restore();
}
function tw(c, s, size, weight = 700) { c.save(); c.font = `${weight} ${size}px ${FONT}`; const w = c.measureText(s).width; c.restore(); return w; }
function wrapLines(c, s, maxW, size, weight = 700) {
  const words = s.split(' '); const lines = []; let cur = '';
  for (const w of words) { const t = cur ? cur + ' ' + w : w; if (tw(c, t, size, weight) > maxW && cur) { lines.push(cur); cur = w; } else cur = t; }
  if (cur) lines.push(cur); return lines;
}
function T(c, o, fn) { // transform block
  c.save(); if (o.a !== undefined) c.globalAlpha *= clamp(o.a);
  c.translate(o.x || 0, o.y || 0); if (o.r) c.rotate(o.r); if (o.s !== undefined) c.scale(o.s, o.sy === undefined ? o.s : o.sy);
  fn(); c.restore();
}
function shadow(c, x, y, rx, a = .14) { ell(c, x, y, rx, rx * .16, `rgba(15,23,42,${a})`); }

// ── backgrounds ─────────────────────────────────────────────────────────────
function bgFlat(c, col) { c.fillStyle = col; c.fillRect(0, 0, W, H); }
function bgRoom(c, o) { // wall + floor + optional tiles/stripe
  const { wall, wall2, floor, floor2, horizon = 1240, tiles = false, stripe } = o;
  c.fillStyle = wall; c.fillRect(0, 0, W, horizon);
  if (wall2) { c.fillStyle = wall2; c.fillRect(0, horizon - 360, W, 360); }
  if (tiles) { c.fillStyle = 'rgba(255,255,255,.18)'; for (let x = 0; x < W; x += 90) c.fillRect(x, horizon - 360, 3, 360); for (let y = horizon - 360; y < horizon; y += 90) c.fillRect(0, y, W, 3); }
  if (stripe) { c.fillStyle = stripe; c.fillRect(0, horizon - 380, W, 22); }
  c.fillStyle = floor; c.fillRect(0, horizon, W, H - horizon);
  if (floor2) { c.fillStyle = floor2; for (let i = 0; i < 9; i++) poly(c, [[i * 140 - 40, horizon], [i * 140 + 30, horizon], [i * 220 - 300 + 120, H], [i * 220 - 300, H]], floor2); }
}
function sign(c, x, y, w, h, bg, text, col = '#fff', size = 70) {
  shadow(c, x + w / 2, y + h + 26, w * .4, .08); rr(c, x, y + 10, w, h, 22, shade(bg, -.25)); rr(c, x, y, w, h, 22, bg);
  txt(c, text, x + w / 2, y + h / 2 + 2, { size, weight: 800, color: col, ls: 4 });
}
function windowPane(c, x, y, w, h, sky = '#BFE3FF') {
  rr(c, x - 14, y - 14, w + 28, h + 28, 18, '#FFFFFF'); rr(c, x, y, w, h, 8, sky);
  poly(c, [[x + w * .15, y + h], [x + w * .55, y], [x + w * .75, y], [x + w * .35, y + h]], 'rgba(255,255,255,.35)');
  c.fillStyle = '#FFFFFF'; c.fillRect(x + w / 2 - 6, y, 12, h);
}
function counter(c, x, y, w, h, col, top) {
  rr(c, x, y, w, 34, 10, top || shade(col, .35)); c.fillStyle = col; c.fillRect(x + 12, y + 30, w - 24, h);
  c.fillStyle = shade(col, -.15); c.fillRect(x + 12, y + 30, w - 24, 26);
  c.fillStyle = shade(col, -.08); for (let i = 1; i < 4; i++) c.fillRect(x + 12 + (w - 24) * i / 4 - 3, y + 70, 6, h - 60);
}
function shelf(c, x, y, w, col = '#E2E8F0') { rr(c, x, y, w, 20, 6, col); c.fillStyle = shade(col, -.2); c.fillRect(x + 6, y + 20, w - 12, 8); }
function grain(c) {
  if (!grain.p) { const g = document.createElement('canvas'); g.width = g.height = 256; const gc = g.getContext('2d'); const r = rng(7);
    const im = gc.createImageData(256, 256); for (let i = 0; i < im.data.length; i += 4) { const v = r() * 255; im.data[i] = im.data[i + 1] = im.data[i + 2] = v; im.data[i + 3] = 14; }
    gc.putImageData(im, 0, 0); grain.p = c.createPattern(g, 'repeat'); }
  c.save(); c.globalCompositeOperation = 'overlay'; c.fillStyle = grain.p; c.fillRect(0, 0, W, H); c.restore();
}
function confetti(c, t, seed, cols, n = 40, x0 = 540, y0 = 700) {
  const r = rng(seed); for (let i = 0; i < n; i++) {
    const a = r() * Math.PI * 2, v = 300 + r() * 700, col = cols[i % cols.length], sz = 10 + r() * 14, sp = r() * 8;
    const x = x0 + Math.cos(a) * v * t, y = y0 + Math.sin(a) * v * t + 900 * t * t;
    T(c, { x, y, r: sp * t, a: 1 - P(t, .7, 1.2) }, () => rr(c, -sz / 2, -sz / 4, sz, sz / 2, 2, col));
  }
}

// ── characters (flat vector, 2-3 planes, no outlines) ───────────────────────
function person(c, o) {
  const s = o.s || 1, bw = o.body === 'stocky' ? 230 : o.body === 'f' ? 160 : o.body === 'kid' ? 120 : 180;
  const skin = o.skin || '#E8B48C', skinSh = shade(skin, -.12), top = o.top || '#3B82F6', topSh = shade(top, -.18);
  const hair = o.hair || '#2A1A12', bob = o.bob || 0;
  c.save(); c.translate(o.x, o.y + bob); c.scale(s * (o.flip ? -1 : 1), s); if (o.lean) c.rotate(o.lean);
  const kid = o.body === 'kid'; const legH = kid ? 150 : 200, torsoT = kid ? -330 : -410;
  shadow(c, 0, 0, bw * .7, .12);
  // legs
  const pants = o.pants || '#334155';
  rr(c, -bw * .36, -legH - 10, bw * .32, legH, 16, pants); rr(c, bw * .04, -legH - 10, bw * .32, legH, 16, shade(pants, -.1));
  ell(c, -bw * .2, -8, bw * .22, 16, o.shoes || '#1F2937'); ell(c, bw * .2, -8, bw * .22, 16, o.shoes || '#1F2937');
  const hy0 = torsoT - 70, hr0 = kid ? 56 : 62;
  if (o.hs === 'long' || o.hs === 'pony2') rr(c, -hr0 - 26, hy0 - hr0 * .4, hr0 * 2 + 52, hr0 * 2.5, hr0 * .9, hair);
  // torso
  const tH = -torsoT - legH;
  rr(c, -bw / 2, torsoT, bw, tH + 20, o.body === 'f' ? 60 : 50, top);
  c.save(); rr(c, -bw / 2, torsoT, bw, tH + 20, 50); c.clip(); c.fillStyle = topSh; c.fillRect(bw * .18, torsoT, bw, tH + 30); c.restore();
  if (o.apron) { const ap = o.apron; rr(c, -bw * .36, torsoT + 50, bw * .72, tH - 10, 24, ap.col || '#fff');
    if (ap.stripe) { c.fillStyle = ap.stripe; c.fillRect(-bw * .36, torsoT + 120, bw * .72, 14); }
    c.fillStyle = shade(ap.col || '#fff', -.08); c.fillRect(bw * .1, torsoT + 50, bw * .26, tH - 10);
    rr(c, -bw * .2, torsoT + tH - 90, bw * .4, 50, 10, shade(ap.col || '#fff', -.05)); }
  if (o.hoodie) { rr(c, -46, torsoT - 8, 92, 40, 20, topSh); line(c, -16, torsoT + 30, -18, torsoT + 90, '#fff', 5); line(c, 16, torsoT + 30, 18, torsoT + 90, '#fff', 5); }
  if (o.collar) poly(c, [[-34, torsoT], [0, torsoT + 46], [34, torsoT], [0, torsoT + 14]], o.collar);
  if (o.logo) T(c, { x: -bw * .2, y: torsoT + 70, s: .3 }, () => logo(c, 0, 0, 100));
  // arms
  const arm = (side, ang, holdFn) => {
    c.save(); c.translate(side * (bw / 2 - 14), torsoT + 30); c.rotate(-side * (ang || 0));
    rr(c, -22, -10, 44, kid ? 150 : 190, 22, side > 0 ? topSh : top);
    circ(c, 0, kid ? 150 : 192, 24, side > 0 ? skinSh : skin);
    if (holdFn) { c.translate(0, kid ? 150 : 192); c.rotate(side * (ang || 0)); holdFn(); }
    c.restore();
  };
  arm(-1, o.armL, o.holdL); arm(1, o.armR, o.holdR);
  // neck + head
  const hy = torsoT - 70, hr = kid ? 56 : 62;
  rr(c, -20, torsoT - 30, 40, 40, 10, skinSh);
  if (o.hat === 'scarf') { ell(c, 0, hy + 6, hr + 22, hr + 26, o.scarf || '#9333EA'); poly(c, [[-30, hy + 60], [30, hy + 60], [0, hy + 120]], shade(o.scarf || '#9333EA', -.15)); }
  circ(c, -hr + 2, hy + 4, 13, skinSh); circ(c, hr - 2, hy + 4, 13, skinSh);
  circ(c, 0, hy, hr, skin);
  c.save(); circ(c, 0, hy, hr); c.clip(); c.fillStyle = skinSh; c.fillRect(hr * .45, hy - hr, hr, hr * 2); c.restore();
  // hair
  if (o.hat !== 'scarf') {
    if (o.hs === 'short' || !o.hs) { c.beginPath(); c.arc(0, hy - 4, hr + 4, Math.PI * 1.02, Math.PI * 1.98); c.closePath(); c.fillStyle = hair; c.fill(); rr(c, -hr - 4, hy - 30, 20, 40, 8, hair); rr(c, hr - 16, hy - 30, 20, 40, 8, hair); }
    if (o.hs === 'long' || o.hs === 'pony' || o.hs === 'bun' || o.hs === 'pony2') { c.beginPath(); c.arc(0, hy - 18, hr + 4, Math.PI * .98, Math.PI * 2.02); c.closePath(); c.fillStyle = hair; c.fill(); poly(c, [[-hr - 4, hy - 16], [-6, hy - hr - 10], [-hr + 34, hy - 26]], hair); rr(c, -hr - 6, hy - 30, 18, 50, 8, hair); rr(c, hr - 12, hy - 30, 18, 50, 8, hair); }
    if (o.hs === 'pony') { ell(c, hr + 14, hy - 10, 22, 50, hair); }
    if (o.hs === 'bun') { circ(c, 0, hy - hr - 18, 30, hair); }
    if (o.hs === 'curly') { for (let i = 0; i < 9; i++) { const a = Math.PI * (1.0 + i / 8); circ(c, Math.cos(a) * (hr + 2), hy - 6 + Math.sin(a) * (hr + 2), 24, hair); } }
    if (o.hs === 'bald') { }
  }
  if (o.hat === 'takiya') { c.beginPath(); c.arc(0, hy - 18, hr * .85, Math.PI, Math.PI * 2); c.closePath(); c.fillStyle = o.hatCol || '#1E293B'; c.fill();
    for (let i = -2; i <= 2; i++) circ(c, i * 18, hy - 40, 5, '#F8D57E'); }
  if (o.hat === 'baker') { rr(c, -hr + 6, hy - hr - 70, hr * 2 - 12, 90, 30, '#FFFFFF'); rr(c, -hr, hy - hr + 4, hr * 2, 26, 10, '#F1F5F9'); }
  if (o.hat === 'beanie') { c.beginPath(); c.arc(0, hy - 10, hr + 6, Math.PI, Math.PI * 2); c.closePath(); c.fillStyle = o.hatCol || '#0EA5E9'; c.fill(); rr(c, -hr - 8, hy - 24, hr * 2 + 16, 26, 12, shade(o.hatCol || '#0EA5E9', -.15)); circ(c, 0, hy - hr - 18, 14, shade(o.hatCol || '#0EA5E9', .2)); }
  if (o.hat === 'cap') { c.beginPath(); c.arc(0, hy - 12, hr + 2, Math.PI, Math.PI * 2); c.closePath(); c.fillStyle = o.hatCol || '#F97316'; c.fill(); rr(c, -10, hy - 22, hr + 40, 16, 8, shade(o.hatCol || '#F97316', -.2)); }
  if (o.hat === 'cookcap') { rr(c, -hr - 2, hy - hr - 6, hr * 2 + 4, 40, 16, o.hatCol || '#FFFFFF'); }
  // face
  const ex = o.look || 0, blink = o.blink;
  [-1, 1].forEach(sd => {
    if (blink) line(c, sd * 22 - 8 + ex, hy - 2, sd * 22 + 8 + ex, hy - 2, '#1F2937', 5);
    else { circ(c, sd * 22 + ex, hy - 2, 8, '#1F2937'); circ(c, sd * 22 + ex + 2, hy - 5, 2.5, '#fff'); }
    const by = hy - 24 - (o.brow === 'up' ? 6 : 0);
    if (o.brow === 'angry') line(c, sd * 32, by - 6, sd * 12, by + 4, hair, 6); else line(c, sd * 32, by, sd * 12, by - (o.brow === 'worry' ? -4 : 2), hair, 6);
  });
  if (o.glasses) { c.strokeStyle = '#111827'; c.lineWidth = 4; c.beginPath(); c.arc(-22, hy - 2, 17, 0, 7); c.stroke(); c.beginPath(); c.arc(22, hy - 2, 17, 0, 7); c.stroke(); line(c, -5, hy - 4, 5, hy - 4, '#111827', 4); }
  circ(c, -34, hy + 16, 10, 'rgba(244,114,182,.25)'); circ(c, 34, hy + 16, 10, 'rgba(244,114,182,.25)');
  const m = o.mouth || 'smile', my = hy + 30;
  if (m === 'smile') { c.beginPath(); c.arc(0, my - 8, 16, .15 * Math.PI, .85 * Math.PI); c.strokeStyle = '#7C2D12'; c.lineWidth = 5; c.lineCap = 'round'; c.stroke(); }
  if (m === 'big') { c.beginPath(); c.arc(0, my - 6, 18, 0, Math.PI); c.closePath(); c.fillStyle = '#7C2D12'; c.fill(); c.beginPath(); c.arc(0, my - 6, 18, 0, Math.PI); c.clip && 0; rr(c, -12, my - 6, 24, 7, 3, '#fff'); }
  if (m === 'open') ell(c, 0, my, 10, 13, '#7C2D12');
  if (m === 'flat') line(c, -12, my, 12, my, '#7C2D12', 5);
  if (m === 'sad') { c.beginPath(); c.arc(0, my + 12, 14, 1.2 * Math.PI, 1.8 * Math.PI); c.strokeStyle = '#7C2D12'; c.lineWidth = 5; c.stroke(); }
  if (m === 'o') circ(c, 0, my, 8, '#7C2D12');
  if (o.mustache) { ell(c, -14, my - 14, 18, 8, hair); ell(c, 14, my - 14, 18, 8, hair); }
  if (o.beard) { c.save(); c.beginPath(); c.arc(0, hy + 6, hr + 2, .05 * Math.PI, .95 * Math.PI); c.closePath(); c.fillStyle = hair; c.fill(); c.restore(); if (m === 'smile' || m === 'big') { c.beginPath(); c.arc(0, my - 8, 14, .15 * Math.PI, .85 * Math.PI); c.strokeStyle = '#fff'; c.lineWidth = 4; c.stroke(); } }
  if (o.sweat) { const sy = hy - 30 + (o.sweat % 1) * 40; poly(c, [[hr - 4, sy - 16], [hr + 8, sy + 4], [hr - 16, sy + 4]], '#7DD3FC'); circ(c, hr - 4, sy + 6, 12, '#7DD3FC'); }
  if (o.flour) circ(c, -30, hy + 22, 8, 'rgba(255,255,255,.9)');
  c.restore();
}

// ── brand ───────────────────────────────────────────────────────────────────
function logo(c, x, y, size) { // blue squircle, white "m", green dot (from assets/images/logo.png)
  const s = size / 100; c.save(); c.translate(x, y); c.scale(s, s);
  rr(c, -50, -50, 100, 100, 26, BRAND.blue); poly(c, [[-50, 20], [50, -50], [50, 50], [-50, 50]], 'rgba(29,78,216,.45)');
  c.strokeStyle = '#fff'; c.lineWidth = 9; c.lineCap = 'round'; c.lineJoin = 'round';
  c.beginPath(); c.moveTo(-32, 22); c.lineTo(-32, -6); c.quadraticCurveTo(-32, -22, -17, -22); c.quadraticCurveTo(-8, -22, -8, -6); c.lineTo(-8, 22);
  c.moveTo(-8, -6); c.quadraticCurveTo(-8, -22, 7, -22); c.quadraticCurveTo(16, -22, 16, -6); c.lineTo(16, 22); c.stroke();
  circ(c, 30, -22, 8, BRAND.green); c.restore();
}

// ── devices & props ─────────────────────────────────────────────────────────
// iMag POS monoblock showing the real cashier layout: dark sidebar, product tiles, cart, green "К оплате"
function posScreen(c, w, h, st = {}) {
  rr(c, 0, 0, w, h, 6, '#F3F5F9');
  const sb = w * .14; c.fillStyle = BRAND.navy; c.fillRect(0, 0, sb, h);
  T(c, { x: sb / 2, y: h * .09, s: sb / 150 }, () => logo(c, 0, 0, 80));
  for (let i = 0; i < 5; i++) rr(c, sb * .2, h * (.2 + i * .12), sb * .6, h * .07, 6, i === (st.nav || 0) ? BRAND.blue : '#1E293B');
  const cartX = w * .64;
  // header & search
  rr(c, sb + w * .02, h * .04, cartX - sb - w * .04, h * .08, 8, '#fff');
  txt(c, st.search || 'Поиск товара...', sb + w * .04, h * .08, { size: h * .035, weight: 500, color: st.search ? BRAND.ink : '#A0AEC0', align: 'left' });
  // category chips
  const cats = st.cats || ['Все', 'Мясо', 'Молочное', 'Хлеб'];
  let cx = sb + w * .02; cats.forEach((k, i) => { const cw = tw(c, k, h * .03, 600) + w * .03; rr(c, cx, h * .145, cw, h * .06, 30, i === (st.cat || 0) ? BRAND.blue : '#E2E8F0');
    txt(c, k, cx + cw / 2, h * .175, { size: h * .03, weight: 600, color: i === (st.cat || 0) ? '#fff' : '#475569' }); cx += cw + w * .01; });
  // tiles
  const tiles = st.tiles || [];
  const cols = 3, tW = (cartX - sb - w * .05) / cols - w * .01, tH = h * .26;
  tiles.forEach((tl, i) => { const tx = sb + w * .02 + (i % cols) * (tW + w * .012), ty = h * .24 + Math.floor(i / cols) * (tH + h * .025);
    const hl = st.hl === i; T(c, { x: tx + tW / 2, y: ty + tH / 2, s: hl ? 1 + .06 * (st.hlp || 1) : 1 }, () => {
      rr(c, -tW / 2, -tH / 2, tW, tH, 8, hl ? '#EFF6FF' : '#fff'); if (hl) { c.strokeStyle = BRAND.blue; c.lineWidth = 3; rr(c, -tW / 2, -tH / 2, tW, tH, 8); c.stroke(); }
      rr(c, -tW / 2 + 6, -tH / 2 + 6, tW - 12, tH * .45, 6, tl.col || '#FDE68A'); if (tl.icon) tl.icon(c, 0, -tH / 2 + 6 + tH * .225, tH * .35);
      txt(c, tl.name, -tW / 2 + 10, tH * .07, { size: h * .03, weight: 700, align: 'left' });
      txt(c, tl.price, -tW / 2 + 10, tH * .24, { size: h * .026, weight: 600, align: 'left', color: tl.kg ? '#B45309' : '#047857' });
      rr(c, tW / 2 - 40, tH * .3, 32, h * .035, 4, tl.kg ? '#FEF3C7' : '#D1FAE5'); txt(c, tl.kg ? 'кг' : 'шт', tW / 2 - 24, tH * .3 + h * .0175, { size: h * .022, weight: 600, color: tl.kg ? '#92400E' : '#065F46' });
    }); });
  // cart
  c.fillStyle = '#fff'; c.fillRect(cartX, 0, w - cartX, h);
  txt(c, 'Корзина', cartX + w * .02, h * .07, { size: h * .04, weight: 700, align: 'left' });
  if (st.scaleKg !== undefined) { rr(c, cartX + w * .2, h * .035, w * .14, h * .07, 8, '#0F172A'); txt(c, st.scaleKg.toFixed(3) + ' кг', cartX + w * .27, h * .07, { size: h * .032, weight: 700, mono: true, color: '#34D399' }); }
  (st.items || []).forEach((it, i) => { const iy = h * .14 + i * h * .11, a = it.a === undefined ? 1 : it.a;
    T(c, { x: 0, y: (1 - a) * 20, a }, () => {
      rr(c, cartX + w * .015, iy, 6, h * .08, 3, it.kg ? BRAND.amber : BRAND.pay);
      txt(c, it.name, cartX + w * .03, iy + h * .025, { size: h * .03, weight: 600, align: 'left' });
      txt(c, it.qty, cartX + w * .03, iy + h * .062, { size: h * .025, weight: 500, align: 'left', color: '#64748B' });
      txt(c, it.sum + ' ₸', w - w * .02, iy + h * .04, { size: h * .032, weight: 700, align: 'right' }); }); });
  c.fillStyle = '#EDF0F4'; c.fillRect(cartX, h * .72, w - cartX, 2);
  txt(c, 'Итого', cartX + w * .02, h * .78, { size: h * .032, weight: 600, align: 'left', color: '#64748B' });
  txt(c, (st.total || '0') + ' ₸', w - w * .02, h * .78, { size: h * .05, weight: 800, align: 'right' });
  rr(c, cartX + w * .02, h * .84, w - cartX - w * .04, h * .11, 10, st.payHl ? '#059669' : BRAND.pay);
  txt(c, 'К оплате', cartX + (w - cartX) / 2, h * .895, { size: h * .04, weight: 700, color: '#fff' });
  if (st.overlay) st.overlay(c, w, h);
}
function monoblock(c, x, y, s, st) { // stand + bezel; (x,y) = bottom-center of stand
  c.save(); c.translate(x, y); c.scale(s, s);
  shadow(c, 0, 0, 200, .18); rr(c, -150, -24, 300, 24, 12, '#334155'); rr(c, -36, -140, 72, 120, 10, '#475569');
  rr(c, -330, -560, 660, 440, 26, '#111827'); rr(c, -330, -560, 660, 440, 26); c.save(); c.clip(); c.fillStyle = '#1F2937'; c.fillRect(150, -560, 200, 440); c.restore();
  c.save(); c.translate(-308, -538); rr(c, 0, 0, 616, 396, 8); c.clip(); posScreen(c, 616, 396, st); c.restore();
  c.restore();
}
function scaleDev(c, x, y, s, kg, on = true, item) {
  c.save(); c.translate(x, y); c.scale(s, s);
  shadow(c, 0, 0, 170, .16); rr(c, -170, -70, 340, 70, 18, '#CBD5E1'); rr(c, -170, -70, 340, 22, 12, '#E2E8F0');
  rr(c, -190, -110, 380, 40, 14, '#94A3B8'); rr(c, -190, -110, 380, 16, 8, '#CBD5E1');
  rr(c, -110, -52, 220, 46, 8, '#0F172A'); txt(c, on ? kg.toFixed(3) : '-.---', 30, -29, { size: 34, weight: 700, mono: true, color: on ? '#34D399' : '#475569' }); txt(c, 'кг', 86, -29, { size: 20, weight: 600, color: '#64748B' });
  if (item) item(c, 0, -120);
  c.restore();
}
function labelScale(c, x, y, s, kg, printing = 0) { // label-printing scale (Rongta-like, generic)
  c.save(); c.translate(x, y); c.scale(s, s);
  shadow(c, 0, 0, 200, .16); rr(c, -200, -90, 400, 90, 18, '#E2E8F0'); rr(c, -210, -128, 420, 40, 12, '#94A3B8');
  rr(c, 60, -330, 150, 250, 18, '#CBD5E1'); rr(c, 76, -310, 118, 70, 8, '#0F172A'); txt(c, kg.toFixed(3), 135, -275, { size: 26, weight: 700, mono: true, color: '#34D399' });
  for (let i = 0; i < 6; i++) rr(c, 82 + (i % 3) * 38, -225 + Math.floor(i / 3) * 34, 30, 26, 5, '#F8FAFC');
  rr(c, 90, -150, 90, 10, 4, '#334155');
  if (printing > 0) { const lh = 90 * printing; rr(c, 92, -150, 86, lh, 4, '#fff'); for (let i = 0; i < 4; i++) if (lh > 20 + i * 16) rr(c, 100, -136 + i * 16, 50 + (i % 2) * 20, 6, 2, '#94A3B8'); }
  c.restore();
}
function barcode(c, x, y, w, h, seed = 3, digits) {
  const r = rng(seed); rr(c, x - 10, y - 10, w + 20, h + (digits ? 60 : 20), 8, '#fff'); let px = x;
  while (px < x + w) { const bw = 3 + Math.floor(r() * 3) * 3; if (r() > .4) { c.fillStyle = '#111827'; c.fillRect(px, y, bw, h); } px += bw + 3; }
  if (digits) txt(c, digits, x + w / 2, y + h + 26, { size: 30, weight: 600, mono: true, ls: 4 });
}
function scanner(c, x, y, s, ang = 0, beam = 0) {
  c.save(); c.translate(x, y); c.rotate(ang); c.scale(s, s);
  if (beam > 0) { c.save(); c.globalAlpha = beam; poly(c, [[-40, -10], [40, -10], [140, -260], [-140, -260]], 'rgba(239,68,68,.22)'); line(c, -150, -262, 150, -262, '#EF4444', 6); c.restore(); }
  rr(c, -50, -30, 100, 70, 24, '#1F2937'); rr(c, -26, 20, 52, 150, 22, '#374151'); rr(c, -44, -26, 88, 18, 8, '#EF4444'); rr(c, -14, 40, 28, 30, 8, '#F59E0B');
  c.restore();
}
function receiptPaper(c, x, y, w, lines, prog = 1, opts = {}) { // lines: [{t, b, r, c}] ; grows downward
  const lh = opts.lh || 40, pad = 30, full = pad * 2 + lines.length * lh, h = full * prog;
  c.save(); c.translate(x, y); shadow(c, 0, h + 30, w * .45, .1);
  c.beginPath(); c.moveTo(-w / 2, 0); c.lineTo(w / 2, 0); c.lineTo(w / 2, h);
  for (let i = 0; i <= 12; i++) c.lineTo(w / 2 - (w / 12) * i, h + (i % 2 ? 14 : 0)); c.closePath(); c.fillStyle = '#FFFFFF'; c.fill();
  c.save(); c.beginPath(); c.rect(-w / 2, 0, w, h); c.clip();
  lines.forEach((L, i) => { const ly = pad + i * lh + lh / 2; if (L.sep) { c.setLineDash([8, 8]); line(c, -w / 2 + 24, ly, w / 2 - 24, ly, '#CBD5E1', 3, 'butt'); c.setLineDash([]); return; }
    if (L.t) txt(c, L.t, L.center ? 0 : -w / 2 + 28, ly, { size: L.size || 26, weight: L.b ? 800 : 500, mono: true, align: L.center ? 'center' : 'left', color: L.c || '#111827' });
    if (L.r) txt(c, L.r, w / 2 - 28, ly, { size: L.size || 26, weight: L.b ? 800 : 500, mono: true, align: 'right', color: L.c || '#111827' }); });
  c.restore(); c.restore();
}
function printerDev(c, x, y, s) { c.save(); c.translate(x, y); c.scale(s, s); shadow(c, 0, 0, 120, .16);
  rr(c, -120, -150, 240, 150, 28, '#E5E7EB'); rr(c, -120, -150, 240, 60, 26, '#F3F4F6'); rr(c, -80, -150, 160, 12, 6, '#374151'); circ(c, 88, -40, 10, BRAND.green); c.restore(); }
function phone(c, x, y, s, screen, o = {}) { // (x,y)=center
  const w = 420, h = 860; c.save(); c.translate(x, y); if (o.r) c.rotate(o.r); c.scale(s, s);
  shadow(c, 0, h / 2 + 30, w * .5, .12); rr(c, -w / 2, -h / 2, w, h, 60, '#0B1220'); rr(c, -w / 2 + 6, -h / 2 + 6, w - 12, h - 12, 56, '#1E293B');
  c.save(); rr(c, -w / 2 + 18, -h / 2 + 18, w - 36, h - 36, 46); c.clip(); c.translate(-w / 2 + 18, -h / 2 + 18); screen(c, w - 36, h - 36); c.restore();
  rr(c, -60, -h / 2 + 30, 120, 30, 15, '#0B1220'); c.restore();
}
function reportsUI(c, w, h, d = {}, t = 1) { // real "Отчёты" screen content (labels as in the app)
  c.fillStyle = '#F3F5F9'; c.fillRect(0, 0, w, h); c.fillStyle = '#fff'; c.fillRect(0, 0, w, 130);
  txt(c, '9:41', 40, 50, { size: 22, weight: 600, align: 'left' }); txt(c, 'Отчёты', 30, 100, { size: 36, weight: 800, align: 'left' });
  const per = ['Сегодня', 'Вчера', 'Неделя', 'Месяц']; let px = 18;
  per.forEach((p, i) => { const pw = tw(c, p, 20, 600) + 26; rr(c, px, 148, pw, 44, 22, i === (d.period || 0) ? BRAND.blue : '#E2E8F0'); txt(c, p, px + pw / 2, 170, { size: 20, weight: 600, color: i === (d.period || 0) ? '#fff' : '#475569' }); px += pw + 8; });
  const cards = [['Выручка', (d.rev || '0') + ' ₸', BRAND.pay], ['Чеков', d.n || '0', BRAND.blue], ['Средний чек', (d.avg || '0') + ' ₸', '#8B5CF6'], ['Нал / Карта', d.split || '0 / 0 ₸', BRAND.amber]];
  cards.forEach((k, i) => { const cx = 18 + (i % 2) * ((w - 46) / 2 + 10), cy = 212 + Math.floor(i / 2) * 150, cw = (w - 46) / 2;
    T(c, { x: 0, y: (1 - ease(t, i * .08, i * .08 + .3)) * 30, a: ease(t, i * .08, i * .08 + .3) }, () => {
      rr(c, cx, cy, cw, 136, 18, '#fff'); rr(c, cx + 16, cy + 18, 40, 40, 12, k[2] + '22'); circ(c, cx + 36, cy + 38, 9, k[2]);
      txt(c, k[1], cx + 16, cy + 88, { size: k[1].length > 11 ? 21 : 27, weight: 800, align: 'left' }); txt(c, k[0], cx + 16, cy + 118, { size: 18, weight: 500, align: 'left', color: '#64748B' }); }); });
  rr(c, 18, 522, w - 36, h - 540, 18, '#fff'); txt(c, 'График продаж', 36, 560, { size: 22, weight: 700, align: 'left' });
  txt(c, d.byHour ? 'По часам' : 'По дням', w - 36, 560, { size: 18, weight: 600, align: 'right', color: BRAND.blue });
  const bars = d.bars || [3, 4, 6, 5, 7, 6, 9, 8, 5, 4]; const bx = 40, bw = (w - 80) / bars.length, base = h - 60, mh = h - 680;
  bars.forEach((v, i) => { const bh = mh * v / 10 * ease(t, .2 + i * .03, .6 + i * .03); rr(c, bx + i * bw + 5, base - bh, bw - 10, bh, 6, i === d.peak ? BRAND.amber : BRAND.blue);
    if (d.labels) txt(c, d.labels[i], bx + i * bw + bw / 2, base + 24, { size: 15, weight: 500, color: '#94A3B8' }); });
}
function notebook(c, x, y, s, t = 0) {
  c.save(); c.translate(x, y); c.scale(s, s); c.rotate(-.06); shadow(c, 0, 210, 220, .12);
  rr(c, -230, -200, 460, 400, 14, '#FEF9C3'); c.fillStyle = '#93C5FD'; for (let i = 0; i < 9; i++) c.fillRect(-210, -150 + i * 40, 420, 2);
  c.fillStyle = '#FCA5A5'; c.fillRect(-160, -200, 3, 400);
  const r = rng(11); for (let i = 0; i < 8; i++) { const ww = 120 + r() * 200; line(c, -140, -160 + i * 40, -140 + ww, -160 + i * 40 - 4 + r() * 8, '#1E3A8A', 4);
    if (i % 3 === 1) line(c, -150, -160 + i * 40, -110 + ww, -160 + i * 40, '#DC2626', 5); }
  txt(c, '?', 170, 120, { size: 90, weight: 800, color: '#DC2626' }); c.restore();
}
function calculator(c, x, y, s, disp = '0', err = false) { c.save(); c.translate(x, y); c.scale(s, s); shadow(c, 0, 170, 110, .12);
  rr(c, -110, -160, 220, 330, 24, '#334155'); rr(c, -90, -140, 180, 70, 10, err ? '#FECACA' : '#D9F99D'); txt(c, disp, 78, -105, { size: 34, weight: 700, mono: true, align: 'right', color: err ? '#B91C1C' : '#14532D' });
  for (let i = 0; i < 12; i++) rr(c, -90 + (i % 3) * 62, -50 + Math.floor(i / 3) * 52, 54, 42, 10, i === 11 ? BRAND.amber : '#64748B'); c.restore(); }
function banknote(c, x, y, s, r = 0, val = '5000') { T(c, { x, y, s, r }, () => { rr(c, -110, -55, 220, 110, 10, '#86EFAC'); rr(c, -96, -42, 192, 84, 6, '#4ADE80'); circ(c, 0, 0, 30, '#86EFAC'); txt(c, val, -60, -18, { size: 22, weight: 800, color: '#14532D' }); }); }
function bankCard(c, x, y, s, r = 0, col = '#6366F1') { T(c, { x, y, s, r }, () => { rr(c, -120, -76, 240, 152, 16, col); rr(c, -120, -40, 240, 26, 0, shade(col, -.3)); rr(c, -90, 10, 50, 36, 6, '#FDE68A'); }); }
function terminal(c, x, y, s) { T(c, { x, y, s }, () => { shadow(c, 0, 150, 80, .14); rr(c, -80, -150, 160, 300, 26, '#1F2937'); rr(c, -60, -126, 120, 90, 10, '#38BDF8'); for (let i = 0; i < 9; i++) rr(c, -56 + (i % 3) * 40, -20 + Math.floor(i / 3) * 40, 32, 30, 8, '#475569'); }); }
function custDisplay(c, x, y, s, items = [], total = null, shop = 'iMag Kassa') { // the real browser "Экран покупателя"
  c.save(); c.translate(x, y); c.scale(s, s); const w = 560, h = 380;
  rr(c, -w / 2 - 18, -h - 18, w + 36, h + 36, 22, '#111827'); rr(c, -26, 18, 52, 70, 6, '#374151'); rr(c, -100, 84, 200, 18, 8, '#334155');
  c.save(); rr(c, -w / 2, -h, w, h, 8); c.clip(); c.fillStyle = '#0F172A'; c.fillRect(-w / 2, -h, w, h); c.fillStyle = '#1E293B'; c.fillRect(-w / 2, -h, w, 54);
  txt(c, shop, 0, -h + 28, { size: 22, weight: 700, color: '#E2E8F0' });
  if (!items.length) { txt(c, 'Қош келдіңіз!', 0, -h / 2 - 10, { size: 50, weight: 800, color: '#fff' }); txt(c, 'Добро пожаловать!', 0, -h / 2 + 44, { size: 26, weight: 500, color: '#64748B' }); }
  items.forEach((it, i) => { const iy = -h + 76 + i * 50, a = it.a === undefined ? 1 : it.a; T(c, { x: (1 - a) * 40, a }, () => {
    txt(c, it.name, -w / 2 + 20, iy + 18, { size: 22, weight: 600, color: '#E2E8F0', align: 'left' }); txt(c, it.qty, 40, iy + 18, { size: 18, weight: 500, color: '#94A3B8' });
    txt(c, it.sum, w / 2 - 20, iy + 18, { size: 24, weight: 700, color: '#34D399', align: 'right' }); }); });
  if (total !== null) { c.fillStyle = '#059669'; c.fillRect(-w / 2, -96, w, 96); txt(c, 'ИТОГО', -w / 2 + 24, -48, { size: 28, weight: 600, color: 'rgba(255,255,255,.85)', align: 'left' }); txt(c, total + ' ₸', w / 2 - 24, -48, { size: 52, weight: 900, color: '#fff', align: 'right' }); }
  c.restore(); c.restore();
}
function vfd(c, x, y, s, l1, l2) { c.save(); c.translate(x, y); c.scale(s, s); rr(c, -230, -80, 460, 160, 18, '#1F2937'); rr(c, -36, 80, 72, 120, 8, '#374151');
  rr(c, -205, -58, 410, 116, 8, '#022C22'); txt(c, l1, -190, -22, { size: 30, weight: 600, mono: true, color: '#5EEAD4', align: 'left' }); txt(c, l2, -190, 26, { size: 30, weight: 600, mono: true, color: '#5EEAD4', align: 'left' }); c.restore(); }

// food props
function meatCut(c, x, y, s, col = '#DC2626') { T(c, { x, y, s }, () => { ell(c, 0, 0, 90, 56, col); ell(c, 10, -6, 66, 38, shade(col, .18)); ell(c, -40, 10, 26, 16, '#FDE2E2'); ell(c, 50, -20, 14, 10, '#FFF1F2'); }); }
function hangingMeat(c, x, y, s, t = 0) { T(c, { x, y, s, r: osc(t, .4, .03) }, () => { line(c, 0, -120, 0, -40, '#94A3B8', 6); c.beginPath(); c.arc(0, -40, 16, 0, Math.PI); c.strokeStyle = '#94A3B8'; c.lineWidth = 6; c.stroke();
  ell(c, 0, 60, 60, 100, '#B91C1C'); ell(c, 8, 50, 40, 74, '#DC2626'); ell(c, -10, 120, 20, 26, '#FECACA'); }); }
function fruitCrate(c, x, y, s, col, seed = 1) { T(c, { x, y, s }, () => { const r = rng(seed); for (let i = 0; i < 9; i++) circ(c, -110 + (i % 5) * 55 + (i > 4 ? 27 : 0), -30 - (i > 4 ? 40 : 0) + r() * 6, 30, i % 2 ? col : shade(col, -.12));
  rr(c, -150, -20, 300, 90, 10, '#B45309'); c.fillStyle = '#92400E'; c.fillRect(-150, 10, 300, 8); c.fillRect(-150, 40, 300, 8); }); }
function apple(c, x, y, s, col = '#EF4444') { T(c, { x, y, s }, () => { circ(c, -14, 0, 34, col); circ(c, 14, 0, 34, shade(col, -.1)); line(c, 0, -30, 6, -50, '#78350F', 6); ell(c, 18, -44, 14, 7, '#22C55E'); }); }
function bread(c, x, y, s, col = '#D97706') { T(c, { x, y, s }, () => { ell(c, 0, 0, 90, 44, col); ell(c, 0, -8, 76, 30, shade(col, .2)); for (let i = -1; i <= 1; i++) line(c, i * 34 - 10, -22, i * 34 + 10, 4, shade(col, -.2), 6); }); }
function bottle(c, x, y, s, col = '#FFFFFF', cap = '#3B82F6', label = '#60A5FA') { T(c, { x, y, s }, () => { rr(c, -34, -120, 68, 160, 20, col); rr(c, -20, -150, 40, 40, 10, col); rr(c, -22, -164, 44, 22, 6, cap); rr(c, -34, -70, 68, 50, 0, label); }); }
function fish(c, x, y, s, col = '#60A5FA') { T(c, { x, y, s }, () => { ell(c, 0, 0, 110, 44, col); poly(c, [[100, 0], [160, -40], [160, 40]], shade(col, -.15)); ell(c, -10, -10, 80, 22, shade(col, .2)); circ(c, -70, -8, 8, '#0F172A'); }); }
function cheese(c, x, y, s) { T(c, { x, y, s }, () => { poly(c, [[-90, 40], [90, 40], [90, -10], [-90, -40]], '#FCD34D'); poly(c, [[-90, -40], [90, -10], [60, -40]], '#FDE68A'); circ(c, -30, 10, 12, '#F59E0B'); circ(c, 40, 20, 9, '#F59E0B'); }); }
function jar(c, x, y, s, col) { T(c, { x, y, s }, () => { rr(c, -50, -110, 100, 130, 22, 'rgba(255,255,255,.7)'); const r = rng(5); for (let i = 0; i < 10; i++) circ(c, -30 + r() * 60, -20 - r() * 70, 13, i % 2 ? col : shade(col, -.2)); rr(c, -54, -126, 108, 24, 8, '#92400E'); }); }
function box(c, x, y, s, col = '#D6A15E') { T(c, { x, y, s }, () => { rr(c, -90, -140, 180, 140, 8, col); c.fillStyle = shade(col, -.15); c.fillRect(30, -140, 60, 140); rr(c, -20, -140, 40, 60, 0, shade(col, .25)); }); }

// ── UI overlays ─────────────────────────────────────────────────────────────
function bubble(c, x, y, text, o = {}) { // speech bubble anchored at tail point (x,y)
  const size = o.size || 40, pad = 26, lines = wrapLines(c, text, o.maxW || 620, size, 700), lw = Math.max(...lines.map(l => tw(c, l, size, 700)));
  const bw = lw + pad * 2, bh = lines.length * size * 1.25 + pad * 1.6, dir = o.dir || 1; const bx = x - (dir > 0 ? 60 : bw - 60), by = y - bh - 34;
  const sc = o.p === undefined ? 1 : E.back(clamp(o.p)); if (sc <= 0) return;
  T(c, { x, y, s: sc }, () => { c.translate(-x, -y);
    rr(c, bx, by + 8, bw, bh, 30, 'rgba(15,23,42,.10)'); rr(c, bx, by, bw, bh, 30, o.bg || '#fff');
    poly(c, [[x - 18 * dir, by + bh - 2], [x + 22 * dir, by + bh - 2], [x, y]], o.bg || '#fff');
    lines.forEach((l, i) => txt(c, l, bx + bw / 2, by + pad * .8 + size * .62 + i * size * 1.25, { size, weight: 700, color: o.color || BRAND.ink })); });
}
function headline(c, text, y, t, o = {}) { // kinetic word-by-word title
  const size = o.size || 84, words = text.split(' '), maxW = o.maxW || 940, lines = wrapLines(c, text, maxW, size, 900);
  if (o.panel) { const pp = clamp((t - (o.delay || 0)) / .3), bw = Math.max(...lines.map(l => tw(c, l, size, 900))) + 70, bh = lines.length * size * 1.12 + 40;
    T(c, { a: pp * .92 }, () => rr(c, 540 - bw / 2, y - size * .62 - 20, bw, bh, 36, o.panel)); }
  let wi = 0; lines.forEach((ln, li) => { const ws = ln.split(' '); let total = tw(c, ln, size, 900), x = 540 - total / 2;
    ws.forEach(wd => { const d = (o.delay || 0) + wi * (o.step || .09), p = clamp((t - d) / .35), wwid = tw(c, wd + ' ', size, 900);
      if (p > 0) T(c, { x: x + tw(c, wd, size, 900) / 2, y: y + li * size * 1.12 + (1 - E.back(p)) * 40, a: p, s: .8 + .2 * E.back(p) }, () => {
        if (o.box) { const bw = tw(c, wd, size, 900) + 24; rr(c, -bw / 2, -size * .62, bw, size * 1.2, 14, o.box); }
        txt(c, wd, 0, 0, { size, weight: 900, color: (o.hl && o.hl.includes(wd)) ? (o.hlCol || BRAND.amber) : (o.color || BRAND.ink) }); });
      x += wwid; wi++; }); });
  return lines.length * size * 1.12;
}
function chip(c, x, y, text, bg, col = '#fff', size = 34, p = 1) { if (p <= 0) return; const w = tw(c, text, size, 700) + 50;
  T(c, { x, y, s: E.back(clamp(p)), a: clamp(p * 2) }, () => { rr(c, -w / 2, -size * .9, w, size * 1.8, size * .9, bg); txt(c, text, 0, 2, { size, weight: 700, color: col }); }); }
function toast(c, text, p, col = BRAND.pay, y = 1500) { if (p <= 0) return; const w = Math.min(980, tw(c, text, 34, 600) + 80);
  T(c, { x: 540, y: y + (1 - E.out(clamp(p * 3))) * 60, a: clamp(p * 4) }, () => { rr(c, -w / 2, -48, w, 96, 20, col); txt(c, text, 0, 2, { size: 34, weight: 600, color: '#fff' }); }); }
function check(c, x, y, s, p = 1, col = BRAND.pay) { if (p <= 0) return; T(c, { x, y, s: s * E.back(clamp(p)) }, () => { circ(c, 0, 0, 60, col); c.beginPath(); c.moveTo(-26, 2); c.lineTo(-6, 22); c.lineTo(28, -18); c.strokeStyle = '#fff'; c.lineWidth = 14; c.lineCap = 'round'; c.lineJoin = 'round'; c.stroke(); }); }
function cross(c, x, y, s, p = 1) { if (p <= 0) return; T(c, { x, y, s: s * E.back(clamp(p)) }, () => { circ(c, 0, 0, 60, BRAND.red); line(c, -22, -22, 22, 22, '#fff', 14); line(c, 22, -22, -22, 22, '#fff', 14); }); }
function finger(c, x, y, s = 1, press = 0) { T(c, { x, y, s: s * (1 - press * .12) }, () => { rr(c, -22, -10, 44, 120, 22, '#E8B48C'); rr(c, -40, 70, 80, 110, 34, '#E8B48C'); ell(c, 0, 2, 16, 12, '#F5D0B5'); if (press > .3) { c.globalAlpha = press; c.strokeStyle = 'rgba(37,99,235,.6)'; c.lineWidth = 6; c.beginPath(); c.arc(0, -10, 40 + press * 30, 0, 7); c.stroke(); } }); }
function commentCard(c, x, y, w, name, text, p = 1, likes = '') {
  if (p <= 0) return; const lines = wrapLines(c, text, w - 170, 40, 600), h = 120 + lines.length * 52;
  T(c, { x, y, s: .85 + .15 * E.back(clamp(p)), a: clamp(p * 3) }, () => {
    rr(c, -w / 2, -h / 2 + 10, w, h, 34, 'rgba(15,23,42,.12)'); rr(c, -w / 2, -h / 2, w, h, 34, '#fff');
    circ(c, -w / 2 + 70, -h / 2 + 70, 42, '#F472B6'); txt(c, name[0].toUpperCase(), -w / 2 + 70, -h / 2 + 72, { size: 40, weight: 800, color: '#fff' });
    txt(c, name, -w / 2 + 130, -h / 2 + 52, { size: 30, weight: 700, align: 'left', color: '#64748B' });
    lines.forEach((l, i) => txt(c, l, -w / 2 + 130, -h / 2 + 106 + i * 52, { size: 40, weight: 600, align: 'left' }));
    if (likes) { circ(c, w / 2 - 70, -h / 2 + 60, 22, '#FEE2E2'); txt(c, '♥', w / 2 - 70, -h / 2 + 62, { size: 28, color: BRAND.red }); txt(c, likes, w / 2 - 70, -h / 2 + 106, { size: 24, weight: 600, color: '#64748B' }); } });
}
function caption(c, text, p, y = 1600) { // subtitles for voice-over lines
  if (!text || p <= 0) return; const size = 46, lines = wrapLines(c, text, 900, size, 700);
  const a = clamp(Math.min(p * 6, (1 - p) * 8 + .0001)); const bw = Math.max(...lines.map(l => tw(c, l, size, 700))) + 60, bh = lines.length * size * 1.25 + 34;
  T(c, { a }, () => { rr(c, 540 - bw / 2, y - bh / 2, bw, bh, 24, 'rgba(15,23,42,.78)');
    lines.forEach((l, i) => txt(c, l, 540, y - bh / 2 + 17 + size * .62 + i * size * 1.25, { size, weight: 700, color: '#fff' })); });
}
function endcard(c, lt, tagline, o = {}) {
  bgFlat(c, BRAND.blue); const r = rng(42);
  for (let i = 0; i < 7; i++) { const rad = 140 + r() * 260; circ(c, r() * W, r() * H, rad * (1 + .05 * Math.sin(lt * 2 + i)), i % 2 ? 'rgba(255,255,255,.05)' : 'rgba(29,78,216,.5)'); }
  const p = ease(lt, .1, .7, E.back); T(c, { x: 540, y: 720, s: p * 3.4, r: (1 - p) * -.5 }, () => logo(c, 0, 0, 100));
  txt(c, 'iMag Kassa', 540, 980, { size: 120, weight: 900, color: '#fff', alpha: ease(lt, .4, .8), ls: -2 });
  const sp = ease(lt, .7, 1.1); T(c, { x: 540, y: 1110 + (1 - sp) * 30, a: sp }, () => { const sw = tw(c, 'Әр теңге — есепте.', 64, 800) + 70; rr(c, -sw / 2, -52, sw, 104, 52, BRAND.green); txt(c, 'Әр теңге — есепте.', 0, 2, { size: 64, weight: 800, color: '#fff' }); });
  if (tagline) txt(c, tagline, 540, 1260, { size: 42, weight: 600, color: 'rgba(255,255,255,.9)', alpha: ease(lt, 1.0, 1.4) });
  txt(c, o.cta || 'Сұрағыңыз болса — комментке жазыңыз', 540, 1480, { size: 36, weight: 600, color: '#BFDBFE', alpha: ease(lt, 1.3, 1.7) });
}
function circleWipe(c, p, col, x = 540, y = 960) { if (p <= 0 || p >= 1) return; c.save(); c.beginPath(); c.arc(x, y, 1200 * E.io(p < .5 ? p * 2 : 2 - p * 2), 0, 7); c.fillStyle = col; c.fill(); c.restore(); }
function tag(c, x, y, text, bg = BRAND.navy, size = 30) { const w = tw(c, text, size, 700) + 40; rr(c, x, y - size * .8, w, size * 1.6, 12, bg); txt(c, text, x + w / 2, y + 1, { size, weight: 700, color: '#fff' }); return w; }
function cable(c, pts, col = '#334155', w = 10, glow = 0, gp = 0) { c.beginPath(); c.moveTo(pts[0][0], pts[0][1]); for (let i = 1; i < pts.length - 1; i++) { const mx = (pts[i][0] + pts[i + 1][0]) / 2, my = (pts[i][1] + pts[i + 1][1]) / 2; c.quadraticCurveTo(pts[i][0], pts[i][1], mx, my); } const L = pts[pts.length - 1]; c.lineTo(L[0], L[1]);
  c.strokeStyle = col; c.lineWidth = w; c.lineCap = 'round'; c.stroke(); if (glow > 0) { c.save(); c.setLineDash([30, 60]); c.lineDashOffset = -gp * 400; c.strokeStyle = `rgba(52,211,153,${glow})`; c.lineWidth = w * .6; c.stroke(); c.restore(); } }

// ── player ──────────────────────────────────────────────────────────────────
const VIDEOS = {};
function definePlayer(V) {
  const cv = document.getElementById('cv'), c = cv.getContext('2d');
  let t0 = 0; V.scenes.forEach(s => { s.t0 = t0; t0 += s.d; s.t1 = t0; }); V.duration = t0;
  const N = Math.round(V.duration * FPS);
  const off = document.createElement('canvas'); off.width = W; off.height = H; const oc = off.getContext('2d');
  function drawScene(ctx, s, T) { ctx.save(); ctx.clearRect(0, 0, W, H); s.draw(ctx, clamp(T - s.t0, 0, s.d), s.d, T); ctx.restore(); }
  window.renderFrame = f => {
    const T = Math.min((f - 1) / FPS, V.duration - 1e-6);
    let i = V.scenes.findIndex(s => T >= s.t0 && T < s.t1); if (i < 0) i = V.scenes.length - 1;
    const s = V.scenes[i]; drawScene(c, s, T);
    const tr = s.tr || 'wipe', td = s.td || .45, lt = T - s.t0;
    if (i > 0 && tr !== 'cut' && lt < td) { const prev = V.scenes[i - 1]; drawScene(oc, prev, prev.t1 - 1e-3); const p = E.io(lt / td);
      c.save();
      if (tr === 'wipe') { c.beginPath(); c.rect(0, 0, W, H); c.arc(s.wx || 540, s.wy || 960, 1300 * p, 0, Math.PI * 2, true); c.clip('evenodd'); c.drawImage(off, 0, 0); }
      if (tr === 'slide') { c.drawImage(off, -W * p, 0); c.globalAlpha = 1; }
      if (tr === 'up') { c.drawImage(off, 0, -H * p); }
      if (tr === 'fade') { c.globalAlpha = 1 - p; c.drawImage(off, 0, 0); }
      if (tr === 'zoom') { c.globalAlpha = 1 - p; c.translate(540, 960); c.scale(1 + p * .6, 1 + p * .6); c.drawImage(off, -540, -960); }
      c.restore();
      if (tr === 'slide') { c.save(); c.globalCompositeOperation = 'destination-over'; c.restore(); }
    }
    // voice-over subtitles
    if (V.subs !== false) for (const s2 of V.scenes) if (s2.vo && !s2.noCap) { const a = s2.t0 + (s2.voAt || .15), d = s2.voDur || Math.max(1.6, s2.vo.length / 13); if (T >= a && T < a + d + .25) caption(c, s2.vo, (T - a) / (d + .25), s2.capY || V.capY || 1630); }
    grain(c);
  };
  window.VIDEO_META = { id: V.id, duration: V.duration, frames: N };
  document.fonts.load('900 40px Inter').then(() => document.fonts.load('600 40px "JetBrains Mono"')).then(() => { window.ready = true; });
}
