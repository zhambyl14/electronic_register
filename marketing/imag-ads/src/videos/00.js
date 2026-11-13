// 00 — Intro: reply to the viewer's comment
VIDEOS['00'] = {
  id: '00', title: 'Комментке жауап: «iMag — ең күшті касса»',
  feature: 'iMag Kassa-мен таныстыру: не екені, не істейді, бұлт арқылы есеп',
  setting: 'Брендтік кеңістік (көгілдір студия) + әлеуметтік желі лентасы',
  cast: 'iMag командасының өкілі (көк худи, көзілдірік) — «біз»',
  problem: 'Көрермен «iMag туралы айтшы» деп сұрады — бір видеода iMag деген не екенін түсіндіру',
  music: { style: 'pop', bpm: 112, key: 'A', desc: 'Жеңіл энергиялы поп-электро: клэп, синт-плак, басс. Хук кезінде “notification” дыбысымен басталады.' },
  scenes: [
    { d: 3.2, shot: 'Хук. Үлкен телефон экраны; лентаға оқырманның комменті «секіріп» шығады, жүрекше санағышы өседі. Үстінде кинетикалық тақырып.',
      text: '«Сұрадыңыз — айтамыз!» + коммент: «iMag касса — ең күшті касса, соны да айтшы!»',
      vo: 'Сіз сұрадыңыз — біз айтамыз!', voAt: .9, sfx: [[0.05, 'ding'], [0.12, 'pop'], [0.9, 'whoosh', .7], [1.6, 'pop', .6], [1.8, 'pop', .6]], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#EEF2FF'); circ(c, 900, 300, 260, '#E0E7FF'); circ(c, 120, 1500, 300, '#E0E7FF');
        phone(c, 540, 1180, 1.32 + .03 * ease(t, 0, .4), (c, w, h) => {
          bgFlat(c, '#0F172A'); c.fillStyle = '#1E293B'; c.fillRect(0, 0, w, h * .62);
          T(c, { x: w / 2, y: h * .3, s: .7 }, () => { logo(c, 0, 0, 160); });
          rr(c, 0, h * .55, w, h * .45, 0, '#F8FAFC'); txt(c, 'Комментарийлер', 24, h * .58, { size: 22, weight: 700, align: 'left', color: '#475569' });
          for (let i = 0; i < 3; i++) { circ(c, 44, h * .66 + i * 90, 22, '#CBD5E1'); rr(c, 80, h * .65 + i * 90 - 10, 220 - i * 30, 16, 8, '#E2E8F0'); rr(c, 80, h * .65 + i * 90 + 16, 150, 14, 7, '#E2E8F0'); }
        });
        commentCard(c, 540, 1240, 940, '@оқырман', 'iMag касса — ең күшті касса, соны да айтшы!', ease(t, .05, .45), String(Math.round(lerp(12, 128, ease(t, .5, 2.4)))));
        headline(c, 'Сұрадыңыз — айтамыз!', 250, t, { size: 96, delay: .7, hl: ['айтамыз!'], hlCol: BRAND.blue });
      } },
    { d: 7.0, shot: 'Өкіл кадрға кіреді; жанындағы моноблокта «iMag Kassa орнатылуда» жолағы толады да, касса экраны ашылады.',
      text: '«Дүкенге арналған касса бағдарламасы» • «Windows»',
      vo: 'iMag Kassa — дүкенге арналған касса бағдарламасы. Компьютерге орнатасыз да, сата бересіз.', voAt: .3,
      sfx: [[0.2, 'whoosh'], [1.2, 'tap'], [1.3, 'riser', .5], [3.1, 'success'], [3.3, 'pop', .6], [4.4, 'pop', .6]], tr: 'wipe',
      draw(c, t) {
        bgRoom(c, { wall: '#DBEAFE', wall2: '#BFDBFE', floor: '#93C5FD', horizon: 1350 });
        const px = lerp(-200, 250, ease(t, 0, .9)); person(c, who('dev', { x: px, y: 1500, s: 1.25, armR: t > 1 ? .9 + osc(t, .8, .08) : .1, armL: .05, bob: osc(t, 2, 4), mouth: (t % .5 < .25 && t > .3 && t < 5.5) ? 'open' : 'smile' }));
        const inst = P(t, 1.3, 3.0);
        monoblock(c, 680, 1400, 1.08, t < 3.05 ? { tiles: [], items: [], total: '0', overlay: (c, w, h) => { c.fillStyle = 'rgba(15,23,42,.92)'; c.fillRect(0, 0, w, h); T(c, { x: w / 2, y: h * .36 }, () => logo(c, 0, 0, 90)); txt(c, 'iMag Kassa орнатылуда…', w / 2, h * .62, { size: 26, weight: 600, color: '#E2E8F0' }); rr(c, w * .15, h * .72, w * .7, 16, 8, '#334155'); rr(c, w * .15, h * .72, w * .7 * inst, 16, 8, BRAND.green); } }
          : { tiles: [{ name: 'Сиыр еті', price: '4200 ₸/кг', kg: 1, col: '#FECACA', icon: (c, x, y, s) => meatCut(c, x, y, s / 120) }, { name: 'Нан', price: '250 ₸/шт', col: '#FDE68A', icon: (c, x, y, s) => bread(c, x, y, s / 110) }, { name: 'Сүт', price: '450 ₸/шт', col: '#DBEAFE', icon: (c, x, y, s) => bottle(c, x, y + 20, s / 200) }], items: [], total: '0' });
        chip(c, 540, 420, 'Дүкенге арналған касса бағдарламасы', BRAND.navy, '#fff', 38, P(t, 3.3, 3.8));
        chip(c, 540, 530, 'Windows', BRAND.blue, '#fff', 34, P(t, 4.4, 4.8));
      } },
    { d: 6.2, shot: 'Касса ортада; айналасына алты құрылғы/модуль ұшып келіп, сыммен жалғанады: таразы, сканер, чек принтері, есеп, возврат, покупатель экраны.',
      text: 'Таразы • Сканер • Чек • Есеп • Возврат • Покупатель экраны',
      vo: 'Таразы, штрих-код сканері, чек принтері, есеп пен возврат — бәрі бір жерде.', voAt: .2,
      sfx: [[0.3, 'pop'], [0.9, 'pop'], [1.5, 'pop'], [2.1, 'pop'], [2.7, 'pop'], [3.3, 'pop'], [4.2, 'sparkle']], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#0F172A'); for (let i = 0; i < 3; i++) { c.strokeStyle = 'rgba(96,165,250,.12)'; c.lineWidth = 3; c.beginPath(); c.arc(540, 900, 300 + i * 160 + osc(t, .3, 10), 0, 7); c.stroke(); }
        const items = [['Таразы', -330, -420, (c) => scaleDev(c, 0, 60, .55, 1.25)], ['Сканер', 330, -420, (c) => scanner(c, 0, 20, .9, -.4)], ['Чек', -380, 0, (c) => printerDev(c, 0, 60, .6)],
          ['Есеп', 380, 0, (c) => { rr(c, -80, -60, 160, 120, 14, '#fff'); [3, 6, 4, 8].forEach((v, i) => rr(c, -60 + i * 32, 40 - v * 9, 22, v * 9, 4, i === 3 ? BRAND.amber : BRAND.blue)); }],
          ['Возврат', -330, 420, (c) => { circ(c, 0, 0, 70, '#F59E0B'); c.strokeStyle = '#fff'; c.lineWidth = 12; c.beginPath(); c.arc(0, 0, 36, .3, Math.PI * 1.7); c.stroke(); poly(c, [[30, -40], [50, -8], [14, -6]], '#fff'); }],
          ['Покупатель экраны', 330, 420, (c) => custDisplay(c, 0, 50, .28, [], null)]];
        items.forEach(([name, dx, dy, fn], i) => { const p = ease(t, .3 + i * .6, .9 + i * .6, E.back); if (p <= 0) return;
          const x = 540 + dx * p, y = 900 + dy * p; cable(c, [[540, 900], [540 + dx * .5, 900 + dy * .2], [x, y]], '#334155', 8, .9 * P(t, 4, 4.5), t);
          T(c, { x, y, s: p }, () => { circ(c, 0, 0, 130, '#1E293B'); fn(c); }); chip(c, x, y + 170, name, BRAND.blue, '#fff', 30, P(t, .5 + i * .6, .9 + i * .6)); });
        T(c, { x: 540, y: 900, s: 1 + .05 * Math.sin(t * 3) * P(t, 4, 4.4) }, () => { circ(c, 0, 0, 150, BRAND.blue); logo(c, 0, 0, 170); });
        headline(c, 'Бәрі бір жерде', 230, t, { size: 90, delay: 3.8, color: '#fff', hl: ['бір'], hlCol: '#4ADE80' });
      } },
    { d: 5.9, shot: 'Кассадан бұлтқа, бұлттан телефонға деректер нүктелері ағады; телефонда «Отчёты» экраны жанады.',
      text: '«Деректер бұлтта» • «Есеп — кез келген жерден»',
      vo: 'Ал сатылымдар бұлтта сақталады — иесі есепті кез келген жерден көреді.', voAt: .2,
      sfx: [[0.2, 'whoosh'], [1.0, 'blip', .5], [1.4, 'blip', .5], [1.8, 'blip', .5], [2.6, 'phone_buzz'], [3.2, 'success', .7]], tr: 'wipe',
      draw(c, t) {
        bgFlat(c, '#E0F2FE'); circ(c, 540, 600, 420, '#BAE6FD');
        T(c, { x: 540, y: 520 + osc(t, .5, 10) }, () => { circ(c, -110, 30, 110, '#fff'); circ(c, 40, -30, 150, '#fff'); circ(c, 170, 40, 100, '#fff'); rr(c, -220, 30, 480, 110, 55, '#fff'); txt(c, 'Бұлт', 30, 70, { size: 46, weight: 800, color: BRAND.blue }); });
        monoblock(c, 290, 1560, .62, { tiles: [], items: [{ name: 'Сиыр еті', qty: '1.250 кг', sum: '5 250', kg: 1 }], total: '5 250' });
        phone(c, 800, 1240, .72, (c, w, h) => reportsUI(c, w, h, { rev: '187 400', n: '64', avg: '2 928', split: '121 900 / 65 500' }, P(t, 2.6, 4.2)), { r: .06 });
        for (let i = 0; i < 6; i++) { const p = ((t * .7 + i / 6) % 1); if (t < .6) continue;
          const a = p < .5 ? [lerp(290, 470, p * 2), lerp(1200, 650, p * 2)] : [lerp(610, 800, (p - .5) * 2), lerp(650, 860, (p - .5) * 2)]; circ(c, a[0], a[1], 14, BRAND.green); }
        chip(c, 540, 230, 'Есеп — кез келген жерден', BRAND.navy, '#fff', 44, P(t, 3, 3.5));
      } },
    { d: 4.9, shot: 'Тизер: ет дүкенінің есігі, «ЕТ ДҮКЕНІ» маңдайшасы. Аяжанның ағасы есік алдында қол бұлғайды. «НАҚТЫ ОҚИҒА» мөрі басылады.',
      text: '«НАҚТЫ ОҚИҒА» • «Келесі видеода»',
      vo: 'Келесі видеода — нақты оқиға: Аяжанның ағасының ет дүкені.', voAt: .2,
      sfx: [[0.1, 'whoosh'], [1.6, 'stamp'], [3.0, 'pop', .6]], tr: 'slide',
      draw(c, t) {
        bgRoom(c, { wall: '#FDE7D3', wall2: '#F8D3B5', floor: '#D6B08C', horizon: 1500 });
        rr(c, 140, 520, 800, 980, 20, '#7F1D1D'); rr(c, 160, 540, 760, 960, 14, '#991B1B'); windowPane(c, 220, 700, 260, 340, '#FDE68A'); rr(c, 560, 700, 300, 800, 10, '#451A03');
        sign(c, 220, 360, 640, 140, '#DC2626', 'ЕТ ДҮКЕНІ', '#fff', 78);
        person(c, who('aga', { x: 710, y: 1560, s: 1.15, armR: 2.3 + osc(t, 2, .25), armL: .05, mouth: 'big' }));
        const sp = ease(t, 1.5, 1.8, E.back); T(c, { x: 330, y: 1130, s: (2 - sp) * (sp > 0 ? 1 : 0), r: -.2, a: sp }, () => { c.strokeStyle = '#DC2626'; c.lineWidth = 10; rr(c, -230, -70, 460, 140, 20); c.stroke(); txt(c, 'НАҚТЫ ОҚИҒА', 0, 4, { size: 58, weight: 900, color: '#DC2626' }); });
        chip(c, 540, 230, 'Келесі видеода', BRAND.navy, '#fff', 46, P(t, 2.9, 3.3));
      } },
    { d: 4.2, shot: 'Соңғы кадр: iMag логотипі, атауы және ұран.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Windows-қа арналған касса бағдарламасы»',
      vo: 'iMag Kassa. Әр теңге — есепте.', voAt: .6, sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', noCap: true,
      draw(c, t) { endcard(c, t, 'Windows-қа арналған касса бағдарламасы'); } },
  ],
};
