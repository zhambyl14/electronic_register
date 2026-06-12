import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../providers/products_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _pluController = TextEditingController();
  ProductUnit _selectedUnit = ProductUnit.kg;
  String? _selectedCategoryId;
  bool _isAdding = false;
  XFile? _pickedImage;

  Product? _editingProduct;
  final _editNameController = TextEditingController();
  final _editPriceController = TextEditingController();
  final _editPluController = TextEditingController();
  ProductUnit _editUnit = ProductUnit.kg;
  String? _editCategoryId;
  XFile? _editPickedImage;
  int _categoryKey = 0;
  int _editCategoryKey = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _pluController.dispose();
    _editNameController.dispose();
    _editPriceController.dispose();
    _editPluController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool forEdit = false}) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() {
        if (forEdit) {
          _editPickedImage = file;
        } else {
          _pickedImage = file;
        }
      });
    }
  }

  // Тек қолданыстағы өнімдерден категориялар алу
  List<String> _getAutocompleteCategoryOptions(ProductsProvider provider) {
    return provider.products
        .where((p) => p.categoryId != null && p.categoryId!.isNotEmpty)
        .map((p) => _getCategoryDisplayName(p.categoryId))
        .toSet()
        .toList();
  }

  String? _mapCategoryInput(String input) {
    final trimmed = input.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _getCategoryDisplayName(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) return '';
    // Ескі алдын ала анықталған категориялармен үйлесімділік
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAddForm(),
                const SizedBox(height: 16),
                Expanded(child: _buildProductList()),
              ],
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
          Text(
            'Товары',
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

  Widget _buildAddForm() {
    final provider = context.read<ProductsProvider>();

    return Container(
      padding: const EdgeInsets.all(18),
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
            'Добавить товар',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A2332),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Image picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фото',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1.5),
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.file(
                                File(_pickedImage!.path),
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.add_photo_alternate_outlined,
                              color: Color(0xFFADB5BD), size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Название товара',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Например: Жая ет',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Category
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Категория',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    Autocomplete<String>(
                      key: ValueKey('cat_$_categoryKey'),
                      optionsBuilder: (TextEditingValue textValue) {
                        final opts = _getAutocompleteCategoryOptions(provider);
                        if (textValue.text.isEmpty) return opts;
                        return opts.where((o) => o
                            .toLowerCase()
                            .contains(textValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedCategoryId = _mapCategoryInput(selection);
                        });
                      },
                      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) {
                        return TextField(
                          controller: ctrl,
                          focusNode: focusNode,
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = _mapCategoryInput(value);
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Жая ет, Фарш...',
                            isDense: true,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Unit
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Единица',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<ProductUnit>(
                      value: _selectedUnit, // ignore: deprecated_member_use
                      isDense: true,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(
                            value: ProductUnit.kg, child: Text('кг')),
                        DropdownMenuItem(
                            value: ProductUnit.pcs, child: Text('шт')),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedUnit = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // PLU — код товара в весах с этикетками (Rongta)
              SizedBox(
                width: 90,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Код (PLU)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _pluController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        hintText: '—',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Price
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Цена (₸)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0',
                        suffixText: '₸',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Save button
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addProduct,
                  icon: _isAdding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add, size: 16),
                  label: const Text('Сохранить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                const Text('Товаров нет. Добавьте выше.',
                    style: TextStyle(color: Color(0xFF9CA3AF))),
              ],
            ),
          );
        }

        return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 40,
                        child: Text('#',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500))),
                    SizedBox(
                        width: 50,
                        child: Text('Фото',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    Expanded(
                        child: Text('Название',
                            style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500))),
                    SizedBox(
                        width: 120,
                        child: Text('Категория',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    SizedBox(
                        width: 70,
                        child: Text('Ед.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    SizedBox(
                        width: 100,
                        child: Text('Цена',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    SizedBox(
                        width: 80,
                        child: Text('Статус',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                    SizedBox(
                        width: 90,
                        child: Text('Действия',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    if (_editingProduct?.id == product.id) {
                      return _buildEditRow(product, index, provider);
                    }
                    return _buildProductRow(product, index, provider);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductRow(
      Product product, int index, ProductsProvider provider) {
    final isKg = product.isByWeight;
    final isEven = index.isEven;
    final catName = _getCategoryDisplayName(product.categoryId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : const Color(0xFFFAFBFC),
        border: const Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text('${index + 1}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ),
          SizedBox(
            width: 50,
            child: _ProductThumbnail(product: product),
          ),
          Expanded(
            child: Text(product.name,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A2332))),
          ),
          SizedBox(
            width: 120,
            child: Text(catName.isEmpty ? '—' : catName,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ),
          SizedBox(
            width: 70,
            child: _UnitBadge(isKg: isKg),
          ),
          SizedBox(
            width: 100,
            child: Text('${product.price.toStringAsFixed(0)} ₸',
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A2332))),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Активен',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF065F46))),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: () {
                    setState(() {
                      _editingProduct = product;
                      _editNameController.text = product.name;
                      _editPriceController.text =
                          product.price.toStringAsFixed(0);
                      _editPluController.text =
                          product.plu?.toString() ?? '';
                      _editUnit = product.unit;
                      _editCategoryId = product.categoryId;
                      _editPickedImage = null;
                      _editCategoryKey++;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  onTap: () => _confirmDelete(context, product, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditRow(Product product, int index, ProductsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF0F7FF),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                  width: 40,
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)))),
              SizedBox(
                width: 50,
                child: GestureDetector(
                  onTap: () => _pickImage(forEdit: true),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF2563EB)),
                    ),
                    child: _editPickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Image.file(
                                File(_editPickedImage!.path),
                                fit: BoxFit.cover),
                          )
                        : product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: CachedNetworkImage(
                                    imageUrl: product.imageUrl!,
                                    fit: BoxFit.cover),
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 18,
                                color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _editNameController,
                  decoration: const InputDecoration(isDense: true),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              // Category edit
              SizedBox(
                width: 140,
                child: Autocomplete<String>(
                  key: ValueKey('editcat_$_editCategoryKey'),
                  initialValue: TextEditingValue(
                    text: _getCategoryDisplayName(_editCategoryId),
                  ),
                  optionsBuilder: (TextEditingValue textValue) {
                    final opts = _getAutocompleteCategoryOptions(provider);
                    if (textValue.text.isEmpty) return opts;
                    return opts.where((o) => o
                        .toLowerCase()
                        .contains(textValue.text.toLowerCase()));
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _editCategoryId = _mapCategoryInput(selection);
                    });
                  },
                  fieldViewBuilder: (ctx, ctrl, focusNode, onSubmitted) {
                    return TextField(
                      controller: ctrl,
                      focusNode: focusNode,
                      onChanged: (value) {
                        setState(() {
                          _editCategoryId = _mapCategoryInput(value);
                        });
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'Категория',
                        labelStyle: TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: DropdownButtonFormField<ProductUnit>(
                  value: _editUnit, // ignore: deprecated_member_use
                  isDense: true,
                  decoration: const InputDecoration(isDense: true),
                  items: const [
                    DropdownMenuItem(value: ProductUnit.kg, child: Text('кг')),
                    DropdownMenuItem(value: ProductUnit.pcs, child: Text('шт')),
                  ],
                  onChanged: (val) => setState(() => _editUnit = val!),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _editPriceController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(isDense: true, suffixText: '₸'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _editPluController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'PLU',
                    labelStyle: TextStyle(fontSize: 11),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Row(
                  children: [
                    _ActionBtn(
                      icon: Icons.check,
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          _saveEdit(context.read<ProductsProvider>()),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.close,
                      color: const Color(0xFF9CA3AF),
                      onTap: () => setState(() {
                        _editingProduct = null;
                        _editPickedImage = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Введите название товара!');
      return;
    }
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showSnack('Введите корректную цену!');
      return;
    }

    setState(() => _isAdding = true);
    try {
      await context.read<ProductsProvider>().addProduct(
            name: _nameController.text.trim(),
            unit: _selectedUnit,
            price: price,
            categoryId: _selectedCategoryId,
            imageFile: _pickedImage,
            plu: int.tryParse(_pluController.text.trim()),
          );
      _nameController.clear();
      _priceController.clear();
      _pluController.clear();
      setState(() {
        _selectedUnit = ProductUnit.kg;
        _selectedCategoryId = null;
        _pickedImage = null;
        _categoryKey++;
      });
      _showSnack('Товар успешно добавлен!', color: const Color(0xFF10B981));
    } catch (e) {
      _showSnack('Ошибка: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _saveEdit(ProductsProvider provider) async {
    if (_editingProduct == null) return;
    final price = double.tryParse(_editPriceController.text);
    if (price == null || price <= 0) return;

    final newPlu = int.tryParse(_editPluController.text.trim());
    final updated = _editingProduct!.copyWith(
      name: _editNameController.text.trim(),
      unit: _editUnit,
      price: price,
      categoryId: _editCategoryId,
      clearCategory: _editCategoryId == null,
      subcategory: null,
      clearSubcategory: true,
      plu: newPlu,
      clearPlu: newPlu == null,
    );

    if (_editPickedImage != null) {
      await provider.updateProductWithImage(updated, _editPickedImage!);
    } else {
      await provider.updateProduct(updated);
    }
    setState(() {
      _editingProduct = null;
      _editPickedImage = null;
    });
  }

  void _confirmDelete(
      BuildContext context, Product product, ProductsProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить товар'),
        content: Text('Удалить «${product.name}»?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Нет')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, удалить',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
    ));
  }
}

class _ProductThumbnail extends StatelessWidget {
  final Product product;
  const _ProductThumbnail({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: product.imageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image_outlined, size: 18, color: Color(0xFFADB5BD)),
    );
  }
}

class _UnitBadge extends StatelessWidget {
  final bool isKg;
  const _UnitBadge({required this.isKg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isKg ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isKg ? 'кг' : 'шт',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: isKg ? const Color(0xFF92400E) : const Color(0xFF065F46),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
