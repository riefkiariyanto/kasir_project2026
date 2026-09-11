import '../../../core/models/payment_method.dart';
import 'cart_item.dart';
import 'order.dart';
import 'product_repository.dart';

class OrderRepository {
  const OrderRepository();

  static final DateTime _now = DateTime.now();

  static final List<Order> _orders = <Order>[
    Order(
      id: 'INV-001',
      items: const <CartItem>[
        CartItem(
          product: Product(
            id: 'p1',
            name: 'Manicure Klasik',
            price: 45000,
            category: 'Manicure',
          ),
          quantity: 2,
        ),
        CartItem(
          product: Product(
            id: 'p9',
            name: 'Gel Polish',
            price: 65000,
            category: 'Gel Polish',
          ),
          quantity: 1,
        ),
      ],
      total: 155000,
      method: PaymentMethod.qris,
      createdAt: _now.subtract(const Duration(days: 3, hours: 3, minutes: 45)),
      cashierName: 'Siti Aminah',
    ),
    Order(
      id: 'INV-002',
      items: const <CartItem>[
        CartItem(
          product: Product(
            id: 'p4',
            name: 'Pedicure Spa',
            price: 85000,
            category: 'Pedicure',
          ),
          quantity: 1,
        ),
      ],
      total: 85000,
      method: PaymentMethod.cash,
      createdAt: _now.subtract(const Duration(days: 2, hours: 1, minutes: 30)),
      cashierName: 'Budi Santoso',
    ),
    Order(
      id: 'INV-003',
      items: const <CartItem>[
        CartItem(
          product: Product(
            id: 'p2',
            name: 'Manicure Spa',
            price: 75000,
            category: 'Manicure',
            tag: 'Populer',
          ),
          quantity: 1,
        ),
        CartItem(
          product: Product(
            id: 'p3',
            name: 'Pedicure Klasik',
            price: 50000,
            category: 'Pedicure',
          ),
          quantity: 1,
        ),
      ],
      total: 125000,
      method: PaymentMethod.qris,
      createdAt: _now.subtract(const Duration(days: 1, hours: 6)),
      cashierName: 'Siti Aminah',
    ),
    Order(
      id: 'INV-004',
      items: const <CartItem>[
        CartItem(
          product: Product(
            id: 'p8',
            name: 'Extension Gel',
            price: 175000,
            category: 'Extension',
          ),
          quantity: 1,
        ),
      ],
      total: 175000,
      method: PaymentMethod.qris,
      createdAt: _now.subtract(const Duration(hours: 4)),
      cashierName: 'Budi Santoso',
    ),
    Order(
      id: 'INV-005',
      items: const <CartItem>[
        CartItem(
          product: Product(
            id: 'p12',
            name: 'Paket Hemat Duo',
            price: 130000,
            category: 'Paket Hemat',
          ),
          quantity: 1,
        ),
      ],
      total: 130000,
      method: PaymentMethod.cash,
      createdAt: _now.subtract(const Duration(hours: 1)),
      cashierName: 'Siti Aminah',
    ),
  ];

  List<Order> fetchAll() {
    return List<Order>.from(_orders.reversed);
  }

  String nextId() {
    return 'INV-${(_orders.length + 1).toString().padLeft(3, '0')}';
  }

  void add(Order order) {
    _orders.add(order);
  }

  void remove(String id) {
    _orders.removeWhere((Order order) => order.id == id);
  }
}
