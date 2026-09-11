import '../../../core/data/api_client.dart';
import 'category_repository.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.categoryId,
    this.tag,
    this.imageAsset,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final String? categoryId;
  final String? tag;
  final String? imageAsset;

  factory Product.fromJson(
    Map<String, dynamic> json,
    List<ProductCategory> categories,
  ) {
    final String? categoryId = json['category_id'] as String?;
    final ProductCategory? matched = categories
        .cast<ProductCategory?>()
        .firstWhere((ProductCategory? c) => c?.id == categoryId, orElse: () => null);
    final String? imagePath = json['image_path'] as String?;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      category: matched?.name ?? '',
      categoryId: categoryId,
      tag: json['tag'] as String?,
      imageAsset: imagePath == null ? null : '${ApiClient.baseUrl}/uploads/$imagePath',
    );
  }

  Product copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? categoryId,
    String? tag,
    String? imageAsset,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      tag: tag ?? this.tag,
      imageAsset: imageAsset ?? this.imageAsset,
    );
  }
}

class ProductRepository {
  const ProductRepository({this.api = const ApiClient()});

  final ApiClient api;

  Future<List<Product>> fetchAll(List<ProductCategory> categories) async {
    final List<dynamic> data = await api.get('/api/products') as List<dynamic>;
    return data
        .map((dynamic e) => Product.fromJson(e as Map<String, dynamic>, categories))
        .toList();
  }

  Future<void> add({
    required String name,
    required int price,
    required String categoryId,
    String? tag,
    String? imagePath,
  }) async {
    await api.postMultipart(
      '/api/products',
      <String, String>{
        'name': name,
        'price': price.toString(),
        'categoryId': categoryId,
        if (tag != null) 'tag': tag,
      },
      fileField: imagePath == null ? null : 'image',
      filePath: imagePath,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required int price,
    required String categoryId,
    String? tag,
    String? imagePath,
  }) async {
    await api.postMultipart(
      '/api/products/$id',
      <String, String>{
        'name': name,
        'price': price.toString(),
        'categoryId': categoryId,
        if (tag != null) 'tag': tag,
      },
      fileField: imagePath == null ? null : 'image',
      filePath: imagePath,
      method: 'PUT',
    );
  }

  Future<void> delete(String id) async {
    await api.delete('/api/products/$id');
  }
}
