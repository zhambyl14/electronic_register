import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/money.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _receiptController = TextEditingController();
  Sale? _foundSale;
  List<bool> _selectedItems = [];
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _errorMsg;
  String? _successMsg;

  @override
  void dispose() {
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _searchSale() async {
    final input = _receiptController.text.trim();
    final receiptNumber = int.tryParse(input);
    if (receiptNumber == null) {
      setState(() => _errorMsg = 'Введите корректный номер чека');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMsg = null;
      _successMsg = null;
      _foundSale = null;
      _selectedItems = [];
    });

    try {
      final provider = context.read<SalesProvider>();
      final sale = await provider.findSaleByReceiptNumber(receiptNumber);
      if (!mounted) return;
      if (sale == null) {
        setState(() {
          _errorMsg = 'Чек #${receiptNumber.toString().padLeft(4, '0')} не найден';
          _isSearching = false;
        });
        return;
      }
      // Чек уже возвращался — повторный возврат запрещён
      final alreadyReturned = await provider.isSaleAlreadyReturned(sale);
      if (!mounted) return;
      if (alreadyReturned) {
        setState(() {
          _errorMsg =
              'По чеку #${receiptNumber.toString().padLeft(4, '0')} уже оформлен возврат. Повторный возврат невозможен.';
          _isSearching = false;
        });
        return;
      }
      setState(() {
        _foundSale = sale;
        _selectedItems = List.filled(sale.items.length, true);
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Ошибка поиска: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _processReturn() async {
    if (_foundSale == null) return;
    final selectedList = <SaleItem>[];
    for (int i = 0; i < _foundSale!.items.length; i++) {
      if (_selectedItems[i]) selectedList.add(_foundSale!.items[i]);
    }
    if (selectedList.isEmpty) {
      setState(() => _errorMsg = 'Выберите хотя бы один товар для возврата');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMsg = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await context.read<SalesProvider>().processReturn(
            originalSale: _foundSale!,
            itemsToReturn: selectedList,
            cashierName: auth.displayName,
          );
      if (!mounted) return;

      final returnTotal =
          selectedList.fold(0.0, (sum, item) => sum + item.total);
      setState(() {
        _successMsg =
            'Возврат оформлен: ${formatMoney(returnTotal)} ₸ вычтено из выручки';
        _foundSale = null;
        _selectedItems = [];
        _receiptController.clear();
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Ошибка возврата: $e';
        _isProcessing = false;
      });
    }
  }

  double get _returnTotal {
    if (_foundSale == null) return 0;
    double total = 0;
    for (int i = 0; i < _foundSale!.items.length; i++) {
      if (_selectedItems[i]) total += _foundSale!.items[i].total;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchCard(),
                    if (_errorMsg != null) ...[
                      const SizedBox(height: 12),
                      _buildAlert(_errorMsg!, isError: true),
                    ],
                    if (_successMsg != null) ...[
                      const SizedBox(height: 12),
                      _buildAlert(_successMsg!, isError: false),
                    ],
                    if (_foundSale != null) ...[
                      const SizedBox(height: 16),
                      _buildSaleCard(),
                      const SizedBox(height: 16),
                      _buildConfirmButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.assignment_return,
              color: Color(0xFFEF4444), size: 20),
          SizedBox(width: 10),
          Text(
            'Возврат товара',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Найти чек',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Введите номер чека для оформления возврата',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _receiptController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Номер чека (например: 42)',
                    prefixIcon: const Icon(Icons.receipt_long,
                        size: 18, color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  onSubmitted: (_) => _searchSale(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchSale,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 18),
                  label: const Text('Найти'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard() {
    final sale = _foundSale!;
    final allSelected = _selectedItems.every((s) => s);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sale header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Чек #${sale.receiptNumber.toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2332),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const Spacer(),
              _buildPaymentBadge(sale),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F2F5)),
          const SizedBox(height: 12),

          // Select all row
          Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (val) => setState(() {
                  _selectedItems = List.filled(
                      sale.items.length, val ?? false);
                }),
                activeColor: const Color(0xFF2563EB),
              ),
              const Text(
                'Выбрать все',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                'Итого чека: ${formatMoney(sale.total)} ₸',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),

          // Items
          ...sale.items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _selectedItems[i]
                    ? const Color(0xFFF0F7FF)
                    : const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedItems[i]
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFF0F2F5),
                ),
              ),
              child: CheckboxListTile(
                value: _selectedItems[i],
                onChanged: (val) => setState(() {
                  _selectedItems[i] = val ?? false;
                }),
                activeColor: const Color(0xFF2563EB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${item.quantity.toStringAsFixed(item.unit == 'кг' ? 3 : 0)} ${item.unit} × ${formatMoney(item.price)} ₸',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
                secondary: Text(
                  '${formatMoney(item.total)} ₸',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2332),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(Sale sale) {
    final Color bg;
    final Color fg;
    final String label;
    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'Наличные';
        break;
      case PaymentMethod.card:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        label = 'Карта';
        break;
      case PaymentMethod.combined:
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF6D28D9);
        label =
            'Нал+Карта (${formatMoney(sale.cashAmount ?? 0)}+${formatMoney(sale.cardAmount ?? 0)})';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    final selectedCount = _selectedItems.where((s) => s).length;

    return ElevatedButton.icon(
      onPressed: (_isProcessing || selectedCount == 0) ? null : _processReturn,
      icon: _isProcessing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.assignment_return, size: 20),
      label: Text(
        selectedCount == 0
            ? 'Выберите товары'
            : 'Оформить возврат — ${formatMoney(_returnTotal)} ₸',
        style:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE9ECEF),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAlert(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            isError ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError
              ? const Color(0xFFFECACA)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color:
                isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF065F46),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              if (isError) {
                _errorMsg = null;
              } else {
                _successMsg = null;
              }
            }),
            child: Icon(Icons.close,
                size: 14,
                color: isError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }
}
