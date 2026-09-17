import '../../../core/data/api_client.dart';
import '../../../core/models/payment_method.dart';
import 'cart_item.dart';
import 'order.dart';

class OrderRepository {
  const OrderRepository({this.api = const ApiClient()});

  final ApiClient api;

  Future<List<Order>> fetchAll() async {
    final List<dynamic> data = await api.get('/api/orders') as List<dynamic>;
    return data
        .map((dynamic e) => Order.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<Order> checkout({
    required List<CartItem> items,
    required PaymentMethod method,
    required String cashierPin,
  }) async {
    final dynamic data = await api.post(
      '/api/orders/checkout',
      <String, dynamic>{
        'items': items
            .map(
              (CartItem item) => <String, dynamic>{
                'productId': item.product.id,
                'productName': item.product.name,
                'price': item.product.price,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'method': method == PaymentMethod.cash ? 'cash' : 'qris',
        'cashierPin': cashierPin,
      },
    );
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await api.delete('/api/orders/$id');
  }

  /// Deletes every order created on or after [from] and before [to];
  /// returns how many were deleted.
  Future<int> removeRange({
    required DateTime from,
    required DateTime to,
    required String password,
  }) async {
    final dynamic data = await api
        .post('/api/orders/bulk-delete', <String, dynamic>{
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
          'password': password,
        });
    return (data as Map<String, dynamic>)['deleted'] as int;
  }
}
