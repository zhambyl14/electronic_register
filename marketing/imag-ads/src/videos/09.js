// 09 — First day at the register: search, categories, big tiles, quick fixes (convenience store)
function v09Store(c) {
  bgRoom(c, { wall: '#FFEDD5', wall2: '#FED7AA', floor: '#9CA3AF', floor2: 'rgba(255,255,255,.06)', horizon: 1320 });
  sign(c, 290, 200, 500, 120, '#EA580C', 'ДҮКЕН 24', '#fff', 72);
  shelf(c, 60, 640, 960, '#FB923C'); for (let i = 0; i < 8; i++) rr(c, 100 + i * 115, 540, 80, 100, 10, ['#EF4444', '#3B82F6', '#22C55E', '#EAB308'][i % 4]);
  shelf(c, 60, 900, 960, '#FB923C'); for (let i = 0; i < 6; i++) bottle(c, 130 + i * 160, 890, .5, '#fff', ['#F97316', '#22C55E'][i % 2], '#FFEDD5');
}
const v09All = [['Қазы', '6500 ₸/шт', '#FECACA', 'm'], ['Қаймақ', '590 ₸/шт', '#E0F2FE', 'b'], ['Нан', '250 ₸/шт', '#FDE68A', 'br'], ['Кола', '600 ₸/шт', '#FEE2E2', 'c'], ['Сүт', '450 ₸/шт', '#DBEAFE', 'b'], ['Алма', '890 ₸/кг', '#DCFCE7', 'a']];
const v09Tile = ([n, p, col, k]) => ({ name: n, price: p, kg: p.includes('кг'), col, icon: (c, x, y, s) => k === 'm' ? meatCut(c, x, y, s / 120, '#9F1239') : k === 'br' ? bread(c, x, y, s / 110) : k === 'a' ? apple(c, x, y, s / 90) : k === 'c' ? bottle(c, x, y + 20, s / 200, '#7F1D1D', '#DC2626', '#FCA5A5') : bottle(c, x, y + 20, s / 200) });
VIDEOS['09'] = {
  id: '09', title: 'Кассадағы алғашқы күнім',
  feature: 'Түсінікті интерфейс: тауар іздеу, санат чиптері, сенсорлы үлкен плиткалар; себетте санын +/− өзгерту, тауарды × арқылы өшіру',
  setting: '«ДҮКЕН 24» шағын маркеті (қызғылт-сары)', cast: 'Жаңа кассир жігіт-студент (қызғылт-сары жейде)',
  problem: 'Жаңа қызметкер күрделі кассадан қорқады, кезек күтіп тұр',
  music: { style: 'energetic', bpm: 128, key: 'A', desc: 'Энергиялы инди-поп: жылдам хэт, сағат тықылы ырғаққа сіңген; соңында жеңіс фанфарасы.' },
  scenes: [
    { d: 3.8, shot: 'Хук. Жаңа кассир кассаның артында жұтынып тұр; алдында ұзын кезек, үстінде «7» санағышы; сағат тықылдайды.',
      text: '«Алғашқы күн. Кезекте — 7 адам.»', vo: 'Кассадағы алғашқы күнім. Кезекте — жеті адам.', voAt: .3,
      sfx: [[0.05, 'tick'], [0.5, 'tick'], [1.0, 'tick'], [1.5, 'tick'], [0.4, 'gulp', .7], [1.2, 'pop']], tr: 'cut',
      draw(c, t) {
        v09Store(c);
        for (let i = 6; i >= 0; i--) person(c, { x: 1000 - i * 0 - 60 * i, y: 1780 - i * 14, s: .7 - i * .02, top: ['#0EA5E9', '#A855F7', '#22C55E', '#F43F5E', '#64748B', '#EAB308', '#14B8A6'][i], hs: i % 2 ? 'long' : 'short', body: i % 2 ? 'f' : 'm', mouth: 'flat', brow: 'angry', flip: true, bob: Math.abs(osc(t + i * .17, 2, 4)) });
        person(c, who('rookie', { x: 260, y: 1390, s: 1.0, brow: 'worry', mouth: 'o', sweat: t, look: 10 })); counter(c, 0, 1200, 560, 400, '#C2410C', '#FFF7ED');
        T(c, { x: 820, y: 1060, s: ease(t, 1.1, 1.5, E.back) }, () => { circ(c, 0, 0, 90, BRAND.red); txt(c, '7', 0, 6, { size: 110, weight: 900, color: '#fff' }); });
        headline(c, 'Алғашқы күн. Кезекте — 7 адам.', 470, t, { size: 74, delay: .3, hl: ['7'], hlCol: BRAND.red, panel: 'rgba(255,255,255,.92)' });
      } },
    { d: 4.4, shot: 'Қиял көпіршігі: жүздеген ұсақ батырмасы бар күрделі ескі касса, қатарынан «ERROR» терезелері; кассир дірілдейді.',
      text: '«Күрделі болса — бітті…»', vo: 'Күрделі бағдарлама болса — бітті деп ойладым.', voAt: .2,
      sfx: [[0.3, 'whoosh'], [1.0, 'error', .6], [1.4, 'error', .6], [1.8, 'error', .6], [2.6, 'gulp', .6]], tr: 'wipe',
      draw(c, t) {
        bgFlat(c, '#1F2937');
        T(c, { x: 540, y: 800 }, () => { rr(c, -420, -330, 840, 640, 30, '#4B5563'); for (let i = 0; i < 140; i++) rr(c, -390 + (i % 14) * 56, -300 + Math.floor(i / 14) * 58, 44, 44, 6, ['#9CA3AF', '#6B7280', '#D1D5DB'][i % 3]); });
        for (let i = 0; i < 3; i++) { const p = ease(t, 1.0 + i * .4, 1.2 + i * .4, E.back); if (p > 0) T(c, { x: 400 + i * 120, y: 640 + i * 110, s: p }, () => { rr(c, -230, -90, 460, 180, 14, '#F3F4F6'); rr(c, -230, -90, 460, 44, 14, '#DC2626'); txt(c, 'ERROR 0x' + (51 + i * 17), 0, 20, { size: 40, weight: 800, mono: true, color: '#991B1B' }); }); }
        person(c, who('rookie', { x: 540 + osc(t, 12, 4), y: 1820, s: 1.0, brow: 'worry', mouth: 'sad', sweat: t * 1.5 }));
      } },
    { d: 7.6, shot: 'Шын iMag экраны: іздеу өрісіне «қа» теріледі → плиткалар «Қазы», «Қаймақ»-қа дейін сүзіледі; «Қазы» басылады; сосын «Нан» плиткасы, «+» батырмасымен 3 дана.',
      text: 'Іздеу • Санаттар • Үлкен батырмалар', vo: 'Ал iMag-та бәрі көз алдымда: іздеу, санаттар, үлкен батырмалар — басасың да, себетке түседі.', voAt: .2,
      sfx: [[0.6, 'type', .6], [0.8, 'type', .6], [1.1, 'whoosh', .4], [2.0, 'tap'], [2.1, 'pop'], [3.6, 'tap'], [3.7, 'pop'], [4.6, 'tap'], [5.1, 'tap'], [5.3, 'success', .6]], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#FFF7ED'); const q = t < .6 ? '' : t < .8 ? 'қ' : 'қа'; let tiles = v09All.map(v09Tile); let cat = 0;
        if (q === 'қа' && t < 3.0) tiles = tiles.filter(x => x.name.toLowerCase().startsWith('қа'));
        if (t >= 3.0) { tiles = [v09Tile(v09All[2])]; cat = 3; }
        const nan = t < 3.7 ? 0 : t < 4.6 ? 1 : t < 5.1 ? 2 : 3;
        const items = []; if (t > 2.1) items.push({ name: 'Қазы', qty: '1 шт', sum: '6 500' }); if (nan) items.push({ name: 'Нан', qty: nan + ' шт   −  +', sum: money(250 * nan) });
        T(c, { x: 540, y: 480 }, () => { rr(c, -500, 0, 1000, 640, 26, '#111827'); c.save(); c.translate(-480, 20); rr(c, 0, 0, 960, 600, 10); c.clip();
          posScreen(c, 960, 600, { search: t < 3.0 ? q : '', cats: ['Все', 'Мясо', 'Молочное', 'Хлеб'], cat, tiles, hl: (t > 1.8 && t < 2.4) || (t > 3.4 && t < 4) ? 0 : -1, hlp: 1, items, total: money((t > 2.1 ? 6500 : 0) + 250 * nan) }); c.restore(); });
        if (t > 1.7 && t < 2.3) finger(c, 330, 780, 1, P(t, 1.9, 2.05)); if (t > 3.3 && t < 3.9) finger(c, 330, 780, 1, P(t, 3.5, 3.65)); if (t > 4.4 && t < 5.4) finger(c, 905, 664, .8, (t > 4.55 && t < 4.7) || (t > 5.05 && t < 5.2) ? 1 : 0);
        person(c, who('rookie', { x: 540, y: 1900, s: .95, mouth: t > 2.2 ? 'big' : 'o', brow: 'up', look: 0 }));
        chip(c, 540, 300, 'Іздеу • Санаттар • Үлкен батырмалар', '#EA580C', '#fff', 38, P(t, 2.2, 2.6));
      } },
    { d: 5.0, shot: 'Қате: себетке артық «Кола» түсіп кетті → «×» басылады, жол сырғып жоғалады; «Нан 3 шт» → «−» → 2 шт.',
      text: '«×» — өшіру • «−/+» — санын өзгерту', vo: 'Қателессең — бір басумен өшіресің не санын өзгертесің.', voAt: .2,
      sfx: [[0.8, 'tap'], [0.9, 'swoosh_out'], [2.4, 'tap'], [2.5, 'pop', .6]], tr: 'slide',
      draw(c, t) {
        bgFlat(c, '#FFEDD5'); const gone = ease(t, .9, 1.3), n = t < 2.5 ? 3 : 2;
        T(c, { x: 140, y: 420 }, () => { rr(c, 0, 0, 800, 1000, 34, '#fff'); txt(c, 'Корзина', 40, 70, { size: 46, weight: 800, align: 'left' });
          const rows = [['Қазы', '1 шт', '6 500', 1], ['Кола', '1 шт', '600', 1 - gone], ['Нан', n + ' шт', money(250 * n), 1]]; let y = 140;
          rows.forEach(([nm, q, s, a], i) => { if (a <= .01) return; const hgt = 150 * (i === 1 ? a : 1); T(c, { x: (i === 1 ? -(1 - a) * 400 : 0), y: 0, a }, () => {
            rr(c, 30, y, 8, 110, 4, BRAND.pay); txt(c, nm, 60, y + 36, { size: 38, weight: 700, align: 'left' });
            rr(c, 60, y + 66, 46, 46, 10, i === 2 && t > 2.3 && t < 2.6 ? BRAND.blueL : '#F1F5F9'); txt(c, '−', 83, y + 89, { size: 34, weight: 700 }); txt(c, q, 160, y + 89, { size: 28, weight: 500, color: '#64748B' }); rr(c, 214, y + 66, 46, 46, 10, '#F1F5F9'); txt(c, '+', 237, y + 89, { size: 34, weight: 700 });
            txt(c, s + ' ₸', 700, y + 50, { size: 40, weight: 800, align: 'right' }); rr(c, 716, y + 70, 50, 50, 12, i === 1 && t > .7 && t < 1 ? '#FEE2E2' : '#F8FAFC'); txt(c, '×', 741, y + 95, { size: 36, weight: 700, color: '#ADB5BD' }); }); y += hgt; });
          txt(c, 'Итого', 40, 880, { size: 36, weight: 600, align: 'left', color: '#64748B' }); txt(c, money(6500 + 250 * n + 600 * (1 - gone)) + ' ₸', 760, 880, { size: 56, weight: 900, align: 'right' }); });
        if (t > .5 && t < 1.0) finger(c, 881, 690, .9, P(t, .65, .8)); if (t > 2.1 && t < 2.7) finger(c, 223, 1015, .9, P(t, 2.25, 2.4));
        headline(c, 'Қателессең — бір басу', 260, t, { size: 80, delay: .1, hl: ['бір'], hlCol: '#EA580C' });
      } },
    { d: 4.6, shot: 'Сағат 12:00. Кезек бос. Кассир кеудесін көтеріп күледі, кеудесінде «Алғашқы күн ✓» стикері. Конфетти.',
      text: '«12:00 — кезек бос»', vo: 'Түске дейін кезекті тауысып, өзім де таң қалдым.', voAt: .2,
      sfx: [[0.2, 'whoosh'], [0.8, 'fanfare', .7], [1.0, 'confetti']], tr: 'wipe',
      draw(c, t) {
        v09Store(c); person(c, who('rookie', { x: 420, y: 1700, s: 1.25, mouth: 'big', armL: 2.6, armR: 2.6, bob: -Math.abs(osc(t, 1.6, 14)) }));
        T(c, { x: 350, y: 1250, r: -.15, s: ease(t, 1.0, 1.3, E.back) }, () => { rr(c, -110, -40, 220, 80, 40, BRAND.green); txt(c, 'Алғашқы күн ✓', 0, 2, { size: 28, weight: 800, color: '#fff' }); });
        T(c, { x: 870, y: 1080 }, () => { circ(c, 0, 0, 110, '#fff'); circ(c, 0, 0, 98, '#FFEDD5'); line(c, 0, 0, 0, -70, '#1F2937', 10); line(c, 0, 0, 0, -50, '#DC2626', 12); txt(c, '12:00', 0, 150, { size: 44, weight: 800, color: '#7C2D12' }); });
        if (t > 1) confetti(c, t - 1, 9, ['#F97316', '#22C55E', '#3B82F6', '#EAB308'], 50, 540, 900);
      } },
    { d: 4.2, shot: 'Соңғы кадр.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Түсінікті касса — жылдам кезек»', vo: 'iMag Kassa. Әр теңге — есепте.', voAt: .6, noCap: true,
      sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', draw(c, t) { endcard(c, t, 'Түсінікті касса — жылдам кезек'); } },
  ],
};
