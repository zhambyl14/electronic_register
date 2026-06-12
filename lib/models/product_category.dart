class ProductCategory {
  final String id;
  final String name;
  final List<String> subcategories;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });
}

const List<ProductCategory> defaultCategories = [
  ProductCategory(id: 'all', name: 'Все', subcategories: []),
  ProductCategory(
    id: 'meat',
    name: 'Мясо',
    subcategories: ['Говядина', 'Баранина', 'Свинина', 'Птица', 'Рыба'],
  ),
  ProductCategory(
    id: 'fruits',
    name: 'Фрукты',
    subcategories: ['Яблоки', 'Груши', 'Цитрусовые', 'Ягоды', 'Прочие'],
  ),
  ProductCategory(
    id: 'vegetables',
    name: 'Овощи',
    subcategories: ['Корнеплоды', 'Листовые', 'Томаты', 'Прочие'],
  ),
  ProductCategory(
    id: 'dairy',
    name: 'Молочное',
    subcategories: ['Молоко', 'Сыр', 'Масло', 'Кисломолочное'],
  ),
  ProductCategory(
    id: 'dry',
    name: 'Сухое',
    subcategories: ['Крупы', 'Орехи', 'Специи', 'Мука', 'Сахар'],
  ),
  ProductCategory(
    id: 'bread',
    name: 'Хлеб',
    subcategories: ['Хлеб', 'Выпечка', 'Торты'],
  ),
  ProductCategory(
    id: 'other',
    name: 'Прочее',
    subcategories: ['Консервы', 'Напитки', 'Снеки', 'Другое'],
  ),
];
