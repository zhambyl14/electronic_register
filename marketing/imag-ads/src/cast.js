/* Continuity bible: each character keeps the same look in every scene. */
const CAST = {
  // iMag team member ("біз") — intro + real story only
  dev:     { body: 'm', skin: '#E3AE87', hair: '#1F1410', hs: 'short', top: '#2563EB', hoodie: true, logo: true, pants: '#1E293B', shoes: '#0F172A', glasses: true },
  // Ayazhan's brother — meat shop owner (real story)
  aga:     { body: 'stocky', skin: '#D9A07A', hair: '#1C1917', hs: 'short', mustache: true, top: '#7F1D1D', apron: { col: '#FFFFFF', stripe: '#DC2626' }, pants: '#292524', hat: 'takiya', hatCol: '#111827' },
  ayazhan: { body: 'f', skin: '#EDBE98', hair: '#24160F', hs: 'long', top: '#14B8A6', pants: '#334155' },
  // V02 fruit stall seller + grandmother customer
  fruitGirl: { body: 'f', skin: '#E8B48C', hair: '#3B2416', hs: 'pony', top: '#16A34A', apron: { col: '#BBF7D0' }, pants: '#14532D' },
  apa:     { body: 'f', skin: '#D8A07C', hair: '#9CA3AF', hat: 'scarf', scarf: '#9333EA', top: '#7C3AED', pants: '#4C1D95' },
  // V03 deli worker + checkout cashier
  deli:    { body: 'm', skin: '#EBC09C', hair: '#4A2F1E', hs: 'short', top: '#0D9488', apron: { col: '#F0FDFA' }, hat: 'cookcap', pants: '#134E4A', beard: true },
  checkoutBoy: { body: 'm', skin: '#F0C7A4', hair: '#111827', hs: 'curly', top: '#0EA5E9', glasses: true, pants: '#0C4A6E' },
  // V04 grocery owner (text-only) + customer
  grocer:  { body: 'f', skin: '#DDA886', hair: '#57351F', hs: 'bun', top: '#A855F7', glasses: true, pants: '#581C87' },
  guy:     { body: 'm', skin: '#C98E6A', hair: '#0F0F0F', hs: 'short', top: '#F97316', pants: '#1E3A8A' },
  // V05 bakery cashier + business woman
  baker:   { body: 'm', skin: '#E5B08B', hair: '#3F2A1D', hs: 'curly', top: '#FFFFFF', apron: { col: '#FDE68A' }, hat: 'baker', pants: '#78350F', flour: true },
  bizWoman:{ body: 'f', skin: '#F1C6A6', hair: '#1F1611', hs: 'long', top: '#1E40AF', collar: '#FFFFFF', pants: '#1E293B' },
  // V06 dairy seller + young father + kid
  dairy:   { body: 'f', skin: '#E2AD89', hair: '#2E2018', hs: 'bun', top: '#FFFFFF', apron: { col: '#DBEAFE' }, pants: '#1E3A8A', hat: 'cookcap', hatCol: '#BFDBFE' },
  dad:     { body: 'm', skin: '#D39B76', hair: '#18120E', hs: 'short', beard: true, top: '#65A30D', pants: '#3F3F46', hat: 'cap', hatCol: '#DC2626' },
  kid:     { body: 'kid', skin: '#E9B892', hair: '#2B1A10', hs: 'short', top: '#FACC15', pants: '#2563EB' },
  // V07 nuts shop owner (home, evening)
  owner:   { body: 'f', skin: '#DCA684', hair: '#3A2418', hs: 'bun', top: '#BE185D', pants: '#4A044E' },
  // V08 new shop owner
  newOwner:{ body: 'm', skin: '#D7A07B', hair: '#1A1A1A', hs: 'short', top: '#10B981', hat: 'cap', hatCol: '#1E293B', pants: '#334155' },
  // V09 first-day cashier
  rookie:  { body: 'm', skin: '#EFC3A0', hair: '#5B3A24', hs: 'short', top: '#F97316', pants: '#1F2937' },
  // V10 fish seller + accountant customer
  fisher:  { body: 'stocky', skin: '#C88E68', hair: '#27272A', hs: 'short', beard: true, top: '#0369A1', apron: { col: '#FACC15' }, hat: 'beanie', hatCol: '#0F766E', pants: '#1E293B' },
  accountant: { body: 'f', skin: '#EDC2A0', hair: '#7C2D12', hs: 'pony2', top: '#DB2777', glasses: true, pants: '#334155' },
};
const who = (k, o) => Object.assign({}, CAST[k], o);
