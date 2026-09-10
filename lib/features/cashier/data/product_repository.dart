class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.tag,
    this.imageAsset,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final String? tag;
  final String? imageAsset;

  Product copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? tag,
    String? imageAsset,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}

class ProductRepository {
  const ProductRepository();

  static final List<Product> _products = <Product>[
    const Product(
      id: 'p1',
      name: 'Manicure Klasik',
      price: 45000,
      category: 'Manicure',
    ),
    const Product(
      id: 'p2',
      name: 'Manicure Spa',
      price: 75000,
      category: 'Manicure',
      tag: 'Populer',
    ),
    const Product(
      id: 'p3',
      name: 'Pedicure Klasik',
      price: 50000,
      category: 'Pedicure',
    ),
    const Product(
      id: 'p4',
      name: 'Pedicure Spa',
      price: 85000,
      category: 'Pedicure',
    ),
    const Product(
      id: 'p5',
      name: 'Nail Art Custom',
      price: 120000,
      category: 'Nail Art',
      tag: 'Custome',
    ),
    const Product(
      id: 'p6',
      name: 'Nail Art Sederhana',
      price: 60000,
      category: 'Nail Art',
    ),
    const Product(
      id: 'p7',
      name: 'Extension Akrilik',
      price: 150000,
      category: 'Extension',
    ),
    const Product(
      id: 'p8',
      name: 'Extension Gel',
      price: 175000,
      category: 'Extension',
    ),
    const Product(
      id: 'p9',
      name: 'Gel Polish',
      price: 65000,
      category: 'Gel Polish',
    ),
    const Product(
      id: 'p10',
      name: 'Refill Kuku',
      price: 55000,
      category: 'Refill',
    ),
    const Product(
      id: 'p11',
      name: 'Perawatan Kutikula',
      price: 40000,
      category: 'Perawatan',
    ),
    const Product(
      id: 'p12',
      name: 'Paket Hemat Duo',
      price: 130000,
      category: 'Paket Hemat',
    ),
  ];

  List<Product> fetchAll() => List<Product>.from(_products);

  void add(Product product) {
    _products.add(product);
  }

  void update(Product updatedProduct) {
    final int index = _products.indexWhere(
      (Product p) => p.id == updatedProduct.id,
    );
    if (index != -1) {
      _products[index] = updatedProduct;
    }
  }

  void delete(String id) {
    _products.removeWhere((Product p) => p.id == id);
  }
}
