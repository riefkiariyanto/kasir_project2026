import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/routing/route_results.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../data/category_repository.dart';
import '../../data/employee.dart';
import '../../data/employee_repository.dart';
import '../../data/finance_repository.dart';
import '../../data/order.dart';
import '../../data/order_repository.dart';
import '../widgets/cashier_bottom_nav.dart';
import '../widgets/cashier_drawer.dart';
import '../widgets/category_grid.dart';
import '../widgets/orders_list.dart';
import '../widgets/promo_banner.dart';
import 'cashier_settings_page.dart';
import 'finance_tab.dart';
import 'transaction_page.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({
    super.key,
    this.categoryRepository = const CategoryRepository(),
    this.orderRepository = const OrderRepository(),
    this.employeeRepository = const EmployeeRepository(),
    this.financeRepository = const FinanceRepository(),
  });

  final CategoryRepository categoryRepository;
  final OrderRepository orderRepository;
  final EmployeeRepository employeeRepository;
  final FinanceRepository financeRepository;

  @override
  State<CashierPage> createState() => _CashierPageState();
}

enum _OrdersFilterPeriod { all, day, week, month }

class _CashierPageState extends State<CashierPage> {
  int _navIndex = 0;
  final List<int> _navHistory = <int>[];
  String? _ordersFilterEmployee;
  DateTime? _ordersFilterDate;
  String _ordersSearchQuery = '';
  PaymentMethod? _ordersFilterMethod;
  _OrdersFilterPeriod _ordersFilterPeriod = _OrdersFilterPeriod.all;
  bool _ordersGridView = false;
  bool _ordersSortNewestFirst = true;

  List<ProductCategory>? _categories;
  List<Order>? _orders;
  List<Employee>? _employees;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final List<ProductCategory> categories = await widget.categoryRepository
        .fetchAll();
    if (mounted) {
      setState(() => _categories = categories);
    }
  }

  Future<void> _loadOrders() async {
    final List<Order> orders = await widget.orderRepository.fetchAll();
    if (mounted) {
      setState(() => _orders = orders);
    }
  }

  Future<void> _loadEmployees() async {
    final List<Employee> employees = await widget.employeeRepository
        .fetchNames();
    if (mounted) {
      setState(() => _employees = employees);
    }
  }

  void _pushHistory(int from) {
    _navHistory.add(from);
    if (_navHistory.length > 20) _navHistory.removeAt(0);
  }

  void _goBack() {
    setState(() {
      _resetOrdersFilters();
      if (_navHistory.isNotEmpty) {
        _navIndex = _navHistory.removeLast();
      } else {
        _navIndex = 0;
      }
    });
  }

  List<Order> get _filteredOrders {
    final String query = _ordersSearchQuery.trim().toLowerCase();
    final DateTime now = DateTime.now();
    return (_orders ?? const <Order>[]).where((Order order) {
      final bool matchesEmployee =
          _ordersFilterEmployee == null ||
          order.cashierName == _ordersFilterEmployee;
      final bool matchesMethod =
          _ordersFilterMethod == null || order.method == _ordersFilterMethod;
      final bool matchesSearch =
          query.isEmpty || order.id.toLowerCase().contains(query);
      final bool matchesDate =
          _ordersFilterDate == null ||
          AppDateUtils.isSameDate(order.createdAt, _ordersFilterDate!);

      bool matchesPeriod = true;
      switch (_ordersFilterPeriod) {
        case _OrdersFilterPeriod.all:
          matchesPeriod = true;
          break;
        case _OrdersFilterPeriod.day:
          matchesPeriod = AppDateUtils.isSameDate(order.createdAt, now);
          break;
        case _OrdersFilterPeriod.week:
          matchesPeriod = AppDateUtils.isSameWeek(order.createdAt, now);
          break;
        case _OrdersFilterPeriod.month:
          matchesPeriod = AppDateUtils.isSameMonth(order.createdAt, now);
          break;
      }
      return matchesEmployee &&
          matchesMethod &&
          matchesSearch &&
          matchesDate &&
          matchesPeriod;
    }).toList()..sort(
      (Order a, Order b) => _ordersSortNewestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt),
    );
  }

  Future<void> _pickOrdersFilterDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ordersFilterDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _ordersFilterDate = picked);
    }
  }

  Future<void> _openTransaction({String? category}) async {
    final Object? result = await Navigator.of(context).push(
      MaterialPageRoute<Object>(
        builder: (_) => TransactionPage(initialCategory: category),
      ),
    );

    if (result == RouteResults.openOrders && mounted) {
      setState(() {
        _resetOrdersFilters();
        _navIndex = 2;
      });
      _loadOrders();
      _loadEmployees();
    } else if (result == RouteResults.openFinance && mounted) {
      setState(() {
        _navIndex = 3;
      });
    }
  }

  void _openOrders() {
    setState(() {
      _pushHistory(_navIndex);
      _resetOrdersFilters();
      _navIndex = 2;
    });
    _loadOrders();
    _loadEmployees();
  }

  void _onNavSelected(int index) {
    if (index == 1) {
      _openTransaction();
      return;
    }
    if (index == _navIndex) {
      return;
    }
    setState(() {
      _pushHistory(_navIndex);
      if (_navIndex == 2 && index != 2) {
        _resetOrdersFilters();
      }
      _navIndex = index;
    });
    if (index == 2) {
      _loadOrders();
      _loadEmployees();
    }
  }

  void _openFinance() {
    setState(() {
      _pushHistory(_navIndex);
      _navIndex = 3;
    });
  }

  void _resetOrdersFilters() {
    _ordersFilterEmployee = null;
    _ordersFilterDate = null;
    _ordersFilterMethod = null;
    _ordersSearchQuery = '';
    _ordersFilterPeriod = _OrdersFilterPeriod.all;
    _ordersSortNewestFirst = true;
  }

  Widget _buildBody(BuildContext context) {
    switch (_navIndex) {
      case 0:
        if (_categories == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _CashierHomeTab(
          categories: _categories!,
          onCategoryTap: (ProductCategory category) =>
              _openTransaction(category: category.name),
          onBannerTap: () => _openTransaction(),
          onTransaksiTap: () => _openTransaction(),
          onOrdersTap: _openOrders,
          onFinanceTap: _openFinance,
        );
      case 2:
        return _buildOrdersTab(context);
      case 3:
        return const FinanceTab();
      default:
        return _ComingSoonTab(item: CashierBottomNav.items[_navIndex]);
    }
  }

  Widget _buildOrdersTab(BuildContext context) {
    if (_orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  _buildOrdersSearchAndToggle(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _ordersGridView
                        ? OrdersList.grid(orders: _filteredOrders)
                        : OrdersList(orders: _filteredOrders),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersSearchAndToggle() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _buildOrdersSearchField()),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => setState(
                () => _ordersSortNewestFirst = !_ordersSortNewestFirst,
              ),
              tooltip: _ordersSortNewestFirst
                  ? 'Terbaru ke Terlama'
                  : 'Terlama ke Terbaru',
              icon: Icon(
                _ordersSortNewestFirst
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: AppColors.onSurface,
              ),
            ),
            IconButton(
              onPressed: () =>
                  setState(() => _ordersGridView = !_ordersGridView),
              tooltip: _ordersGridView ? 'Tampilan List' : 'Tampilan Grid',
              icon: Icon(
                _ordersGridView
                    ? Icons.view_list_outlined
                    : Icons.grid_view_outlined,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildOrdersFilterBar(context),
      ],
    );
  }

  Widget _buildOrdersFilterBar(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _buildPeriodChip('Hari Ini', _OrdersFilterPeriod.day),
          const SizedBox(width: 6),
          _buildPeriodChip('Minggu Ini', _OrdersFilterPeriod.week),
          const SizedBox(width: 6),
          _buildPeriodChip('Bulan Ini', _OrdersFilterPeriod.month),
          const SizedBox(width: 6),
          _buildPeriodChip('Semua', _OrdersFilterPeriod.all),
          const SizedBox(width: 6),
          IntrinsicWidth(child: _buildEmployeeDropdown(context)),
          const SizedBox(width: 6),
          IntrinsicWidth(child: _buildMethodDropdown(context)),
          const SizedBox(width: 6),
          _buildOrdersDateFilterChip(context),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, _OrdersFilterPeriod period) {
    final bool isSelected = _ordersFilterPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _ordersFilterPeriod = period),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : AppColors.onSurfaceMuted.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildOrdersDateFilterChip(BuildContext context) {
    final DateTime? date = _ordersFilterDate;
    final String label = date == null
        ? 'Tanggal'
        : AppDateUtils.formatDate(date);

    return Container(
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _pickOrdersFilterDate(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodDropdown(BuildContext context) {
    return Container(
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<PaymentMethod?>(
        isExpanded: false,
        initialValue: _ordersFilterMethod,
        onChanged: (PaymentMethod? value) =>
            setState(() => _ordersFilterMethod = value),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: 14, color: AppColors.onSurface),
        items: const <DropdownMenuItem<PaymentMethod?>>[
          DropdownMenuItem<PaymentMethod?>(
            value: null,
            child: Text('Pembayaran'),
          ),
          DropdownMenuItem<PaymentMethod?>(
            value: PaymentMethod.cash,
            child: Text('Tunai'),
          ),
          DropdownMenuItem<PaymentMethod?>(
            value: PaymentMethod.qris,
            child: Text('QRIS'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDropdown(BuildContext context) {
    final List<String> employeeNames = (_employees ?? const <Employee>[])
        .map((Employee employee) => employee.name)
        .toList();

    return Container(
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonFormField<String?>(
        isExpanded: false,
        initialValue: _ordersFilterEmployee,
        hint: const Text('Pegawai'),
        onChanged: (String? value) =>
            setState(() => _ordersFilterEmployee = value),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: 15, color: AppColors.onSurface),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(value: null, child: Text('Pegawai')),
          for (final String name in employeeNames)
            DropdownMenuItem<String?>(value: name, child: Text(name)),
        ],
      ),
    );
  }

  Widget _buildOrdersSearchField() {
    return Container(
      decoration: ClayDecoration(
        color: AppColors.panelSurface,
        sunken: true,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: (String value) => setState(() => _ordersSearchQuery = value),
        style: TextStyle(fontSize: 15, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: 'Cari ID pesanan, nama kasir...',
          prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceMuted),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _ordersSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _ordersSearchQuery = ''),
                )
              : null,
        ),
      ),
    );
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
      backgroundColor: AppColors.background,
      extendBody: true,
      drawer: CashierDrawer(
        onNewSale: () => _openTransaction(),
        onOpenOrders: _openOrders,
        onOpenSettings: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CashierSettingsPage()),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
        leading: Builder(
          builder: (BuildContext context) => Padding(
            padding: const EdgeInsets.only(left: 10),
            child: _navIndex != 0
                ? IconButton(
                    onPressed: _goBack,
                    tooltip: AppStrings.back,
                    icon: const Icon(Icons.arrow_back),
                  )
                : IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    tooltip: AppStrings.cashierMenu,
                    icon: const Icon(Icons.menu),
                  ),
          ),
        ),
        title: BrandTitle(
          text: _navIndex == 2
              ? AppStrings.adminTransactions
              : _navIndex == 3
              ? AppStrings.financeHeader
              : AppStrings.brandName,
        ),
        actions: <Widget>[const ThemeToggleButton()],
      ),
      body: _buildBody(context),
      bottomNavigationBar: CashierBottomNav(
        currentIndex: _navIndex,
        onSelected: _onNavSelected,
      ),
    );
  }
}

class _CashierHomeTab extends StatelessWidget {
  const _CashierHomeTab({
    required this.categories,
    required this.onCategoryTap,
    required this.onBannerTap,
    required this.onTransaksiTap,
    required this.onOrdersTap,
    required this.onFinanceTap,
  });

  static const double _maxContentWidth = 1080;

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onCategoryTap;
  final VoidCallback onBannerTap;
  final VoidCallback onTransaksiTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onFinanceTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
          children: <Widget>[
            PromoBanner(onTap: onBannerTap),
            const SizedBox(height: 20),
            Text(
              AppStrings.cashierMenu,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _CashierQuickMenuGrid(
              onTransaksiTap: onTransaksiTap,
              onOrdersTap: onOrdersTap,
              onFinanceTap: onFinanceTap,
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.cashierCategories,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            CategoryGrid(categories: categories, onCategoryTap: onCategoryTap),
          ],
        ),
      ),
    );
  }
}

class _CashierQuickMenuGrid extends StatelessWidget {
  const _CashierQuickMenuGrid({
    required this.onTransaksiTap,
    required this.onOrdersTap,
    required this.onFinanceTap,
  });

  final VoidCallback onTransaksiTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onFinanceTap;

  @override
  Widget build(BuildContext context) {
    final List<_CashierMenuItem> items = <_CashierMenuItem>[
      _CashierMenuItem(
        icon: Icons.add_shopping_cart_outlined,
        label: AppStrings.cashierNewSale,
        onTap: onTransaksiTap,
      ),
      _CashierMenuItem(
        icon: Icons.receipt_outlined,
        label: AppStrings.adminTransactions,
        onTap: onOrdersTap,
      ),
      _CashierMenuItem(
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.navFinance,
        onTap: onFinanceTap,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 168,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _CashierMenuItem item = items[index];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: ClayDecoration(borderRadius: BorderRadius.circular(24)),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.icon, size: 36, color: AppColors.primary),
                    const SizedBox(height: 10),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.6,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CashierMenuItem {
  const _CashierMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.item});

  final CashierNavItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(item.icon, size: 56, color: AppColors.placeholder),
          const SizedBox(height: 12),
          Text(
            '${item.label}: ${AppStrings.comingSoon}',
            style: TextStyle(fontSize: 14, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
