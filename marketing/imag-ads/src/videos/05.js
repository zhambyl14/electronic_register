// 05 — Morning rush at a bakery: mixed cash+card payment, instant change
function v05Bakery(c) {
  bgRoom(c, { wall: '#FEF3C7', wall2: '#FDE68A', floor: '#B45309', floor2: 'rgba(0,0,0,.05)', horizon: 1300 });
  sign(c, 290, 200, 500, 120, '#92400E', 'НАН ҮЙІ', '#FEF3C7', 72);
  shelf(c, 60, 640, 960, '#92400E'); for (let i = 0; i < 6; i++) bread(c, 150 + i * 160, 610, .7, i % 2 ? '#D97706' : '#B45309');
  shelf(c, 60, 900, 960, '#92400E'); for (let i = 0; i < 8; i++) circ(c, 120 + i * 120, 870, 34, i % 2 ? '#F59E0B' : '#FBBF24');
}
function v05Pay(c, w, h, st) { // the real "Оплата" dialog
  rr(c, 0, 0, w, h, 34, '#fff'); rr(c, 36, 36, 56, 56, 14, '#D1FAE5'); circ(c, 64, 64, 12, BRAND.pay);
  txt(c, 'Оплата', 112, 66, { size: 44, weight: 800, align: 'left' }); txt(c, 'Итого: ' + st.total + ' ₸', 40, 130, { size: 30, weight: 500, align: 'left', color: '#6B7280' });
  txt(c, 'Способ оплаты', 40, 190, { size: 26, weight: 600, align: 'left', color: '#4A5568' });
  ['Наличные', 'Карта', 'Смешанная'].forEach((m, i) => { const bx = 40 + i * ((w - 100) / 3 + 10), bw = (w - 100) / 3, on = st.method === i;
    rr(c, bx, 220, bw, 100, 18, on ? '#ECFDF5' : '#F8FAFC'); c.strokeStyle = on ? BRAND.pay : '#E2E8F0'; c.lineWidth = on ? 4 : 2; rr(c, bx, 220, bw, 100, 18); c.stroke();
    txt(c, m, bx + bw / 2, 272, { size: 28, weight: 700, color: on ? '#047857' : '#475569' }); });
  if (st.method === 2) {
    [['Наличные:', st.cash, true], ['Карта:', st.card, false]].forEach(([l, v, act], i) => { const fy = 350 + i * 120; rr(c, 40, fy, w - 80, 100, 18, act ? '#F0FDF4' : '#F0F7FF'); c.strokeStyle = act ? BRAND.pay : '#BFDBFE'; c.lineWidth = act ? 4 : 2; rr(c, 40, fy, w - 80, 100, 18); c.stroke();
      txt(c, l, 70, fy + 50, { size: 30, weight: 600, align: 'left', color: '#475569' }); txt(c, (v || '0') + ' ₸', w - 70, fy + 52, { size: 46, weight: 800, align: 'right', color: act ? BRAND.ink : BRAND.blue }); });
    txt(c, 'Сдача:', 70, 615, { size: 28, weight: 500, align: 'left', color: '#6B7280' }); txt(c, '0 ₸', w - 70, 615, { size: 36, weight: 800, align: 'right', color: BRAND.pay });
  } else {
    rr(c, 40, 350, w - 80, 110, 18, '#F8FAFC'); txt(c, 'Принято:', 70, 405, { size: 28, weight: 500, align: 'left', color: '#6B7280' }); txt(c, (st.paid || '0') + ' ₸', w - 70, 407, { size: 50, weight: 800, align: 'right' });
    rr(c, 40, 480, w - 80, 110, 18, '#F0FDF4'); txt(c, 'Сдача:', 70, 535, { size: 28, weight: 500, align: 'left', color: '#6B7280' });
    T(c, { x: w - 70, y: 537, s: st.changePop ? 1 + .25 * st.changePop : 1 }, () => txt(c, (st.change || '0') + ' ₸', 0, 0, { size: 50, weight: 900, align: 'right', color: BRAND.pay }));
  }
  ['7', '8', '9', '4', '5', '6', '1', '2', '3', 'C', '0', '⌫'].forEach((k, i) => { const kx = 40 + (i % 3) * ((w - 100) / 3 + 10), ky = 660 + Math.floor(i / 3) * 96, kw = (w - 100) / 3;
    rr(c, kx, ky, kw, 84, 16, st.key === k ? BRAND.blueL : '#F1F5F9'); txt(c, k, kx + kw / 2, ky + 44, { size: 38, weight: 600 }); });
  rr(c, 40, h - 130, (w - 100) / 3, 96, 18, '#F8FAFC'); txt(c, 'Отмена', 40 + (w - 100) / 6, h - 82, { size: 30, weight: 600, color: '#6B7280' });
  rr(c, 60 + (w - 100) / 3, h - 130, (w - 100) * 2 / 3 + 0, 96, 18, st.okHl ? '#059669' : BRAND.pay); txt(c, 'Подтвердить', 60 + (w - 100) / 3 + (w - 100) / 3, h - 82, { size: 32, weight: 700, color: '#fff' });
}
VIDEOS['05'] = {
  id: '05', title: 'Таңғы кезек: жартысы қолма-қол, жартысы карта',
  feature: 'Төлем: «Наличные» (қайтарымды автоматты есептеу), «Карта», «Смешанная» (қолма-қол сомасын терсе, картаға қалғаны өзі шығады); есепте Нал / Карта бөлек',
  setting: 'Таңертеңгі наубайхана «НАН ҮЙІ» (жылы бежевый-қоңыр)', cast: 'Наубайшы-кассир жігіт (бұйра шаш, ақ қалпақ, бетінде ұн), асығыс іскер әйел (көк пиджак)',
  problem: 'Аралас төлем мен қайтарымды ойша есептеу — таңғы кезекте қате мен кідіріс',
  music: { style: 'acoustic', bpm: 116, key: 'G', desc: 'Таңғы акустикалық гитара-плак, жеңіл шейкер; кезек сахнасында сағат тықылы қосылады.' },
  scenes: [
    { d: 3.2, shot: 'Хук. Сағат 08:01. Ұзын кезек. Іскер әйел карта мен 3000 теңгені қатар ұстап: «3000 қолма-қол, қалғаны картамен!» Үлкен мәтін.',
      text: '«Жартысы қолма-қол, жартысы карта?»', vo: 'Жартысы қолма-қол, жартысы картамен?', voAt: .4,
      sfx: [[0.05, 'alarm', .6], [0.4, 'pop'], [1.0, 'whoosh', .6]], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#FFFBEB'); circ(c, 540, 1100, 520, '#FEF3C7');
        T(c, { x: 850, y: 640 }, () => { rr(c, -150, -70, 300, 140, 30, '#1F2937'); txt(c, t % 1 < .5 ? '08:01' : '08 01', 0, 4, { size: 80, weight: 800, mono: true, color: '#F87171' }); });
        person(c, who('bizWoman', { x: 540, y: 1700, s: 1.3, armL: 1.1, armR: 1.1, mouth: (t % .4 < .2) ? 'open' : 'smile', holdL: () => banknote(c, 0, -30, .7, .2, '3000'), holdR: () => bankCard(c, 0, -30, .6, -.2) }));
        headline(c, 'Жартысы қолма-қол, жартысы карта?', 220, t, { size: 78, delay: .5, step: .1, hl: ['қолма-қол,', 'карта?'], hlCol: BRAND.pay, maxW: 700 });
      } },
    { d: 5.4, shot: 'Наубайхана. Кассир жігіттің басының үстінде ой-бұлты: «7350 − 3000 = ?»; кезектегілер сағатқа қарайды; кассир абдырап, тер тамшысы.',
      text: '«7350 − 3000 = ?»', vo: 'Таңғы кезекте мұндай сұрақ кассирді тұйыққа тірейді.', voAt: .2,
      sfx: [[0.3, 'tick'], [0.8, 'tick'], [1.3, 'tick'], [1.8, 'tick'], [2.3, 'tick'], [2.0, 'question', .7], [3.6, 'crowd', .5]], tr: 'wipe',
      draw(c, t) {
        v05Bakery(c);
        for (let i = 0; i < 4; i++) person(c, { x: 650 + i * 120, y: 1760 - i * 20, s: .78, top: ['#1E40AF', '#64748B', '#DB2777', '#0D9488'][i], hs: i % 2 ? 'long' : 'short', body: i === 0 || i === 2 ? 'f' : 'm', mouth: 'flat', brow: 'angry', look: -10, bob: Math.abs(osc(t + i * .2, 2, 5)) });
        person(c, who('baker', { x: 300, y: 1390, s: 1.0, brow: 'worry', mouth: 'o', sweat: t, armL: .3, armR: .3 })); counter(c, 0, 1200, 640, 400, '#92400E', '#FFFBEB');
        T(c, { x: 330, y: 700, s: ease(t, .4, .9, E.back) }, () => { circ(c, -120, 30, 90, '#fff'); circ(c, 20, -10, 120, '#fff'); circ(c, 150, 30, 80, '#fff'); rr(c, -200, 20, 420, 100, 50, '#fff'); circ(c, -40, 190, 24, '#fff'); circ(c, -70, 240, 14, '#fff');
          txt(c, '7350 − 3000 = ?', 10, 50, { size: 56, weight: 900, color: '#92400E' }); });
      } },
    { d: 7.6, shot: 'Шешім: iMag «Оплата» терезесі. «Смешанная» таңдалады → «Наличные» өрісіне 3000 теріледі → «Карта» өрісі өзі 4350 болады (жасыл жарқыл).',
      text: '«Смешанная» • Наличные 3000 ₸ → Карта 4350 ₸ (автоматты)',
      vo: 'iMag-та «Смешанная» төлем бар: қолма-қол соманы тересіз — картаға қалғаны өзі шығады.', voAt: .2,
      sfx: [[0.3, 'whoosh'], [1.2, 'tap'], [2.2, 'tap'], [2.5, 'tap'], [2.8, 'tap'], [3.1, 'tap'], [3.3, 'sparkle'], [5.6, 'tap'], [5.8, 'success']], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#ECFDF5'); const method = t > 1.2 ? 2 : 0; const cash = t < 2.2 ? '' : t < 2.5 ? '3' : t < 2.8 ? '30' : t < 3.1 ? '300' : '3000';
        const card = method === 2 ? (cash === '' ? '7350' : String(7350 - Number(cash))) : '';
        T(c, { x: 110, y: 330 }, () => v05Pay(c, 860, 1180, { total: '7 350', method, cash, card, key: (t > 2.2 && t < 3.3) ? cash.slice(-1) : '', okHl: t > 5.6 && t < 5.9, paid: '7350', change: '0' }));
        if (t > 1.0 && t < 1.5) finger(c, 820, 650, 1, P(t, 1.1, 1.25)); if (t > 5.4 && t < 6) finger(c, 760, 1440, 1, P(t, 5.5, 5.65));
        if (t > 3.3) T(c, { x: 540, y: 250, a: ease(t, 3.3, 3.6) }, () => chip(c, 0, 0, 'Картаға: 4 350 ₸ — өзі!', BRAND.blue, '#fff', 44, 1));
        check(c, 900, 1500, .9, ease(t, 5.8, 6.1));
      } },
    { d: 5.2, shot: 'Келесі клиент 5000 береді, чек 4830: «Наличные» → «Принято: 5000» → «Сдача: 170 ₸» үлкейіп жанады. Кассир күледі.',
      text: '«Сдача: 170 ₸» — бірден', vo: 'Қолма-қол берсе — қайтарымы бірден көрінеді.', voAt: .2,
      sfx: [[0.3, 'paper'], [1.4, 'tap'], [1.7, 'tap'], [2.0, 'coin'], [2.1, 'pop']], tr: 'slide',
      draw(c, t) {
        bgFlat(c, '#FFFBEB'); const paid = t < 1.4 ? '4830' : t < 1.7 ? '5' : '5000', ch = paid === '5000' ? '170' : '0';
        T(c, { x: 160, y: 300, s: .9 }, () => v05Pay(c, 860, 1180, { total: '4 830', method: 0, paid, change: ch, changePop: ch === '170' ? Math.max(0, 1 - (t - 2.0) * 2) : 0, key: t > 1.4 && t < 2 ? paid.slice(-1) : '' }));
        banknote(c, 220, 1640, 1.2, -.15 + ease(t, 0, .6) * .1, '5000'); person(c, who('baker', { x: 870, y: 1880, s: .9, mouth: t > 2.1 ? 'big' : 'smile', armR: t > 2.1 ? 2.4 : .2 }));
        chip(c, 540, 200, 'Сдача: 170 ₸ — бірден', BRAND.pay, '#fff', 48, P(t, 2.1, 2.5));
      } },
    { d: 4.4, shot: 'Кешкі есеп: «Нал / Карта» карточкасы екі түсті бағанға бөлінеді — қолма-қол бөлек, карта бөлек.',
      text: '«Нал / Карта — бөлек-бөлек»', vo: 'Ал кешке қолма-қол мен картаның есебі бөлек-бөлек тұрады.', voAt: .2,
      sfx: [[0.3, 'whoosh'], [1.0, 'pop'], [1.4, 'pop']], tr: 'wipe',
      draw(c, t) {
        bgFlat(c, '#1E1B4B'); circ(c, 900, 260, 90, '#FDE68A'); circ(c, 870, 240, 80, '#1E1B4B');
        const p = ease(t, .8, 1.8); T(c, { x: 540, y: 900 }, () => { rr(c, -420, -300, 840, 640, 40, '#fff'); txt(c, 'Нал / Карта', -360, -230, { size: 44, weight: 800, align: 'left' });
          rr(c, -330, 260 - 420 * p, 260, 420 * p, 20, BRAND.pay); rr(c, 70, 260 - 300 * p, 260, 300 * p, 20, BRAND.blue);
          txt(c, 'Наличные', -200, 300, { size: 30, weight: 600, color: '#475569' }); txt(c, 'Карта', 200, 300, { size: 30, weight: 600, color: '#475569' });
          txt(c, money(Math.round(84300 * p)) + ' ₸', -200, 220 - 420 * p, { size: 34, weight: 800, color: '#047857', alpha: p }); txt(c, money(Math.round(61250 * p)) + ' ₸', 200, 220 - 300 * p, { size: 34, weight: 800, color: '#1D4ED8', alpha: p }); });
        headline(c, 'Нал / Карта — бөлек-бөлек', 300, t, { size: 76, delay: .2, color: '#fff', hl: ['бөлек-бөлек'], hlCol: '#4ADE80' });
      } },
    { d: 4.2, shot: 'Соңғы кадр.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Қалай төлесе де — есеп дұрыс»', vo: 'iMag Kassa. Әр теңге — есепте.', voAt: .6, noCap: true,
      sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', draw(c, t) { endcard(c, t, 'Қалай төлесе де — есеп дұрыс'); } },
  ],
};
