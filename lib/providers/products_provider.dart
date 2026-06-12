import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';

class ProductsProvider with ChangeNotifier {
  final FirebaseService _service = FirebaseService();
  final CloudinaryService _cloudinary = CloudinaryService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  String? _uid;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get uid => _uid;

  Future<void> loadProducts(String uid) async {
    _uid = uid;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getProductsOnce(uid);
      _isLoading = false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  void clear() {
    _uid = null;
    _products = [];
    _error = null;
    notifyListeners();
  }

  Future<void> addProduct({
    required String name,
    required ProductUnit unit,
    required double price,
    String? categoryId,
    String? subcategory,
    XFile? imageFile,
    int? plu,
  }) async {
    if (_uid == null) return;
    final uid = _uid!;

    // Загружаем фото в Cloudinary (если выбрано)
    String? imageUrl;
    if (imageFile != null) {
      try {
        imageUrl = await _cloudinary.uploadImage(imageFile.path);
      } catch (_) {}
    }

    final product = Product(
      id: '',
      name: name.trim(),
      unit: unit,
      price: price,
      categoryId: categoryId,
      subcategory: subcategory,
      imageUrl: imageUrl,
      plu: plu,
    );
    await _service.addProduct(product, uid: uid);
    await loadProducts(uid);
  }

  Future<void> updateProduct(Product product) async {
    if (_uid == null) return;
    await _service.updateProduct(product, uid: _uid!);
    await loadProducts(_uid!);
  }

  Future<void> updateProductWithImage(Product product, XFile imageFile) async {
    if (_uid == null) return;
    final uid = _uid!;
    try {
      final imageUrl = await _cloudinary.uploadImage(imageFile.path);
      await _service.updateProduct(
        product.copyWith(imageUrl: imageUrl),
        uid: uid,
      );
    } catch (_) {
      await _service.updateProduct(product, uid: uid);
    }
    await loadProducts(uid);
  }

  Future<void> deleteProduct(String productId) async {
    if (_uid == null) return;
    await _service.deleteProduct(productId, uid: _uid!);
    await loadProducts(_uid!);
  }

  /// Фильтрация по категории/подкатегории (для UI-слоя)
  List<Product> getFiltered({
    String? categoryId,
    String? subcategory,
    String searchQuery = '',
  }) {
    return _products.where((p) {
      final matchSearch = searchQuery.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchCat = categoryId == null ||
          categoryId == 'all' ||
          p.categoryId == categoryId;
      final matchSub =
          subcategory == null || p.subcategory == subcategory;
      return matchSearch && matchCat && matchSub;
    }).toList();
  }
}
