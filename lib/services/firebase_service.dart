import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';
import '../models/sale.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== PRODUCTS ====================

  Future<List<Product>> getProductsOnce(String uid) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();
    final products =
        snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
    products.sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  Future<String> addProduct(Product product, {required String uid}) async {
    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .add(product.toFirestore());
    return docRef.id;
  }

  Future<void> updateProduct(Product product, {required String uid}) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String productId, {required String uid}) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .doc(productId)
        .update({'isActive': false});
  }

  // ==================== IMAGE UPLOAD ====================

  Future<String> uploadProductImage({
    required String uid,
    required String productId,
    required String filePath,
  }) async {
    final file = File(filePath);
    final ref = _storage
        .ref()
        .child('users/$uid/products/$productId/image.jpg');
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> updateProductImageUrl({
    required String uid,
    required String productId,
    required String imageUrl,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('products')
        .doc(productId)
        .update({'imageUrl': imageUrl});
  }

  // ==================== SALES ====================

  Future<int> _getNextReceiptNumber(String uid) async {
    final counterRef = _db
        .collection('users')
        .doc(uid)
        .collection('counters')
        .doc('receipts');
    await counterRef.set(
      {'count': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    final snapshot = await counterRef.get();
    return (snapshot.data()?['count'] as int?) ?? 1;
  }

  Future<Sale> saveSale(Sale sale, {required String uid}) async {
    final receiptNumber = sale.isReturn ? 0 : await _getNextReceiptNumber(uid);
    final saleWithNumber = Sale(
      id: sale.id,
      items: sale.items,
      total: sale.total,
      paymentMethod: sale.paymentMethod,
      amountPaid: sale.amountPaid,
      change: sale.change,
      createdAt: sale.createdAt,
      cashierName: sale.cashierName,
      receiptNumber: receiptNumber,
      userId: uid,
      storeName: sale.storeName,
      isReturn: sale.isReturn,
      originalSaleId: sale.originalSaleId,
      cashAmount: sale.cashAmount,
      cardAmount: sale.cardAmount,
    );

    final docRef = await _db
        .collection('users')
        .doc(uid)
        .collection('sales')
        .add(saleWithNumber.toFirestore());

    return Sale(
      id: docRef.id,
      items: saleWithNumber.items,
      total: saleWithNumber.total,
      paymentMethod: saleWithNumber.paymentMethod,
      amountPaid: saleWithNumber.amountPaid,
      change: saleWithNumber.change,
      createdAt: saleWithNumber.createdAt,
      cashierName: saleWithNumber.cashierName,
      receiptNumber: saleWithNumber.receiptNumber,
      userId: uid,
      storeName: saleWithNumber.storeName,
      isReturn: saleWithNumber.isReturn,
      originalSaleId: saleWithNumber.originalSaleId,
      cashAmount: saleWithNumber.cashAmount,
      cardAmount: saleWithNumber.cardAmount,
    );
  }

  Future<List<Sale>> getSalesByDateRangeOnce(
    String uid,
    DateTime from,
    DateTime to,
  ) async {
    final fromTimestamp =
        Timestamp.fromDate(DateTime(from.year, from.month, from.day, 0, 0, 0));
    final toTimestamp =
        Timestamp.fromDate(DateTime(to.year, to.month, to.day, 23, 59, 59));

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: fromTimestamp)
        .where('createdAt', isLessThanOrEqualTo: toTimestamp)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList();
  }

  Future<Sale?> getSaleByReceiptNumber(String uid, int receiptNumber) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sales')
        .where('receiptNumber', isEqualTo: receiptNumber)
        .get();

    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      return data['isReturn'] != true;
    }).toList();

    if (docs.isEmpty) return null;
    return Sale.fromFirestore(docs.first);
  }

  // Помечает чек как возвращённый — повторный возврат по нему запрещён
  Future<void> markSaleReturned(String uid, String saleId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('sales')
        .doc(saleId)
        .update({'isReturned': true});
  }

  // Проверка для старых чеков, возвращённых до появления флага isReturned:
  // ищем возврат, ссылающийся на этот чек
  Future<bool> hasReturnForSale(String uid, String saleId) async {
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('sales')
        .where('originalSaleId', isEqualTo: saleId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
