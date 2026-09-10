import '../../../core/models/payment_method.dart';
import 'cart_item.dart';

class Order {
  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.method,
    required this.createdAt,
    required this.cashierName,
  });

  final String id;
  final List<CartItem> items;
  final int total;
  final PaymentMethod method;
  final DateTime createdAt;
  final String cashierName;

  int get itemCount =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);
}
