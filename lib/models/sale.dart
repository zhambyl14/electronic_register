import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum PaymentMethod { cash, card, combined }

class SaleItem {
  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double price;
  final double total;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory SaleItem.fromCartItem(CartItem item) {
    return SaleItem(
      productId: item.product.id,
      productName: item.product.name,
      unit: item.product.unitLabel,
      quantity: item.quantity,
      price: item.effectivePrice,
      total: item.total,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unit': unit,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      price: (map['price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }
}

class Sale {
  final String id;
  final List<SaleItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final double amountPaid;
  final double change;
  final DateTime createdAt;
  final String? cashierName;
  final int receiptNumber;
  final String? userId;
  final String? storeName;
  final bool isReturn;
  // По этому чеку уже оформлен возврат — повторный возврат запрещён
  final bool isReturned;
  final String? originalSaleId;
  final double? cashAmount;
  final double? cardAmount;

  Sale({
    required this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.amountPaid,
    required this.change,
    required this.createdAt,
    this.cashierName,
    required this.receiptNumber,
    this.userId,
    this.storeName,
    this.isReturn = false,
    this.isReturned = false,
    this.originalSaleId,
    this.cashAmount,
    this.cardAmount,
  });

  String get paymentLabel {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'НАЛИЧНЫЕ';
      case PaymentMethod.card:
        return 'КАРТА';
      case PaymentMethod.combined:
        return 'НАЛ+КАРТА';
    }
  }

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    PaymentMethod method;
    switch (data['paymentMethod']) {
      case 'card':
        method = PaymentMethod.card;
        break;
      case 'combined':
        method = PaymentMethod.combined;
        break;
      default:
        method = PaymentMethod.cash;
    }
    return Sale(
      id: doc.id,
      items: (data['items'] as List<dynamic>)
          .map((e) => SaleItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: method,
      amountPaid: (data['amountPaid'] as num).toDouble(),
      change: (data['change'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cashierName: data['cashierName'],
      receiptNumber: data['receiptNumber'] ?? 0,
      userId: data['userId'],
      storeName: data['storeName'],
      isReturn: data['isReturn'] == true,
      isReturned: data['isReturned'] == true,
      originalSaleId: data['originalSaleId'],
      cashAmount: (data['cashAmount'] as num?)?.toDouble(),
      cardAmount: (data['cardAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    String pmStr;
    switch (paymentMethod) {
      case PaymentMethod.card:
        pmStr = 'card';
        break;
      case PaymentMethod.combined:
        pmStr = 'combined';
        break;
      default:
        pmStr = 'cash';
    }
    return {
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'paymentMethod': pmStr,
      'amountPaid': amountPaid,
      'change': change,
      'createdAt': Timestamp.fromDate(createdAt),
      'cashierName': cashierName ?? 'Кассир',
      'receiptNumber': receiptNumber,
      'isReturn': isReturn,
      'isReturned': isReturned,
      if (userId != null) 'userId': userId,
      if (storeName != null) 'storeName': storeName,
      if (originalSaleId != null) 'originalSaleId': originalSaleId,
      if (cashAmount != null) 'cashAmount': cashAmount,
      if (cardAmount != null) 'cardAmount': cardAmount,
    };
  }
}
