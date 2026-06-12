import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/cart_item.dart';
import '../providers/products_provider.dart';
import '../providers/cart_provider.dart';
import '../services/app_log.dart';
import '../utils/money.dart';
import 'payment_screen.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  // ── Сканер штрих-кодов (USB, режим клавиатуры) ──────────────────────────
  // Сканер «печатает» цифры очень быстро и завершает Enter-ом. Копим цифры,
  // пришедшие с паузой <150 мс; ручной ввод с такой скоростью не печатают,
  // поэтому обычные поля не затрагиваются.
  final StringBuffer _scanBuffer = StringBuffer();
  DateTime _lastScanKey = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onScannerKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onScannerKey);
    _searchController.dispose();
    super.dispose();
  }

  bool _onScannerKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final now = DateTime.now();
    if (now.difference(_lastScanKey).inMilliseconds > 150) {
      _scanBuffer.clear();
    }
    _lastScanKey = now;

    final ch = event.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 0x30 &&
        ch.codeUnitAt(0) <= 0x39) {
      _scanBuffer.write(ch);
      return false;
    }
    if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
        _scanBuffer.length >= 6) {
      final code = _scanBuffer.toString();
      _scanBuffer.clear();
      _handleBarcode(code);
      return true; // Enter сканера не передаём полям ввода
    }
    return false;
  }

  // Весовой штрих-код Rongta тип 2 (EAN-13): ПП XXXXX SSSSS К
  // ПП — префикс (20–29), XXXXX — код PLU, SSSSS — итоговая СУММА в тиынах
  // (этикетка «230.00» → «23000»), К — контрольная цифра. Вес на этикетке
  // в код не входит — восстанавливаем его по цене товара.
  void _handleBarcode(String code) {
    final products = context.read<ProductsProvider>().products;
    final cart = context.read<CartProvider>();

    if (code.length == 13) {
      final prefix = int.tryParse(code.substring(0, 2)) ?? 0;
      if (prefix >= 20 && prefix <= 29) {
        final plu = int.tryParse(code.substring(2, 7));
        final raw = int.tryParse(code.substring(7, 12));
        if (plu != null && raw != null) {
          final matches = products.where((p) => p.plu == plu);
          if (matches.isNotEmpty) {
            final product = matches.first;
            if (product.isByWeight && raw > 0 && product.price > 0) {
              final sum = raw / 100.0; // тиыны → тенге
              // Вес НЕ округляем: иначе сумма уезжает (709.5 → 710).
              // Точный вес × цена даёт ровно сумму с этикетки.
              final weight = sum / product.price;
              if (weight > 0) {
                cart.addProductWeighed(product, weight);
                _scanFeedback('${product.name} — '
                    '${weight.toStringAsFixed(3)} кг, '
                    '${formatMoney(sum)} ₸');
                return;
              }
            }
            cart.addProduct(product);
            _scanFeedback(product.name);
            return;
          }
          _scanFeedback('Товар с кодом PLU $plu не найден', error: true);
          return;
        }
      }
    }

    // Обычный штрих-код: ищем точное совпадение с PLU
    final asNumber = int.tryParse(code);
    if (asNumber != null) {
      final matches = products.where((p) => p.plu == asNumber);
      if (matches.isNotEmpty) {
        cart.addProduct(matches.first);
        _scanFeedback(matches.first.name);
        return;
      }
    }
    _scanFeedback('Штрих-код не распознан: $code', error: true);
  }

  void _scanFeedback(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      backgroundColor:
          error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
    ));
  }

  // При выборе категории сбрасываем поиск — иначе старый запрос
  // незаметно фильтрует товары внутри категории
  void _selectCategory(String categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  String _getCategoryDisplayName(String categoryId) {
    for (final cat in defaultCategories) {
      if (cat.id == categoryId) return cat.name;
    }
    return categoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildScaleWidget(context),
                    _buildCategoryChips(),
                    Expanded(child: _buildProductGrid(context)),
                  ],
                ),
              ),
              SizedBox(
                width: 330,
                child: _buildCartPanel(context),
              ),
            ],
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
      child: Row(
        children: [
          const Text(
            'Касса',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v.toLowerCase();
                if (v.isNotEmpty) _selectedCategoryId = 'all';
              }),
              decoration: InputDecoration(
                hintText: 'Поиск товара...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Color(0xFFADB5BD)),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        // Тек бар өнімдердің категориялары
        final categories = <String, String>{};
        for (final product in provider.products) {
          if (product.categoryId != null && product.categoryId!.isNotEmpty) {
            categories[product.categoryId!] =
                _getCategoryDisplayName(product.categoryId!);
          }
        }

        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'Все',
                  isSelected: _selectedCategoryId == 'all',
                  onTap: () => _selectCategory('all'),
                ),
                ...categories.entries.map((entry) => _CategoryChip(
                      label: entry.value,
                      isSelected: _selectedCategoryId == entry.key,
                      onTap: () => _selectCategory(entry.key),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScaleWidget(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Весы',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3D0A),
                      border: Border.all(color: const Color(0xFF1A6B1A)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cart.scaleWeight.toStringAsFixed(3),
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        color: Color(0xFF00FF41),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'кг',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cart.scaleConnected
                          ? const Color(0xFF00FF41)
                          : Colors.grey,
                      boxShadow: cart.scaleConnected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00FF41)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (!cart.scaleConnected)
                Text(
                  'Весы не подключены\n(Настройте COM-порт в Настройках)',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.right,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Ошибка:\n${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final uid = provider.uid;
                    if (uid != null) provider.loadProducts(uid);
                  },
                  child: const Text('Обновить'),
                ),
              ],
            ),
          );
        }

        final products = provider.getFiltered(
          categoryId: _selectedCategoryId,
          searchQuery: _searchQuery,
        );

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'Нет товаров.\nДобавьте их в разделе «Товары».'
                      : 'По запросу «$_searchQuery» ничего не найдено.',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Товары (${products.length})',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 10),
                  _legend(color: const Color(0xFFF59E0B), label: 'кг'),
                  const SizedBox(width: 6),
                  _legend(color: const Color(0xFF10B981), label: 'шт'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _ProductButton(product: products[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legend({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _buildCartPanel(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Color(0xFFE9ECEF))),
          ),
          child: Column(
            children: [
              // Cart header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  border:
                      Border(bottom: BorderSide(color: Color(0xFF374151))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Корзина',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (cart.itemCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${cart.itemCount} поз.',
                          style: const TextStyle(
                              color: Color(0xFF2563EB), fontSize: 11),
                        ),
                      ),
                    if (!cart.isEmpty) ...[
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _confirmClear(context, cart),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.delete_outline,
                                color: Color(0xFFEF4444), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Cart items
              Expanded(
                child: cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            const Text(
                              'Корзина пуста\nНажмите на товар',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFFADB5BD), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return _CartItemRow(
                            item: item,
                            index: index,
                            onRemove: () => cart.removeItem(item.id),
                            onQuantityChange: (q) =>
                                cart.updateQuantity(item.id, q),
                            onPriceEdit: () =>
                                _showPriceEditDialog(context, item, cart),
                            onWeightEdit: () =>
                                _showWeightEditDialog(context, item, cart),
                          );
                        },
                      ),
              ),

              // Total
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  border:
                      Border(top: BorderSide(color: Color(0xFFE9ECEF))),
                ),
                child: Row(
                  children: [
                    const Text('Итого',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280))),
                    const Spacer(),
                    Text(
                      cart.totalLabel,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2332),
                      ),
                    ),
                  ],
                ),
              ),

              // Pay button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PaymentScreen()),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE9ECEF),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: cart.isEmpty
                        ? const Text('К оплате',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, size: 20),
                              const SizedBox(width: 8),
                              const Text('К оплате',
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cart.totalLabel,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPriceEditDialog(
      BuildContext context, CartItem item, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => _PriceEditDialog(
        item: item,
        onConfirm: (newPrice) => cart.updateItemPrice(item.id, newPrice),
      ),
    );
  }

  void _showWeightEditDialog(
      BuildContext context, CartItem item, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => _WeightEditDialog(
        item: item,
        onConfirm: (newWeight) => cart.updateQuantity(item.id, newWeight),
      ),
    );
  }

  void _confirmClear(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Очистить корзину'),
        content: const Text('Удалить все товары из корзины?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, очистить',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Диалог редактирования цены ──────────────────────────────────────────────

class _PriceEditDialog extends StatefulWidget {
  final CartItem item;
  final ValueChanged<double> onConfirm;
  const _PriceEditDialog({required this.item, required this.onConfirm});

  @override
  State<_PriceEditDialog> createState() => _PriceEditDialogState();
}

class _PriceEditDialogState extends State<_PriceEditDialog> {
  String _input = '';

  @override
  void initState() {
    super.initState();
    _input = widget.item.effectivePrice.toStringAsFixed(0);
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (key == 'C') {
        _input = '';
      } else {
        _input += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_input) ?? 0;
    return AlertDialog(
      title: Text(
        'Цена: ${widget.item.product.name}',
        style: const TextStyle(fontSize: 15),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price display
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Цена (₸):',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                  Text(
                    '${_input.isEmpty ? '0' : _input} ₸',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2332),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Numpad
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.4,
              children: ['7', '8', '9', '4', '5', '6', '1', '2', '3', 'C', '0', '⌫']
                  .map((key) {
                final isAction = key == '⌫' || key == 'C';
                return GestureDetector(
                  onTap: () => _onKey(key),
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: price > 0
              ? () {
                  widget.onConfirm(price);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Применить'),
        ),
      ],
    );
  }
}

// ── Диалог ручного ввода веса (когда весы не подключены) ───────────────────

class _WeightEditDialog extends StatefulWidget {
  final CartItem item;
  final ValueChanged<double> onConfirm;
  const _WeightEditDialog({required this.item, required this.onConfirm});

  @override
  State<_WeightEditDialog> createState() => _WeightEditDialogState();
}

class _WeightEditDialogState extends State<_WeightEditDialog> {
  String _input = '';

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
      } else if (key == 'C') {
        _input = '';
      } else if (key == '.') {
        if (_input.isEmpty) {
          _input = '0.';
        } else if (!_input.contains('.')) {
          _input += '.';
        }
      } else {
        // Не больше 3 знаков после точки (граммы)
        final dot = _input.indexOf('.');
        if (dot != -1 && _input.length - dot > 3) return;
        _input += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(_input) ?? 0;
    final price = widget.item.effectivePrice;
    return AlertDialog(
      title: Text(
        'Вес: ${widget.item.product.name}',
        style: const TextStyle(fontSize: 15),
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Вес (кг):',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                  Text(
                    _input.isEmpty ? '0' : _input,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2332),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Сразу видно сумму за введённый вес
            Text(
              'Сумма: ${(weight * price).toStringAsFixed(0)} ₸ '
              '(${price.toStringAsFixed(0)} ₸/кг)',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.4,
              children: [
                '7', '8', '9',
                '4', '5', '6',
                '1', '2', '3',
                '.', '0', '⌫',
              ].map((key) {
                final isAction = key == '⌫';
                return GestureDetector(
                  onTap: () => _onKey(key),
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
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: weight > 0
              ? () {
                  widget.onConfirm(weight);
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Применить'),
        ),
      ],
    );
  }
}

// ── Cart item row ────────────────────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChange;
  final VoidCallback onPriceEdit;
  final VoidCallback onWeightEdit;

  const _CartItemRow({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onQuantityChange,
    required this.onPriceEdit,
    required this.onWeightEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasCustomPrice = item.customPrice != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFBFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: item.product.isByWeight
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A2332),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!item.product.isByWeight) ...[
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => onQuantityChange(item.quantity - 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item.quantityLabel,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => onQuantityChange(item.quantity + 1),
                      ),
                    ] else
                      // Вес — басқанда қолмен енгізуге болады
                      GestureDetector(
                        onTap: onWeightEdit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.quantityLabel,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  size: 12, color: Color(0xFF92400E)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.totalLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2332),
                ),
              ),
              const SizedBox(height: 2),
              // Баға — басқанда өзгертуге болады
              GestureDetector(
                onTap: onPriceEdit,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasCustomPrice
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(4),
                    border: hasCustomPrice
                        ? Border.all(color: const Color(0xFFF59E0B))
                        : null,
                  ),
                  child: Text(
                    '${item.effectivePrice.toStringAsFixed(0)} ₸/${item.product.unitLabel}',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasCustomPrice
                          ? const Color(0xFF92400E)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close,
                        size: 16, color: Color(0xFFADB5BD)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4A5568),
          ),
        ),
      ),
    );
  }
}

// ── Quantity button ──────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18, color: const Color(0xFF4A5568)),
        ),
      ),
    );
  }
}

// ── Product button ───────────────────────────────────────────────────────────

class _ProductButton extends StatelessWidget {
  final Product product;
  const _ProductButton({required this.product});

  @override
  Widget build(BuildContext context) {
    final isKg = product.isByWeight;
    final accentColor =
        isKg ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final hasImage =
        product.imageUrl != null && product.imageUrl!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.read<CartProvider>().addProduct(product),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: hasImage
                ? _ImageCard(product: product, accentColor: accentColor)
                : _TextCard(
                    product: product,
                    accentColor: accentColor,
                    isKg: isKg,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final Product product;
  final Color accentColor;
  const _ImageCard({required this.product, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: product.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: const Color(0xFFF0F2F5),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          // Кэш-менеджер на части POS-машин не работает (диск/sqlite) —
          // тогда грузим картинку напрямую без кэша; причину пишем в лог.
          errorWidget: (_, url, error) {
            appLog('Фото: кэш не сработал ($error), пробуем напрямую: $url');
            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, err, __) {
                appLog('Фото: прямая загрузка не удалась: $err');
                return Container(
                  color: const Color(0xFFF0F2F5),
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Color(0xFFADB5BD)),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 24, 8, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  product.priceLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TextCard extends StatelessWidget {
  final Product product;
  final Color accentColor;
  final bool isKg;
  const _TextCard(
      {required this.product,
      required this.accentColor,
      required this.isKg});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 4, color: accentColor),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2332),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.priceLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isKg
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isKg ? 'кг' : 'шт',
                    style: TextStyle(
                      fontSize: 11,
                      color: isKg
                          ? const Color(0xFF92400E)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
