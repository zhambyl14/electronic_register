// 08 — New shop opening tomorrow: adding products with photo, category, unit, price; inline price edit
function v08Shop(c) {
  bgRoom(c, { wall: '#D1FAE5', wall2: '#A7F3D0', floor: '#E5E7EB', horizon: 1320 });
  sign(c, 250, 200, 580, 120, '#059669', 'ЖАҢА ДҮКЕН', '#fff', 64);
  shelf(c, 60, 700, 960, '#94A3B8'); shelf(c, 60, 980, 960, '#94A3B8');
}
function v08Form(c, w, h, st) { // the real "Добавить товар" form
  rr(c, 0, 0, w, h, 34, '#fff'); txt(c, 'Добавить товар', 40, 64, { size: 42, weight: 800, align: 'left' });
  rr(c, 40, 110, 230, 230, 24, '#F1F5F9'); txt(c, 'Фото', 155, 320, { size: 24, weight: 600, color: '#94A3B8' });
  if (st.photo) T(c, { x: 155, y: 215, s: st.photo }, () => { rr(c, -100, -95, 200, 190, 18, '#FEF3C7'); bottle(c, 0, 60, .62, '#FFFBEB', '#B45309', '#FDE68A'); }); else { rr(c, 135, 190, 40, 30, 6, '#CBD5E1'); circ(c, 155, 205, 8, '#F1F5F9'); }
  const f = [['Название товара', st.name || '', 'Например: Жая ет'], ['Категория', st.cat || '', 'Жая ет, Фарш...'], ['Единица', st.unit || 'кг', ''], ['Цена (₸)', st.price || '', '']];
  f.forEach(([l, v, hint], i) => { const fy = 120 + i * 120, fx = 300; txt(c, l, fx, fy, { size: 24, weight: 600, align: 'left', color: '#4A5568' });
    rr(c, fx, fy + 22, w - fx - 40, 70, 16, st.active === i ? BRAND.blueL : '#F7F9FC'); if (st.active === i) { c.strokeStyle = BRAND.blue; c.lineWidth = 4; rr(c, fx, fy + 22, w - fx - 40, 70, 16); c.stroke(); }
    txt(c, v || hint, fx + 24, fy + 58, { size: 30, weight: v ? 700 : 500, align: 'left', color: v ? BRAND.ink : '#A0AEC0' }); });
  rr(c, w - 300, h - 120, 260, 86, 18, st.saveHl ? '#1D4ED8' : BRAND.blue); txt(c, '+ Сохранить', w - 170, h - 76, { size: 32, weight: 700, color: '#fff' });
}
VIDEOS['08'] = {
  id: '08', title: 'Ертең ашыламыз! Тауарды бір минутта қосу',
  feature: 'Тауарлар: фото, атауы, санаты, өлшем бірлігі (кг/шт), PLU, бағасы; тауар кассада суретімен және санат бойынша шығады; бағаны тізімнен түзету',
  setting: 'Ашылуға дайындалып жатқан жаңа шағын дүкен (жалбыз-жасыл, қораптар)', cast: 'Жас кәсіпкер жігіт (жасыл футболка, қара кепка)',
  problem: 'Ертең ашылу, ал жүздеген тауар әлі жүйеге енгізілмеген',
  music: { style: 'brightpop', bpm: 118, key: 'C', desc: 'Жарқын поп: маримба мен синт-плак, “тық-тық” теру ырғағы; “Сохранить” сәтінде позитив аккорд.' },
  scenes: [
    { d: 3.8, shot: 'Хук. Қораптар тауы құлауға таяу; кәсіпкер қолындағы қораптарды теңестіріп тұр; күнтізбеде «ЕРТЕҢ — АШЫЛУ!» қызыл шеңбермен.',
      text: '«Ертең ашыламыз!»', vo: 'Ертең ашыламыз, ал тауарлар әлі енгізілмеген!', voAt: .3,
      sfx: [[0.05, 'thud'], [0.3, 'wobble', .6], [1.2, 'pop'], [2.4, 'thud', .6]], tr: 'cut',
      draw(c, t) {
        bgFlat(c, '#ECFDF5');
        for (let i = 0; i < 9; i++) box(c, 180 + (i % 3) * 180 + osc(t + i, 1.5, 4), 1700 - Math.floor(i / 3) * 140, .95, i % 2 ? '#D6A15E' : '#C08A4E');
        person(c, who('newOwner', { x: 820, y: 1720, s: 1.15, armL: 2.9, armR: 2.9, brow: 'worry', mouth: 'o', sweat: t, lean: osc(t, 1.2, .05) }));
        T(c, { x: 820, y: 920 + osc(t, 1.2, 8) }, () => box(c, 0, 0, .8, '#D6A15E'));
        T(c, { x: 300, y: 820, r: -.06, s: ease(t, 1.1, 1.5, E.back) }, () => { rr(c, -170, -150, 340, 300, 24, '#fff'); rr(c, -170, -150, 340, 80, 24, BRAND.red); txt(c, 'ЕРТЕҢ', 0, -110, { size: 40, weight: 900, color: '#fff' }); txt(c, 'АШЫЛУ!', 0, 20, { size: 60, weight: 900, color: BRAND.red });
          c.strokeStyle = BRAND.red; c.lineWidth = 8; c.beginPath(); c.ellipse(0, 20, 150, 60, 0, 0, 7); c.stroke(); });
        headline(c, 'Тауарлар әлі енгізілмеген!', 260, t, { size: 82, delay: .2, hl: ['әлі'], hlCol: BRAND.red });
      } },
    { d: 4.8, shot: 'Жаңа дүкен: бос сөрелер; кәсіпкердің қолындағы тізім-орама еденге дейін жайылып кетеді: «Шұбат, Құрт, Нан, Сүт, Ірімшік…»',
      text: '«Жүздеген тауар…»', vo: 'Жаңа дүкен — жүздеген тауар. Қайдан бастау керек?', voAt: .2,
      sfx: [[0.4, 'unroll'], [2.4, 'sigh', .6]], tr: 'wipe',
      draw(c, t) {
        v08Shop(c); const L = 900 * ease(t, .4, 1.6);
        person(c, who('newOwner', { x: 540, y: 1560, s: 1.0, armL: .9, armR: .9, brow: 'worry', mouth: 'sad' }));
        rr(c, 380, 1220, 320, Math.max(20, L * .5), 6, '#FFFFFF'); rr(c, 380, 1220 + L * .5, 320, 30, 15, '#F1F5F9');
        ['Шұбат', 'Құрт', 'Нан', 'Сүт', 'Ірімшік', 'Қаймақ', 'Жұмыртқа'].forEach((n, i) => { if (40 + i * 60 < L * .5) txt(c, '• ' + n, 410, 1260 + i * 60, { size: 32, weight: 600, align: 'left', color: '#334155' }); });
        headline(c, 'Қайдан бастау керек?', 470, t, { size: 76, delay: 1.6, panel: 'rgba(255,255,255,.9)' });
      } },
    { d: 7.6, shot: 'iMag «Товары» → «Добавить товар» формасы: фото қосылады (камера жарқылы), атауы «Шұбат», санаты «Молочное», бірлігі «шт», бағасы «1200» теріледі → «Сохранить» → «Товар успешно добавлен!».',
      text: 'Фото • Название • Категория • кг/шт • Цена → «Сохранить»',
      vo: 'iMag-та тауар қосу оңай: фото, атауы, санаты, кг не дана, бағасы — «Сохранить».', voAt: .2,
      sfx: [[0.6, 'camera'], [1.5, 'type', .5], [1.65, 'type', .5], [1.8, 'type', .5], [1.95, 'type', .5], [2.1, 'type', .5], [2.9, 'tap'], [3.6, 'tap'], [4.3, 'type', .5], [4.45, 'type', .5], [4.6, 'type', .5], [4.75, 'type', .5], [5.6, 'tap'], [5.7, 'success']], tr: 'zoom',
      draw(c, t) {
        bgFlat(c, '#ECFDF5'); const name = 'Шұбат'.slice(0, Math.floor(clamp((t - 1.5) / .15, 0, 5))); const price = '1200'.slice(0, Math.floor(clamp((t - 4.3) / .15, 0, 4)));
        T(c, { x: 60, y: 500 }, () => v08Form(c, 960, 640, { photo: ease(t, .6, 1.0, E.back), name, cat: t > 2.9 ? 'Молочное' : '', unit: t > 3.6 ? 'шт' : 'кг', price, active: t < 1.4 ? -1 : t < 2.8 ? 0 : t < 3.5 ? 1 : t < 4.2 ? 2 : t < 5.5 ? 3 : -1, saveHl: t > 5.6 && t < 5.9 }));
        if (t > .55 && t < .75) { c.fillStyle = `rgba(255,255,255,${1 - (t - .55) * 5})`; c.fillRect(0, 0, W, H); }
        if (t > 5.4 && t < 6) finger(c, 900, 1100, 1, P(t, 5.5, 5.65));
        toast(c, 'Товар успешно добавлен!', P(t, 5.7, 7.6), BRAND.pay, 1350);
        headline(c, 'Тауар қосу — бір форма', 260, t, { size: 78, delay: .1, hl: ['бір'], hlCol: BRAND.pay });
      } },
    { d: 6.0, shot: 'Касса экраны: «Молочное» санаты басылады; «Шұбат» плиткасы суретімен торға «секіріп» кіреді; саусақ басып, себетке қосады.',
      text: '«Шұбат — 1200 ₸/шт» кассада суретімен', vo: 'Сол сәтте тауар кассада суретімен шығады — санат бойынша табу оңай.', voAt: .2,
      sfx: [[0.6, 'tap'], [1.0, 'pop'], [3.0, 'tap'], [3.1, 'pop', .7]], tr: 'slide',
      draw(c, t) {
        bgFlat(c, '#F0FDF4'); const tiles = [{ name: 'Сүт', price: '450 ₸/шт', col: '#DBEAFE', icon: (c, x, y, s) => bottle(c, x, y + 20, s / 200) }, { name: 'Айран', price: '380 ₸/шт', col: '#E0F2FE', icon: (c, x, y, s) => bottle(c, x, y + 20, s / 200, '#fff', '#22C55E', '#DCFCE7') }];
        if (t > 1.0) tiles.push({ name: 'Шұбат', price: '1200 ₸/шт', col: '#FEF3C7', icon: (c, x, y, s) => bottle(c, x, y + 20, s / 200 * (t < 1.5 ? E.back(clamp((t - 1) * 2)) : 1), '#FFFBEB', '#B45309', '#FDE68A') });
        T(c, { x: 540, y: 520 }, () => { rr(c, -500, 0, 1000, 640, 26, '#111827'); c.save(); c.translate(-480, 20); rr(c, 0, 0, 960, 600, 10); c.clip();
          posScreen(c, 960, 600, { cats: ['Все', 'Мясо', 'Молочное', 'Хлеб'], cat: t > .6 ? 2 : 0, tiles, hl: t > 1.0 && t < 2.6 ? 2 : -1, hlp: 1, items: t > 3.1 ? [{ name: 'Шұбат', qty: '1 шт', sum: '1 200', a: ease(t, 3.1, 3.4) }] : [], total: t > 3.1 ? '1 200' : '0' }); c.restore(); });
        if (t > .3 && t < .9) finger(c, 455, 680, 1, P(t, .45, .6)); if (t > 2.7 && t < 3.4) finger(c, 640, 900, 1, P(t, 2.9, 3.05));
        person(c, who('newOwner', { x: 540, y: 1880, s: .9, mouth: 'big', armR: 2.3, armL: .2, holdR: () => { rr(c, -18, -40, 36, 50, 14, '#D7A07B'); rr(c, -10, -70, 20, 40, 10, '#D7A07B'); } }));
        chip(c, 540, 330, 'Санат бойынша — бір басу', BRAND.pay, '#fff', 40, P(t, 1.4, 1.8));
      } },
    { d: 4.6, shot: '«Товары» кестесі: «Құрт — 4500 ₸» жолында қаламша белгісі басылады; баға өрісі ашылып 4800 теріледі; жасыл белгі.',
      text: '«Баға өзгерді? — бір басумен түзету»', vo: 'Баға өзгерді ме? Тізімнен бір басып түзетесіз.', voAt: .2,
      sfx: [[0.6, 'tap'], [1.3, 'type', .5], [1.45, 'type', .5], [1.6, 'type', .5], [1.75, 'type', .5], [2.4, 'tap'], [2.5, 'success', .7]], tr: 'wipe',
      draw(c, t) {
        bgFlat(c, '#F8FAFC'); const editing = t > .6 && t < 2.4, price = t < 1.3 ? '4500' : '4800'.slice(0, Math.floor(clamp((t - 1.3) / .15, 1, 4)));
        T(c, { x: 60, y: 560 }, () => { rr(c, 0, 0, 960, 700, 30, '#fff'); txt(c, 'Товары', 40, 60, { size: 42, weight: 800, align: 'left' });
          ['Название', 'Категория', 'Ед.', 'Цена', ''].forEach((hd, i) => txt(c, hd, [40, 330, 560, 680, 880][i], 140, { size: 24, weight: 600, align: 'left', color: '#94A3B8' }));
          [['Шұбат', 'Молочное', 'шт', '1200'], ['Құрт', 'Молочное', 'кг', null], ['Нан', 'Хлеб', 'шт', '250'], ['Сүт', 'Молочное', 'шт', '450']].forEach((r, i) => { const ry = 200 + i * 110, hl = i === 1;
            rr(c, 20, ry - 40, 920, 90, 16, hl && editing ? '#EFF6FF' : (i % 2 ? '#fff' : '#F8FAFC'));
            txt(c, r[0], 40, ry, { size: 32, weight: 700, align: 'left' }); txt(c, r[1], 330, ry, { size: 28, weight: 500, align: 'left', color: '#475569' }); txt(c, r[2], 560, ry, { size: 28, weight: 500, align: 'left', color: '#475569' });
            if (hl) { if (editing) { rr(c, 660, ry - 32, 180, 64, 12, '#fff'); c.strokeStyle = BRAND.blue; c.lineWidth = 3; rr(c, 660, ry - 32, 180, 64, 12); c.stroke(); } txt(c, price + ' ₸', 680, ry, { size: 32, weight: 800, align: 'left', color: t > 2.4 ? BRAND.pay : BRAND.ink }); }
            else txt(c, r[3] + ' ₸', 680, ry, { size: 30, weight: 700, align: 'left' });
            rr(c, 870, ry - 26, 52, 52, 12, hl && t > .5 && t < .8 ? BRAND.blue : '#F1F5F9'); line(c, 884, ry + 12, 906, ry - 10, hl && t > .5 && t < .8 ? '#fff' : '#64748B', 5); }); });
        if (t > .3 && t < .9) finger(c, 956, 860, .9, P(t, .45, .6)); check(c, 900, 1420, .8, ease(t, 2.5, 2.8));
        headline(c, 'Баға өзгерді ме?', 280, t, { size: 88, delay: .1 });
      } },
    { d: 4.2, shot: 'Соңғы кадр.', text: 'iMag Kassa • «Әр теңге — есепте.» • «Жаңа тауар — бір минутта»', vo: 'iMag Kassa. Әр теңге — есепте.', voAt: .6, noCap: true,
      sfx: [[0.1, 'whoosh'], [0.35, 'logo_hit'], [1.0, 'sparkle', .6]], tr: 'wipe', draw(c, t) { endcard(c, t, 'Жаңа тауар — бір минутта'); } },
  ],
};
