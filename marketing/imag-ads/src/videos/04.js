// 04 — NO VOICE-OVER: text-only story about returns (readable kinetic type + animated SFX)
const typeSfx = (t0, n, step = .055, g = .45) => Array.from({ length: n }, (_, i) => [+(t0 + i * step).toFixed(3), 'type', g]);
function typeText(c, s, x, y, t, t0, o = {}) { const n = Math.floor(clamp((t - t0) / (o.step || .055), 0, s.length)); const shown = s.slice(0, n);
  txt(c, shown, x, y, o); if (n < s.length && n > 0 && (t * 3) % 1 < .6) { const w = tw(c, shown, o.size || 48, o.weight || 700); const x0 = o.align === 'left' ? x + w + 6 : x + w / 2 + 6; rr(c, x0, y - (o.size || 48) * .45, 6, (o.size || 48) * .9, 3, o.color || BRAND.ink); } }
function v04Returns(c, w, h, st) { // the real "Возврат товара" screen
  rr(c, 0, 0, w, h, 20, '#F3F5F9'); c.fillStyle = '#fff'; c.fillRect(0, 0, w, 110); txt(c, 'Возврат товара', 36, 58, { size: 40, weight: 800, align: 'left' });
  rr(c, 30, 140, w - 60, 250, 22, '#fff'); txt(c, 'Найти чек', 60, 190, { size: 32, weight: 700, align: 'left' }); txt(c, 'Введите номер чека для оформления возврата', 60, 234, { size: 22, weight: 500, align: 'left', color: '#64748B' });
  rr(c, 60, 270, w - 340, 90, 16, '#F7F9FC'); txt(c, st.input || 'Номер чека (например: 42)', 86, 316, { size: st.input ? 38 : 26, weight: st.input ? 700 : 500, align: 'left', color: st.input ? BRAND.ink : '#A0AEC0' });
  rr(c, w - 260, 270, 200, 90, 16, st.findHl ? '#1D4ED8' : BRAND.blue); txt(c, 'Найти', w - 160, 316, { size: 32, weight: 700, color: '#fff' });
  if (st.error) { rr(c, 30, 420, w - 60, 150, 20, '#FEF2F2'); const ls = wrapLines(c, st.error, w - 140, 28, 600); ls.forEach((l, i) => txt(c, l, 60, 470 + i * 38, { size: 28, weight: 600, align: 'left', color: '#B91C1C' })); }
  if (st.sale) { const a = st.saleA ?? 1; T(c, { a, y: (1 - a) * 30 }, () => { rr(c, 30, 420, w - 60, 520, 22, '#fff');
    txt(c, 'Чек #0042', 60, 474, { size: 36, weight: 800, align: 'left' }); txt(c, 'Наличные', w - 60, 474, { size: 26, weight: 600, align: 'right', color: BRAND.pay });
    [['Сүт 2.5%', '1 шт × 520 ₸', '520 ₸', st.c1], ['Нан', '1 шт × 250 ₸', '250 ₸', false]].forEach(([n, q, s, on], i) => { const iy = 540 + i * 130;
      rr(c, 60, iy, 54, 54, 10, on ? BRAND.blue : '#fff'); if (!on) { c.strokeStyle = '#B9C2CF'; c.lineWidth = 3; rr(c, 60, iy, 54, 54, 10); c.stroke(); } else { c.beginPath(); c.moveTo(74, iy + 28); c.lineTo(84, iy + 38); c.lineTo(102, iy + 18); c.strokeStyle = '#fff'; c.lineWidth = 7; c.stroke(); }
      txt(c, n, 140, iy + 16, { size: 32, weight: 700, align: 'left' }); txt(c, q, 140, iy + 52, { size: 24, weight: 500, align: 'left', color: '#64748B' }); txt(c, s, w - 60, iy + 30, { size: 32, weight: 700, align: 'right' }); });
    rr(c, 60, 810, w - 120, 100, 18, st.c1 ? (st.btnHl ? '#B45309' : BRAND.amber) : '#CBD5E1'); txt(c, st.c1 ? 'Оформить возврат — 520 ₸' : 'Выберите товары', w / 2, 860, { size: 32, weight: 700, color: '#fff' }); }); }
}
VIDEOS['04'] = {
  id: '04', title: 'Чек №0042 (дауыссыз видео)', noVoice: true, subs: false,
  feature: 'Возврат: чекті нөмірі бойынша табу, тауарды белгілеу, соманы выручкадан автоматты шегеру; бір чекке қайта возврат жасауға тыйым',
  setting: 'Шағын азық-түлік дүкені (күлгін-лаванда түстері)', cast: 'Дүкен иесі әйел (көзілдірік, түйілген шаш), жас жігіт клиент (қызғылт-сары футболка)',
  problem: 'Тауар қайтарылғанда дәптер ақтару, кассадан ақша алу, кешкі есептің шатасуы',
  music: { style: 'lofi', bpm: 96, key: 'C', desc: 'Ойнақы маримба + лоу-фай барабан. Диктор жоқ — әр сөз шыққанда «тық», «поп», «вжух» эффектілері ырғақпен дәл келеді.' },
  scenes: [
    { d: 3.2, shot: 'Хук. Есік қоңырауы «дың». Қою күлгін фонда үлкен сөздер бірінен соң бірі соғылып шығады; чек белгішесі дірілдейді.',
      text: '«Клиент қайтып келді.»', sfx: [[0.0, 'doorbell'], [0.35, 'thud'], [0.6, 'thud'], [0.85, 'thud'], [1.6, 'shake', .6]], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#2E1065'); for (let i = 0; i < 6; i++) circ(c, (i * 230) % W, 300 + i * 260, 120, 'rgba(167,139,250,.08)');
        headline(c, 'Клиент қайтып келді.', 760, t, { size: 120, delay: .3, step: .25, color: '#fff', hl: ['қайтып'], hlCol: '#FBBF24' });
        T(c, { x: 540, y: 1300, r: t > 1.5 ? osc(t, 6, .08) : 0, s: ease(t, 1.2, 1.5, E.back) }, () => { rr(c, -110, -150, 220, 300, 16, '#fff'); for (let i = 0; i < 6; i++) rr(c, -80, -110 + i * 40, i % 2 ? 120 : 160, 12, 6, '#C4B5FD'); });
      } },
    { d: 4.4, shot: 'Дүкен. Сатушы сөре артында; жігіт бір қолында сүт бөтелкесі, бір қолында чек. Үстінде «Қолында — чек №0042», жігіттің сөз көпіршігі «Сүт ашып кетіпті...».',
      text: '«Қолында — чек №0042» • «Сүт ашып кетіпті...»', sfx: [[0.2, 'whoosh'], ...typeSfx(.5, 20), [2.0, 'pop'], ...typeSfx(2.2, 19, .05, .35)], tr: 'wipe',
      draw(c, t) {
        bgRoom(c, { wall: '#EDE9FE', wall2: '#DDD6FE', floor: '#C4B5FD', horizon: 1300 }); sign(c, 280, 380, 520, 110, '#7C3AED', 'АЗЫҚ-ТҮЛІК', '#fff', 56);
        shelf(c, 60, 640, 960, '#A78BFA'); for (let i = 0; i < 7; i++) bottle(c, 120 + i * 140, 630, .55, '#fff', ['#3B82F6', '#EF4444', '#22C55E'][i % 3], '#DDD6FE');
        person(c, who('grocer', { x: 300, y: 1390, s: 1.0, brow: 'up', mouth: 'o', look: 10 })); counter(c, 0, 1200, 600, 400, '#6D28D9', '#F5F3FF');
        person(c, who('guy', { x: 820, y: 1720, s: 1.05, armL: .45, armR: .45, mouth: 'sad', brow: 'worry', look: -10, holdL: () => bottle(c, 0, -10, .45, '#fff', '#3B82F6', '#BFDBFE'), holdR: () => rr(c, -30, -70, 60, 90, 6, '#fff') }));
        rr(c, 60, 140, 960, 120, 30, '#fff'); typeText(c, 'Қолында — чек №0042', 540, 202, t, .5, { size: 64, weight: 900 });
        bubble(c, 800, 900, 'Сүт ашып кетіпті...', { size: 46, p: ease(t, 2.0, 2.3), dir: -1, maxW: 520 });
      } },
    { d: 4.4, shot: '«Бұрын» тізімі: үш жол машинкамен басылады, әрқайсысының алдына қызыл ✗ соғылады.',
      text: '«Бұрын:» ✗ Дәптерді ақтару ✗ Кассадан ақша алу ✗ Кешке есеп шатасады',
      sfx: [[0.1, 'whoosh'], ...typeSfx(.4, 15, .04), [1.1, 'buzz', .5], ...typeSfx(1.4, 17, .04), [2.1, 'buzz', .5], ...typeSfx(2.4, 20, .04), [3.2, 'buzz', .5]], tr: 'slide',
      draw(c, t) {
        bgFlat(c, '#FFF7ED'); txt(c, 'Бұрын:', 100, 420, { size: 100, weight: 900, align: 'left', color: '#9A3412', alpha: ease(t, .1, .4) });
        ['Дәптерді ақтару', 'Кассадан ақша алу', 'Кешке есеп шатасады'].forEach((s, i) => { const y = 700 + i * 260;
          cross(c, 170, y, .9, ease(t, 1.1 + i, 1.3 + i)); typeText(c, s, 260, y, t, .4 + i, { size: 64, weight: 800, align: 'left', step: .04 }); });
        notebook(c, 760, 1600, .55, t);
      } },
    { d: 5.8, shot: 'iMag «Возврат товара» экраны: «Номер чека» өрісіне 42 теріледі → «Найти» → чек #0042 тауарларымен шығады → «Сүт 2.5%» белгіленеді.',
      text: '«iMag: чек нөмірі → тауарды белгіле»', sfx: [[0.2, 'whoosh'], [1.0, 'type', .6], [1.25, 'type', .6], [1.9, 'tap'], [2.2, 'pop'], [3.6, 'tap'], [3.7, 'pop', .7]], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#EDE9FE');
        T(c, { x: 80, y: 520, s: 1 }, () => v04Returns(c, 920, 1000, { input: t > 1.25 ? '42' : t > 1.0 ? '4' : '', findHl: t > 1.9 && t < 2.1, sale: t > 2.2, saleA: ease(t, 2.2, 2.5), c1: t > 3.7 }));
        if (t > 1.7 && t < 2.2) finger(c, 900, 900, 1, P(t, 1.85, 2.0)); if (t > 3.4 && t < 4) finger(c, 190, 1150, 1, P(t, 3.55, 3.7));
        headline(c, 'iMag: чек нөмірі → тауарды белгіле', 230, t, { size: 68, delay: .2, step: .08, hl: ['iMag:'], hlCol: '#7C3AED' });
      } },
    { d: 4.6, shot: '«Оформить возврат — 520 ₸» басылады → жасыл хабарлама «Возврат оформлен: 520 ₸ вычтено из выручки»; астында выручка санағышы 520-ға азаяды.',
      text: '«Сома выручкадан өзі шегеріледі»', sfx: [[0.4, 'tap'], [0.6, 'success'], [1.6, 'coin_down'], ...typeSfx(2.0, 18, .05, .35)], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#EDE9FE');
        T(c, { x: 80, y: 520 }, () => v04Returns(c, 920, 1000, { input: '42', sale: true, c1: true, btnHl: t > .4 && t < .6 }));
        if (t < .7) finger(c, 540, 1400, 1, P(t, .25, .4));
        toast(c, 'Возврат оформлен: 520 ₸ вычтено из выручки', P(t, .6, 4.6), BRAND.pay, 1660);
        T(c, { x: 540, y: 1820 }, () => { const v = Math.round(lerp(48300, 47780, ease(t, 1.4, 2.2))); txt(c, 'Выручка: ' + money(v) + ' ₸', 0, 0, { size: 44, weight: 800, color: '#4C1D95', alpha: ease(t, 1.2, 1.5) }); });
        rr(c, 60, 140, 960, 140, 30, '#fff'); typeText(c, 'Сома выручкадан өзі шегеріледі', 540, 212, t, 2.0, { size: 56, weight: 900, step: .05 });
      } },
    { d: 5.0, shot: 'Сол чекпен тағы біреу келеді: «42» → «Найти» → қызыл қате: «По чеку #0042 уже оформлен возврат. Повторный возврат невозможен.» Үстінде «Бір чекке — бір ғана возврат.» Құлып белгісі түседі.',
      text: '«Бір чекке — бір ғана возврат.» • «Алаяқтыққа жол жоқ.»', sfx: [[0.3, 'type', .6], [0.5, 'type', .6], [0.9, 'tap'], [1.0, 'error'], [1.6, 'lock'], ...typeSfx(2.0, 18, .05, .35)], tr: 'wipe',
      draw(c, t) {
        bgFlat(c, '#FEF2F2');
        T(c, { x: 80 + (t > 1 && t < 1.4 ? osc(t, 14, 10) : 0), y: 620 }, () => v04Returns(c, 920, 700, { input: t > .5 ? '42' : '4', findHl: t > .9 && t < 1.05, error: t > 1.0 ? 'По чеку #0042 уже оформлен возврат. Повторный возврат невозможен.' : '' }));
        const lk = ease(t, 1.5, 1.9, E.back); T(c, { x: 540, y: 1520, s: lk }, () => { rr(c, -80, -40, 160, 140, 24, BRAND.red); c.strokeStyle = BRAND.red; c.lineWidth = 22; c.beginPath(); c.arc(0, -40, 50, Math.PI, 0); c.stroke(); circ(c, 0, 20, 16, '#fff'); });
        headline(c, 'Бір чекке — бір ғана возврат.', 250, t, { size: 76, delay: .1, step: .08, hl: ['бір'], hlCol: BRAND.red });
        T(c, { x: 540, y: 1800 }, () => typeText(c, 'Алаяқтыққа жол жоқ.', 0, 0, t, 2.0, { size: 60, weight: 900, color: '#7F1D1D' }));
      } },
    { d: 4.4, shot: 'Соңғы кадр (мәтінмен): логотип, атау, ұран.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Возврат — 3 қадамда»',
      sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', draw(c, t) { endcard(c, t, 'Возврат — 3 қадамда'); } },
  ],
};
