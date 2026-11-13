"""Line-by-line Python ports of iMag Kassa's pure Dart logic, checked with real numbers.

Every claim shown in the ads is checked here or confirmed by reading the code.
Sources: lib/utils/money.dart, lib/screens/cashier_screen.dart (_handleBarcode),
lib/services/scale_service_io.dart (_parseWeight), lib/screens/payment_screen.dart,
lib/providers/sales_provider.dart (processReturn, averageCheck, cash/cardRevenue).
"""
import re

def format_money(value):                       # utils/money.dart
    v = round(value * 100) / 100
    if v == round(v):
        return f"{v:.0f}"
    s = f"{v:.2f}"
    return s[:-1] if s.endswith("0") else s

PRODUCTS = [  # (name, unit, price, plu)
    ("Сиыр еті", "kg", 4200, 1),
    ("Қой еті", "kg", 4600, 2),
    ("Фарш", "kg", 3800, 3),
    ("Қазы", "pcs", 6500, 4870001),
    ("Сыр", "kg", 4300, 15),
]

def handle_barcode(code):                      # cashier_screen.dart _handleBarcode
    if len(code) == 13:
        prefix = int(code[0:2])
        if 20 <= prefix <= 29:
            plu = int(code[2:7]); raw = int(code[7:12])
            m = [p for p in PRODUCTS if p[3] == plu]
            if not m:
                return ("error", f"Товар с кодом PLU {plu} не найден")
            name, unit, price, _ = m[0]
            if unit == "kg" and raw > 0 and price > 0:
                total = raw / 100.0
                weight = total / price
                return ("weighed", name, round(weight, 3), format_money(weight * price))
            return ("added", name)
    if code.isdigit():
        m = [p for p in PRODUCTS if p[3] == int(code)]
        if m:
            return ("added", m[0][0])
    return ("error", f"Штрих-код не распознан: {code}")

def parse_weight(line):                        # scale_service_io.dart _parseWeight
    for mm in re.finditer(r"[\+\-]?\s*(\d+\.?\d*)", line):
        try:
            v = float(mm.group(1))
        except ValueError:
            continue
        if 0 <= v < 1000:
            return v
    return None

def cash_change(total, paid):                  # payment_screen.dart _change
    return max(paid - total, 0)

def combined_card_autofill(total, cash):       # payment_screen.dart _onNumpad (combined)
    return format_money(total - cash) if cash <= total else "0"

def return_split(orig_total, orig_cash, orig_card, return_total):  # sales_provider.processReturn
    ratio = return_total / orig_total
    return -(orig_cash * ratio), -(orig_card * ratio)

ok = 0
def check(label, got, want):
    global ok
    assert got == want, f"{label}: got {got!r}, want {want!r}"
    ok += 1
    print(f"OK  {label}: {got}")

# 1. Money format: tiyn precision without trailing zeros
check("formatMoney(710)", format_money(710), "710")
check("formatMoney(709.5)", format_money(709.5), "709.5")
check("formatMoney(709.55)", format_money(709.55), "709.55")

# 2. Weighted label barcode (Rongta type 2): 20 | PLU 00001 | sum 2394.00 -> 239400 | check digit
# 20 | PLU 00015 | sum 709.50 -> 70950 | check digit 0
check("label 709.50 tg, cheese 4300/kg", handle_barcode("2000015709500"), ("weighed", "Сыр", 0.165, "709.5"))
check("label 239.40 tg, beef 4200/kg", handle_barcode("2000001239400"), ("weighed", "Сиыр еті", 0.057, "239.4"))
# LIMIT: the sum field is 5 digits in tiyn, so a label can carry at most 999.99 tg
check("max label sum", format_money(int("99999") / 100), "999.99")
check("unknown PLU on label", handle_barcode("2000099100000"), ("error", "Товар с кодом PLU 99 не найден"))
check("ordinary barcode = PLU", handle_barcode("4870001"), ("added", "Қазы"))
check("unknown barcode", handle_barcode("123456"), ("error", "Штрих-код не распознан: 123456"))

# 3. Scale serial line parsing (typical scale outputs)
check("scale 'ST,GS,+  1.250kg'", parse_weight("ST,GS,+  1.250kg"), 1.25)
check("scale '  0.785'", parse_weight("  0.785"), 0.785)

# 4. Payments
check("cash: total 4830, paid 5000 -> change", cash_change(4830, 5000), 170)
check("combined: total 7350, cash 3000 -> card autofill", combined_card_autofill(7350, 3000), "4350")

# 5. Proportional return on a mixed payment
cash, card = return_split(7350, 3000, 4350, 2450)
check("return 2450 of mixed 3000+4350 -> cash part", round(cash, 2), -1000.0)
check("return 2450 of mixed 3000+4350 -> card part", round(card, 2), -1450.0)

print(f"\nAll {ok} checks passed.")
