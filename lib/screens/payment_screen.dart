import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/money.dart';
import 'receipt_screen.dart';

enum _CombinedField { cash, card }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  String _amountInput = '';
  String _cashInput = '';
  String _cardInput = '';
  _CombinedField _activeField = _CombinedField.cash;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final total = context.read<CartProvider>().total;
    _amountInput = formatMoney(total);
  }

  double get _total => context.read<CartProvider>().total;
  double get _amountPaid => double.tryParse(_amountInput) ?? _total;
  double get _change => (_amountPaid - _total).clamp(0, double.infinity);

  double get _combinedCash => double.tryParse(_cashInput) ?? 0;
  double get _combinedCard => double.tryParse(_cardInput) ?? 0;
  double get _combinedChange =>
      (_combinedCash + _combinedCard - _total).clamp(0, double.infinity);

  void _selectMethod(PaymentMethod method) {
    setState(() {
      _selectedMethod = method;
      if (method == PaymentMethod.combined) {
        _cashInput = '';
        _cardInput = formatMoney(_total);
        _activeField = _CombinedField.cash;
      }
    });
  }

  void _onNumpad(String key) {
    setState(() {
      if (_selectedMethod == PaymentMethod.combined) {
        if (_activeField == _CombinedField.cash) {
          _cashInput = _applyKey(_cashInput, key);
          final cash = double.tryParse(_cashInput) ?? 0;
          if (cash <= _total) {
            _cardInput = formatMoney(_total - cash);
          } else {
            _cardInput = '0';
          }
        } else {
          _cardInput = _applyKey(_cardInput, key);
        }
      } else {
        _amountInput = _applyKey(_amountInput, key);
      }
    });
  }

  String _applyKey(String current, String key) {
    if (key == '⌫') {
      return current.isNotEmpty
          ? current.substring(0, current.length - 1)
          : current;
    } else if (key == 'C') {
      return '';
    } else if (key == '.' && current.contains('.')) {
      return current;
    }
    return current + key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      body: Center(
        child: Container(
          width: 440,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payment,
                        color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Оплата',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2332),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Consumer<CartProvider>(
                builder: (_, cart, __) => Text(
                  'Итого: ${cart.totalLabel}',
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),

              const SizedBox(height: 20),

              // Payment method
              const Text('Способ оплаты',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A5568))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _PaymentOption(
                      icon: Icons.money,
                      label: 'Наличные',
                      isSelected: _selectedMethod == PaymentMethod.cash,
                      onTap: () => _selectMethod(PaymentMethod.cash),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PaymentOption(
                      icon: Icons.credit_card,
                      label: 'Карта',
                      isSelected: _selectedMethod == PaymentMethod.card,
                      onTap: () => _selectMethod(PaymentMethod.card),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PaymentOption(
                      icon: Icons.payments_outlined,
                      label: 'Смешанная',
                      isSelected: _selectedMethod == PaymentMethod.combined,
                      onTap: () => _selectMethod(PaymentMethod.combined),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (_selectedMethod == PaymentMethod.cash) ...[
                _buildCashSection(),
                const SizedBox(height: 14),
                _buildNumpad(),
                const SizedBox(height: 14),
              ] else if (_selectedMethod == PaymentMethod.card) ...[
                _buildCardSection(),
                const SizedBox(height: 18),
              ] else ...[
                _buildCombinedSection(),
                const SizedBox(height: 14),
                _buildNumpad(),
                const SizedBox(height: 14),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Отмена',
                          style: TextStyle(color: Color(0xFF6B7280))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _confirmPayment,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Подтвердить',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Принято:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              Text(
                '${_amountInput.isEmpty ? '0' : _amountInput} ₸',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2332),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _change >= 0
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Сдача:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              Text(
                '${formatMoney(_change)} ₸',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _change >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Center(
        child: Text(
          'Оплата картой производится\nчерез терминал',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }

  Widget _buildCombinedSection() {
    final isCashActive = _activeField == _CombinedField.cash;
    final isCardActive = _activeField == _CombinedField.card;
    final totalSufficient = _combinedCash + _combinedCard >= _total;

    return Column(
      children: [
        // Cash field
        GestureDetector(
          onTap: () => setState(() => _activeField = _CombinedField.cash),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCashActive
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCashActive
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
                width: isCashActive ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.money,
                        size: 16,
                        color: isCashActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      'Наличные:',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCashActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_cashInput.isEmpty ? '0' : _cashInput} ₸',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isCashActive
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1A2332),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Card field
        GestureDetector(
          onTap: () => setState(() => _activeField = _CombinedField.card),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isCardActive
                  ? const Color(0xFFF0F7FF)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCardActive
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFE2E8F0),
                width: isCardActive ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card,
                        size: 16,
                        color: isCardActive
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    Text(
                      'Карта:',
                      style: TextStyle(
                        fontSize: 13,
                        color: isCardActive
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_cardInput.isEmpty ? '0' : _cardInput} ₸',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isCardActive
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF1A2332),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Change / validation row
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: totalSufficient
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalSufficient ? 'Сдача:' : 'Не хватает:',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
              ),
              Text(
                totalSufficient
                    ? '${formatMoney(_combinedChange)} ₸'
                    : '${formatMoney(_total - _combinedCash - _combinedCard)} ₸',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: totalSufficient
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    const keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['C', '0', '⌫'],
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.8,
      children: keys.expand((row) => row).map((key) {
        final isAction = key == '⌫' || key == 'C';
        return GestureDetector(
          onTap: () => _onNumpad(key),
          child: Container(
            decoration: BoxDecoration(
              color: isAction
                  ? const Color(0xFFF5F7FA)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            alignment: Alignment.center,
            child: Text(
              key,
              style: TextStyle(
                fontSize: key == '⌫' ? 16 : 18,
                fontWeight: FontWeight.w500,
                color: isAction
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1A2332),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _confirmPayment() async {
    if (_selectedMethod == PaymentMethod.cash && _amountPaid < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сумма оплаты меньше суммы чека!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMethod == PaymentMethod.combined &&
        _combinedCash + _combinedCard < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Общая сумма меньше суммы чека!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = context.read<CartProvider>();
      final salesProvider = context.read<SalesProvider>();
      final auth = context.read<AuthProvider>();

      final Sale sale;

      if (_selectedMethod == PaymentMethod.combined) {
        sale = Sale(
          id: '',
          items:
              cart.items.map((item) => SaleItem.fromCartItem(item)).toList(),
          total: _total,
          paymentMethod: PaymentMethod.combined,
          amountPaid: _combinedCash + _combinedCard,
          change: _combinedChange,
          cashAmount: _combinedCash,
          cardAmount: _combinedCard,
          createdAt: DateTime.now(),
          cashierName: auth.displayName,
          receiptNumber: 0,
          userId: auth.uid,
          storeName: auth.storeName,
        );
      } else {
        sale = Sale(
          id: '',
          items:
              cart.items.map((item) => SaleItem.fromCartItem(item)).toList(),
          total: _total,
          paymentMethod: _selectedMethod,
          amountPaid:
              _selectedMethod == PaymentMethod.cash ? _amountPaid : _total,
          change: _selectedMethod == PaymentMethod.cash ? _change : 0,
          createdAt: DateTime.now(),
          cashierName: auth.displayName,
          receiptNumber: 0,
          userId: auth.uid,
          storeName: auth.storeName,
        );
      }

      final savedSale = await salesProvider.saveSale(sale, uid: auth.uid!);
      cart.clearCart();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(sale: savedSale),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

class _PaymentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PaymentOption(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? const Color(0xFFF0FDF4)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
