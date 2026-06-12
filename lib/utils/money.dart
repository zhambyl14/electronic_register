/// Денежный формат: целые суммы без дробной части, дробные (тиыны с
/// весовых этикеток, например 709.5) — с точностью до тиына, без
/// лишних нулей: 710 → «710», 709.5 → «709.5», 709.55 → «709.55».
String formatMoney(num value) {
  // Нормализуем двоичные хвосты double (709.4999999 → 709.5)
  final v = (value * 100).round() / 100;
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  final s = v.toStringAsFixed(2);
  return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
}
