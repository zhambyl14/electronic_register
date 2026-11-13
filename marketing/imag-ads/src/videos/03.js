// 03 — Weighted label barcode (label-printing scale) scanned at checkout
function v03Market(c) {
  bgRoom(c, { wall: '#CCFBF1', wall2: '#99F6E4', floor: '#E2E8F0', floor2: 'rgba(148,163,184,.12)', horizon: 1320 });
  sign(c, 60, 230, 440, 110, '#0F766E', 'КУЛИНАРИЯ', '#fff', 54); sign(c, 600, 230, 420, 110, '#0369A1', 'КАССА', '#fff', 60);
  c.fillStyle = '#5EEAD4'; c.fillRect(530, 0, 10, 1320);
}
function v03Label(c, x, y, s, hl = -1) { // the printed label with the type-2 barcode
  T(c, { x, y, s }, () => { rr(c, -260, -170, 520, 340, 24, '#fff'); txt(c, 'СЫР', -220, -120, { size: 40, weight: 800, align: 'left' });
    txt(c, '0.165 кг', -220, -66, { size: 30, weight: 600, align: 'left', color: '#475569' }); txt(c, '4300 ₸/кг', 220, -66, { size: 30, weight: 600, align: 'right', color: '#475569' });
    txt(c, '709.50 ₸', 220, -118, { size: 44, weight: 800, align: 'right', color: BRAND.ink }); barcode(c, -200, -20, 400, 120, 9, '2000015709500'); });
}
VIDEOS['03'] = {
  id: '03', title: 'Бір «пик» — бәрі дайын',
  feature: 'Этикетка басатын таразының салмақ штрих-кодын (EAN-13, префикс 20–29) оқу: PLU бойынша тауар табылады, сома мен салмақ себетке автоматты түседі',
  setting: 'Супермаркет: кулинария бөлімі + касса (көгілдір-теңіз түсі)', cast: 'Кулинар (ақ қалпақ, сақал), кассир жігіт (бұйра шаш, көзілдірік)',
  problem: 'Кассир этикеткадағы кішкентай цифрларды қолмен тереді — баяу әрі қате',
  music: { style: 'electro', bpm: 124, key: 'F#', desc: 'Таза электро: пульсті синт-басс, “сканер” дыбысына синхрон ырғақ; шешім сәтінде ашық аккорд.' },
  scenes: [
    { d: 3.0, shot: 'Хук. Экстремал жақын план: этикеткадағы штрих-код; қызыл сканер сәулесі өтеді; «ПИК!» жарылысы; «0.165 кг» мен «709.5 ₸» ұшып шығады.',
      text: '«Бір «пик» — бәрі дайын»', vo: 'Бір «пик» — және бәрі дайын.', voAt: .9,
      sfx: [[0.55, 'scan'], [0.6, 'impact', .6], [1.0, 'pop'], [1.3, 'pop']], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#042F2E'); for (let i = 0; i < 12; i++) { c.fillStyle = 'rgba(94,234,212,.06)'; c.fillRect(0, i * 170, W, 2); }
        v03Label(c, 540, 1000, 1.7 + .1 * ease(t, 0, 3));
        const sy = lerp(760, 1240, ease(t, .1, .55)); if (t < .7) { c.save(); c.globalAlpha = .9; line(c, 60, sy, 1020, sy, '#EF4444', 10); c.globalAlpha = .25; c.fillStyle = '#EF4444'; c.fillRect(60, sy - 30, 960, 60); c.restore(); }
        const b = ease(t, .55, .8, E.back); if (b > 0) T(c, { x: 540, y: 560, s: b, r: -.08 }, () => { poly(c, Array.from({ length: 16 }, (_, i) => { const a = i / 16 * Math.PI * 2, r = i % 2 ? 150 : 230; return [Math.cos(a) * r * 1.3, Math.sin(a) * r * .8]; }), '#FACC15'); txt(c, 'ПИК!', 0, 6, { size: 110, weight: 900, color: '#B91C1C' }); });
        chip(c, 300, 1500, '0.165 кг', BRAND.amber, '#fff', 56, P(t, 1.0, 1.3)); chip(c, 780, 1500, '709.5 ₸', BRAND.pay, '#fff', 56, P(t, 1.3, 1.6));
        headline(c, 'Бір «пик» — бәрі дайын', 260, t, { size: 84, delay: 1.6, color: '#fff', hl: ['«пик»'], hlCol: '#FACC15' });
      } },
    { d: 6.8, shot: 'Супермаркет: сол жақта кулинар этикетка басатын таразыдан этикетка шығарады; оң жақта кассир жігіт кішкентай этикеткаға көзін қысып қарап, қолмен тереді; кезек ұзарады.',
      text: '«Қолмен теру = уақыт + қате»', vo: 'Кулинарияда таразы этикетка басады. Ал кассада оны қолмен теру — уақыт пен қате.', voAt: .2,
      sfx: [[0.6, 'print', .6], [2.8, 'type', .5], [3.1, 'type', .5], [3.4, 'type', .5], [3.7, 'type', .5], [4.3, 'buzz', .6], [5.0, 'tick'], [5.5, 'tick']], tr: 'wipe',
      draw(c, t) {
        v03Market(c);
        person(c, who('deli', { x: 260, y: 1360, s: .9, armR: .7, armL: .3, mouth: 'smile', look: 8 })); counter(c, 0, 1160, 520, 380, '#0F766E', '#F0FDFA');
        labelScale(c, 250, 1170, .75, .165, ease(t, .6, 1.6)); cheese(c, 160, 1060, .6);
        person(c, who('checkoutBoy', { x: 800, y: 1380, s: .9, armR: .4, armL: .5, brow: 'worry', mouth: 'flat', sweat: t > 3 ? t : 0, look: -10 })); counter(c, 560, 1160, 520, 380, '#0369A1', '#F0F9FF');
        T(c, { x: 820, y: 1120, s: .5 }, () => { rr(c, -200, -40, 400, 60, 14, '#1F2937'); for (let i = 0; i < 10; i++) rr(c, -180 + i * 36, -30, 28, 40, 6, (t > 2.8 && Math.floor((t - 2.8) * 3.3) % 10 === i) ? BRAND.amber : '#475569'); });
        for (let i = 0; i < 3; i++) person(c, { x: 1130 - (i + 1) * 0, y: 1760 + i * 0, s: .7, top: ['#22C55E', '#F43F5E', '#6366F1'][i], hs: i === 1 ? 'long' : 'short', body: i === 1 ? 'f' : 'm', mouth: 'flat', flip: true, bob: 0, ...{ x: 700 + i * 130 } });
        T(c, { x: 820, y: 760, s: ease(t, 2.2, 2.6, E.back) }, () => { circ(c, 0, 0, 120, '#fff'); T(c, { s: .35 }, () => v03Label(c, 0, 0, 1)); });
        chip(c, 820, 560, 'Қолмен теру = уақыт + қате', BRAND.red, '#fff', 36, P(t, 4.3, 4.7));
      } },
    { d: 8.4, shot: 'Шешім-диаграмма: сканер «пик» етеді; штрих-код цифрлары түсті топтарға бөлінеді: 20 (салмақ белгісі) • 00015 (PLU → Сыр) • 70950 (сома 709.50 ₸) • 0. Сосын «709.50 ÷ 4300 = 0.165 кг» есебі және себетке жол түседі.',
      text: 'PLU 15 → Сыр • 709.50 ₸ • 0.165 кг', capY: 1765,
      vo: 'iMag этикеткадағы салмақ штрих-кодын оқиды: PLU бойынша тауарды табады, салмақ пен соманы өзі қояды.', voAt: .2,
      sfx: [[0.3, 'scan'], [1.2, 'pop'], [2.0, 'pop'], [2.8, 'pop'], [4.4, 'whoosh', .6], [5.6, 'pop'], [6.2, 'success', .8]], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#F0FDFA');
        const groups = [['20', 'Салмақ белгісі', '#64748B'], ['00015', 'PLU → Сыр', BRAND.blue], ['70950', 'Сома: 709.50 ₸', BRAND.pay], ['0', '', '#94A3B8']];
        let gx = 540 - (13 * 62 + 3 * 30) / 2;
        groups.forEach(([d, lbl, col], i) => { const p = ease(t, .9 + i * .8, 1.3 + i * .8, E.back), w = d.length * 62;
          T(c, { x: gx + w / 2, y: 420 - p * 40 }, () => { rr(c, -w / 2 - 6, -60, w + 12, 120, 18, p > 0 ? col : '#CBD5E1'); txt(c, d, 0, 4, { size: 76, weight: 800, mono: true, color: '#fff', ls: 8 }); });
          if (lbl && p > 0) T(c, { x: gx + w / 2, y: 540, a: clamp(p) }, () => { txt(c, lbl, 0, 0, { size: 30, weight: 700, color: col }); });
          gx += w + 30; });
        const m = ease(t, 4.4, 5.0); if (m > 0) T(c, { x: 540, y: 720, a: m, s: .9 + .1 * m }, () => { rr(c, -440, -90, 880, 180, 30, '#fff'); txt(c, '709.50 ÷ 4300 ₸/кг = 0.165 кг', 0, 4, { size: 50, weight: 800 }); });
        T(c, { x: 540, y: 880 }, () => { rr(c, -500, 0, 1000, 640, 26, '#111827'); c.save(); c.translate(-480, 20); rr(c, 0, 0, 960, 600, 10); c.clip();
          posScreen(c, 960, 600, { cats: ['Все', 'Молочное'], cat: 1, tiles: [{ name: 'Сыр', price: '4300 ₸/кг', kg: 1, col: '#FEF3C7', icon: (c, x, y, s) => cheese(c, x, y, s / 120) }],
            items: t > 5.6 ? [{ name: 'Сыр', qty: '0.165 кг × 4300', sum: '709.5', kg: 1, a: ease(t, 5.6, 5.9) }] : [], total: t > 5.6 ? '709.5' : '0' }); c.restore(); });
        scanner(c, 940, 800, .6, -.5, t < .6 ? 1 : 0);
        toast(c, 'Сыр — 0.165 кг, 709.5 ₸', P(t, 5.7, 8.4), BRAND.pay, 1580);
      } },
    { d: 5.0, shot: 'Баптау: «Товары» бетінде «Сыр» тауарының «Код (PLU)» өрісі = 15; жанында таразы дисплейінде де «PLU 15». Арасында «=» белгісі жанады.',
      text: '«PLU таразыда = PLU iMag-та»', vo: 'Тек тауардың PLU кодын таразыдағыдай етіп енгізесіз.', voAt: .2,
      sfx: [[0.3, 'pop'], [1.2, 'type'], [1.4, 'type'], [2.2, 'sparkle', .7]], tr: 'slide',
      draw(c, t) {
        bgFlat(c, '#E0F2FE');
        T(c, { x: 540, y: 700, s: ease(t, .2, .6, E.back) }, () => { rr(c, -470, -260, 940, 520, 34, '#fff'); txt(c, 'Добавить товар', -420, -200, { size: 40, weight: 800, align: 'left' });
          [['Название товара', 'Сыр'], ['Категория', 'Молочное'], ['Единица', 'кг'], ['Код (PLU)', t > 1.2 ? (t > 1.4 ? '15' : '1') : '—'], ['Цена (₸)', '4300']].forEach(([l, v], i) => { const fy = -130 + i * 74, hl = i === 3;
            txt(c, l, -420, fy, { size: 28, weight: 500, align: 'left', color: '#64748B' }); rr(c, -60, fy - 30, 460, 60, 14, hl ? BRAND.blueL : '#F7F9FC'); if (hl) { c.strokeStyle = BRAND.blue; c.lineWidth = 4; rr(c, -60, fy - 30, 460, 60, 14); c.stroke(); }
            txt(c, v, -36, fy + 2, { size: 30, weight: 700, align: 'left' }); }); });
        labelScale(c, 300, 1650, 1.1, 0); T(c, { x: 449, y: 1347 }, () => { rr(c, -62, -36, 124, 70, 8, '#0F172A'); txt(c, 'PLU 15', 0, 0, { size: 24, weight: 800, mono: true, color: '#34D399' }); });
        const q = ease(t, 2.1, 2.5, E.back); T(c, { x: 760, y: 1250, s: q }, () => { circ(c, 0, 0, 90, BRAND.green); txt(c, '=', 0, 4, { size: 110, weight: 900, color: '#fff' }); });
        headline(c, 'PLU таразыда = PLU iMag-та', 220, t, { size: 70, delay: .2, hl: ['PLU'], hlCol: BRAND.blue });
      } },
    { d: 3.8, shot: 'Кассада үш тауар қатарынан «пик-пик-пик»; әр сканерде жасыл белгі; кезектегі адамдар бірінен соң бірі шығып кетеді.',
      text: '«Кезек жылдам, есеп — дәл»', vo: 'Кезек жылдам, есеп — дәл.', voAt: .2,
      sfx: [[0.3, 'scan'], [0.9, 'scan'], [1.5, 'scan'], [2.1, 'kaching', .8]], tr: 'wipe',
      draw(c, t) {
        v03Market(c);
        person(c, who('checkoutBoy', { x: 800, y: 1380, s: .9, armR: .9, armL: .2, mouth: 'big', look: -10 })); counter(c, 560, 1160, 520, 380, '#0369A1', '#F0F9FF');
        [0, 1, 2].forEach(i => { const left = ease(t, .5 + i * .6, .9 + i * .6); person(c, { x: 400 - i * 140 - left * 700, y: 1760, s: .75, top: ['#22C55E', '#F43F5E', '#6366F1'][i], hs: i === 1 ? 'long' : 'short', body: i === 1 ? 'f' : 'm', mouth: 'big', bob: Math.abs(osc(t, 3, 6)) * left }); check(c, 960, 1000 - i * 130, .6, ease(t, .3 + i * .6, .5 + i * .6)); });
        scanner(c, 650, 1150, .6, -.6, (t % .6) < .2 ? 1 : 0);
        headline(c, 'Кезек жылдам, есеп — дәл', 400, t, { size: 76, delay: .1, hl: ['дәл'], hlCol: BRAND.pay, panel: 'rgba(255,255,255,.92)' });
      } },
    { d: 4.2, shot: 'Соңғы кадр.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Этикетканы сканерле — қалғанын iMag жасайды»', vo: 'iMag Kassa. Әр теңге — есепте.', voAt: .6, noCap: true,
      sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', draw(c, t) { endcard(c, t, 'Сканерлейсіз — қалғанын iMag жасайды'); } },
  ],
};
