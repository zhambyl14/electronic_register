import 'package:flutter/foundation.dart';
import '../utils/money.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../services/customer_display_service.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  double _scaleWeight = 0.0;
  bool _scaleConnected = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  double get scaleWeight => _scaleWeight;
  bool get scaleConnected => _scaleConnected;

  double get total => _items.fold(0, (sum, item) => sum + item.total);

  String get totalLabel => '${formatMoney(total)} ₸';

  @override
  void notifyListeners() {
    super.notifyListeners();
    CustomerDisplayService().updateCart(_items, total);
  }

  void updateScaleWeight(double weight) {
    _scaleWeight = weight;
    notifyListeners();
  }

  void setScaleConnected(bool connected) {
    _scaleConnected = connected;
    notifyListeners();
  }

  /// Добавление по весовому штрих-коду с этикетки: вес уже известен.
  void addProductWeighed(Product product, double weightKg) {
    _items.add(CartItem(
      id: const Uuid().v4(),
      product: product,
      quantity: weightKg,
    ));
    notifyListeners();
  }

  void addProduct(Product product) {
    double quantity;

    if (product.isByWeight) {
      quantity = _scaleWeight > 0 ? _scaleWeight : 0.001;
    } else {
      final existing = _items.where((i) => i.product.id == product.id);
      if (existing.isNotEmpty) {
        final idx = _items.indexWhere((i) => i.product.id == product.id);
        final old = _items[idx];
        _items[idx] = CartItem(
          id: old.id,
          product: old.product,
          quantity: old.quantity + 1,
          customPrice: old.customPrice,
        );
        notifyListeners();
        return;
      }
      quantity = 1;
    }

    _items.add(CartItem(
      id: const Uuid().v4(),
      product: product,
      quantity: quantity,
    ));
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    _scaleWeight = 0.0;
    notifyListeners();
  }

  void updateQuantity(String cartItemId, double newQuantity) {
    if (newQuantity <= 0) {
      removeItem(cartItemId);
      return;
    }
    final idx = _items.indexWhere((i) => i.id == cartItemId);
    if (idx != -1) {
      final old = _items[idx];
      _items[idx] = CartItem(
        id: old.id,
        product: old.product,
        quantity: newQuantity,
        customPrice: old.customPrice,
      );
      notifyListeners();
    }
  }

  void updateItemPrice(String cartItemId, double newPrice) {
    final idx = _items.indexWhere((i) => i.id == cartItemId);
    if (idx != -1) {
      final old = _items[idx];
      _items[idx] = CartItem(
        id: old.id,
        product: old.product,
        quantity: old.quantity,
        customPrice: newPrice > 0 ? newPrice : null,
      );
      notifyListeners();
    }
  }
}
