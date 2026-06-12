import '../utils/money.dart';
import 'product.dart';

class CartItem {
  final String id;
  final Product product;
  final double quantity;
  final double? customPrice;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.customPrice,
  });

  double get effectivePrice => customPrice ?? product.price;
  double get total => effectivePrice * quantity;

  String get quantityLabel {
    if (product.isByWeight) {
      return '${quantity.toStringAsFixed(3)} кг';
    } else {
      return '${quantity.toInt()} шт';
    }
  }

  String get totalLabel => '${formatMoney(total)} ₸';
}
