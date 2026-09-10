import 'package:flutter/foundation.dart';

import 'cart_item.dart';
import 'product_repository.dart';

class CartController extends ChangeNotifier {
  final List<CartItem> _items = <CartItem>[];

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);

  int get total =>
      _items.fold(0, (int sum, CartItem item) => sum + item.subtotal);

  void add(Product product) {
    final int index = _items.indexWhere(
      (CartItem i) => i.product.id == product.id,
    );

    if (index == -1) {
      _items.add(CartItem(product: product, quantity: 1));
    } else {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + 1,
      );
    }
    notifyListeners();
  }

  void increment(Product product) => add(product);

  void decrement(Product product) {
    final int index = _items.indexWhere(
      (CartItem i) => i.product.id == product.id,
    );
    if (index == -1) {
      return;
    }

    final CartItem current = _items[index];
    if (current.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  void remove(Product product) {
    _items.removeWhere((CartItem i) => i.product.id == product.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
