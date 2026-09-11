import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/routing/route_results.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/cart_controller.dart';
import '../../data/cart_item.dart';
import '../../data/employee.dart';
import '../../data/order.dart';
import '../../data/order_repository.dart';
import '../../data/product_repository.dart';
import '../widgets/cart_panel.dart';
import '../widgets/cashier_bottom_nav.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/order_verification_dialog.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_search_field.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({
    super.key,
    this.productRepository = const ProductRepository(),
    this.orderRepository = const OrderRepository(),
    this.initialCategory,
  });

  final ProductRepository productRepository;
  final OrderRepository orderRepository;
  final String? initialCategory;

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late final List<Product> _products = widget.productRepository.fetchAll();
  final CartController _cart = CartController();

  String _query = '';
  late String? _selectedCategory = widget.initialCategory;
  PaymentMethod? _paymentMethod;

  List<String> get _categories =>
      _products.map((Product p) => p.category).toSet().toList();

  List<Product> get _filteredProducts {
    return _products.where((Product product) {
      final bool matchesCategory =
          _selectedCategory == null || product.category == _selectedCategory;
      final bool matchesQuery =
          _query.isEmpty ||
          product.name.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _checkout() async {
    final PaymentMethod? method = _paymentMethod;
    if (method == null) {
      return;
    }

    final Employee? cashier = await OrderVerificationDialog.show(
      context,
      cart: _cart,
      method: method,
    );

    if (cashier == null || !mounted) {
      return;
    }

    widget.orderRepository.add(
      Order(
        id: widget.orderRepository.nextId(),
        items: _cart.items,
        total: _cart.total,
        method: method,
        createdAt: DateTime.now(),
        cashierName: cashier.name,
      ),
    );

    setState(() {
      _cart.clear();
      _paymentMethod = null;
    });

    showAppDialog(
      context,
      title: AppStrings.paymentSuccess,
      message: method.label,
    );
  }

  void _onNavSelected(int index) {
    if (index == 1) {
      return;
    }
    if (index == 0) {
      Navigator.of(context).pop();
      return;
    }
    if (index == 2) {
      Navigator.of(context).pop(RouteResults.openOrders);
      return;
    }
    if (index == 3) {
      Navigator.of(context).pop(RouteResults.openFinance);
      return;
    }

    showComingSoonDialog(context, CashierBottomNav.items[index].label);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) =>
          _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
        title: BrandTitle(text: AppStrings.navTransactions),
        actions: <Widget>[
          const ThemeToggleButton(),
        ],
      ),
      bottomNavigationBar: CashierBottomNav(
        currentIndex: 1,
        onSelected: _onNavSelected,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isWide = constraints.maxWidth >= 700;

          final Widget catalog = _ProductCatalog(
            categories: _categories,
            selectedCategory: _selectedCategory,
            onCategorySelected: (String? category) =>
                setState(() => _selectedCategory = category),
            onQueryChanged: (String value) => setState(() => _query = value),
            products: _filteredProducts,
            onProductTap: (Product product) =>
                setState(() => _cart.add(product)),
          );

          final Widget cart = ListenableBuilder(
            listenable: _cart,
            builder: (BuildContext context, _) => CartPanel(
              items: _cart.items,
              total: _cart.total,
              onIncrement: (CartItem item) =>
                  setState(() => _cart.increment(item.product)),
              onDecrement: (CartItem item) =>
                  setState(() => _cart.decrement(item.product)),
              onRemove: (CartItem item) =>
                  setState(() => _cart.remove(item.product)),
              selectedMethod: _paymentMethod,
              onMethodSelected: (PaymentMethod method) =>
                  setState(() => _paymentMethod = method),
              onCheckout: _checkout,
            ),
          );

          if (isWide) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(flex: 5, child: catalog),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: cart),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Expanded(flex: 4, child: catalog),
                const SizedBox(height: 16),
                Expanded(flex: 2, child: cart),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProductCatalog extends StatelessWidget {
  const _ProductCatalog({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onQueryChanged,
    required this.products,
    required this.onProductTap,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final ValueChanged<String> onQueryChanged;
  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panelSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ProductSearchField(onChanged: onQueryChanged),
          const SizedBox(height: 12),
          CategoryFilterBar(
            categories: categories,
            selected: selectedCategory,
            onSelected: onCategorySelected,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      AppStrings.comingSoon,
                      style: TextStyle(color: AppColors.onSurface),
                    ),
                  )
                : ProductGrid(products: products, onProductTap: onProductTap),
          ),
        ],
      ),
    );
  }
}
