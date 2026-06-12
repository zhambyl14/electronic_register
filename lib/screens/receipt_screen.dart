import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/printer_service.dart';
import '../utils/money.dart';

class ReceiptScreen extends StatefulWidget {
  final Sale sale;

  const ReceiptScreen({super.key, required this.sale});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isPrinting = false;
  final PrinterService _printer = PrinterService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _printReceipt(auto: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (fixed)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Чек',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2332),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#${widget.sale.receiptNumber.toString().padLeft(4, '0')} · Сохранён ✓',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 20),

                // Scrollable receipt + fixed buttons
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildReceiptPreview(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          _ActionButton(
                            icon: Icons.print_outlined,
                            label: 'Распечатать\nещё раз',
                            color: const Color(0xFF2563EB),
                            isLoading: _isPrinting,
                            onTap: () => _printReceipt(),
                          ),
                          const SizedBox(height: 10),
                          _ActionButton(
                            icon: Icons.shopping_cart_outlined,
                            label: 'Новая\nпродажа',
                            color: const Color(0xFF10B981),
                            onTap: () => Navigator.of(context)
                                .popUntil((route) => route.isFirst),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final sale = widget.sale;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt);
    final shopName = sale.storeName ?? _printer.shopName;
    final ipName = _printer.ipName;
    final address = _printer.address;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ipName.isNotEmpty)
            Text(
              ipName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'Courier New',
                color: Colors.black87,
              ),
            ),
          Text(
            shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier New',
            ),
          ),
          if (address.isNotEmpty)
            Text(
              address,
              textAlign: TextAlign.center,
              style: const _MonoText(),
            ),
          const _Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: const _MonoText()),
              Text(
                  'Чек #${sale.receiptNumber.toString().padLeft(4, '0')}',
                  style: const _MonoText()),
            ],
          ),
          Text('Кассир: ${sale.cashierName ?? 'Кассир'}',
              style: const _MonoText()),

          const _Divider(),

          ...sale.items.map((item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0)} ${item.unit} × ${item.price.toStringAsFixed(0)} ₸',
                        style: const _MonoText(),
                      ),
                      Text(
                        '${formatMoney(item.total)} ₸',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              )),

          const _Divider(thick: true),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ИТОГО:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier New',
                  )),
              Text('${formatMoney(sale.total)} ₸',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier New',
                  )),
            ],
          ),

          const SizedBox(height: 4),

          if (sale.paymentMethod == PaymentMethod.combined) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Наличные:', style: _MonoText()),
                Text('${formatMoney(sale.cashAmount ?? 0)} ₸',
                    style: const _MonoText()),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Карта:', style: _MonoText()),
                Text('${formatMoney(sale.cardAmount ?? 0)} ₸',
                    style: const _MonoText()),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Оплачено:', style: _MonoText()),
                Text('${formatMoney(sale.amountPaid)} ₸',
                    style: const _MonoText()),
              ],
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Сдача:', style: _MonoText()),
              Text('${formatMoney(sale.change)} ₸',
                  style: const _MonoText()),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Способ оплаты:', style: _MonoText()),
              Text(sale.paymentLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier New',
                  )),
            ],
          ),

          const _Divider(),

          const Text(
            'Спасибо за покупку! Ждём вас снова!',
            textAlign: TextAlign.center,
            style: _MonoText(),
          ),
        ],
      ),
    );
  }

  Future<void> _printReceipt({bool auto = false}) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      await _printer.printReceipt(widget.sale);
    } catch (e) {
      if (mounted && !auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка принтера: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}

class _MonoText extends TextStyle {
  const _MonoText()
      : super(
            fontSize: 11, fontFamily: 'Courier New', color: Colors.black87);
}

class _Divider extends StatelessWidget {
  final bool thick;
  const _Divider({this.thick = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(
        height: 1,
        thickness: thick ? 1.0 : 0.5,
        color: Colors.grey.shade400,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 80,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.all(8),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }
}
