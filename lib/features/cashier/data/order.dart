import '../../../core/models/payment_method.dart';
import 'cart_item.dart';
import 'product_repository.dart';

class Order {
  const Order({
    required this.id,
    required this.invoiceNo,
    required this.items,
    required this.total,
    required this.method,
    required this.createdAt,
    required this.cashierName,
  });

  /// Database id, used for API calls.
  final String id;

  /// Human-facing number (INV-001) shown on screen and receipts.
  final String invoiceNo;
  final List<CartItem> items;
  final int total;
  final PaymentMethod method;
  final DateTime createdAt;
  final String cashierName;

  int get itemCount =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems =
        json['items'] as List<dynamic>? ?? <dynamic>[];
    return Order(
      id: json['id'] as String,
      invoiceNo: json['invoice_no'] as String,
      items: rawItems.map((dynamic e) {
        final Map<String, dynamic> item = e as Map<String, dynamic>;
        return CartItem(
          product: Product(
            id:
                item['product_id'] as String? ??
                item['productId'] as String? ??
                '',
            name:
                item['product_name'] as String? ??
                item['productName'] as String,
            price: item['price'] as int,
            category: '',
          ),
          quantity: item['quantity'] as int,
        );
      }).toList(),
      total: json['total'] as int,
      method: (json['method'] as String) == 'cash'
          ? PaymentMethod.cash
          : PaymentMethod.qris,
      createdAt: DateTime.parse(json['created_at'] as String),
      cashierName: json['cashier_name'] as String,
    );
  }
}
