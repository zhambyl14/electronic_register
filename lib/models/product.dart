import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductUnit { kg, pcs }

class Product {
  final String id;
  final String name;
  final ProductUnit unit;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final String? imageUrl;
  final String? categoryId;
  final String? subcategory;

  /// Код PLU — тот же номер, что введён в весах с печатью этикеток
  /// (Rongta RLS и т.п.). По нему товар находится при сканировании
  /// весового штрих-кода.
  final int? plu;

  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    this.isActive = true,
    DateTime? createdAt,
    this.imageUrl,
    this.categoryId,
    this.subcategory,
    this.plu,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isByWeight => unit == ProductUnit.kg;

  String get unitLabel => unit == ProductUnit.kg ? 'кг' : 'шт';

  String get priceLabel =>
      '${price.toStringAsFixed(0)} ₸/${unit == ProductUnit.kg ? 'кг' : 'шт'}';

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      unit: data['unit'] == 'kg' ? ProductUnit.kg : ProductUnit.pcs,
      price: (data['price'] as num).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      categoryId: data['categoryId'] as String?,
      subcategory: data['subcategory'] as String?,
      plu: (data['plu'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'unit': unit == ProductUnit.kg ? 'kg' : 'pcs',
      'price': price,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (categoryId != null) 'categoryId': categoryId,
      if (subcategory != null) 'subcategory': subcategory,
      if (plu != null) 'plu': plu,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    ProductUnit? unit,
    double? price,
    bool? isActive,
    String? imageUrl,
    bool clearImage = false,
    String? categoryId,
    bool clearCategory = false,
    String? subcategory,
    bool clearSubcategory = false,
    int? plu,
    bool clearPlu = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      subcategory: clearSubcategory ? null : (subcategory ?? this.subcategory),
      plu: clearPlu ? null : (plu ?? this.plu),
    );
  }
}
