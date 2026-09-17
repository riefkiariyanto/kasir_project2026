import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../cashier/data/employee.dart';
import '../../../cashier/data/employee_repository.dart';
import '../../../cashier/data/order.dart';
import '../../../cashier/data/order_repository.dart';
import '../../../cashier/presentation/widgets/orders_list.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_reports_view.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.orderRepository = const OrderRepository(),
    this.employeeRepository = const EmployeeRepository(),
  });

  final OrderRepository orderRepository;
  final EmployeeRepository employeeRepository;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

enum _OrdersFilterPeriod { all, day, week, month }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _navIndex = AdminBottomNav.dashboardIndex;
  final List<int> _navHistory = <int>[];
  String? _ordersFilterEmployee;
  DateTime? _ordersFilterDate;
  String _ordersSearchQuery = '';
  PaymentMethod? _ordersFilterMethod;
  _OrdersFilterPeriod _ordersFilterPeriod = _OrdersFilterPeriod.all;
  bool _ordersGridView = false;
  bool _ordersSortNewestFirst = true;
  List<Order>? _orders;
  List<Employee>? _employees;

  Future<void> _load() async {
    final List<dynamic> results = await Future.wait(<Future<dynamic>>[
      widget.orderRepository.fetchAll(),
      widget.employeeRepository.fetchAll(),
    ]);
    if (mounted) {
      setState(() {
        _orders = results[0] as List<Order>;
        _employees = results[1] as List<Employee>;
      });
    }
  }

  void _pushHistory(int from) {
    _navHistory.add(from);
    if (_navHistory.length > 20) _navHistory.removeAt(0);
  }

  void _goBack() {
    setState(() {
      _resetOrdersFilters();
      _navIndex = _navHistory.isNotEmpty
          ? _navHistory.removeLast()
          : AdminBottomNav.dashboardIndex;
    });
    _refreshIfOnTransactions();
  }

  /// The dashboard loads its own data, so the history list is only fetched
  /// when its tab is actually shown — and refreshed on every visit.
  void _refreshIfOnTransactions() {
    if (_navIndex == AdminBottomNav.transactionsIndex) {
      _load();
    }
  }

  List<Order> get _filteredOrders {
    final String query = _ordersSearchQuery.trim().toLowerCase();
    final List<Order> all = _orders ?? const <Order>[];
    return all.where((Order order) {
      final bool matchesEmployee =
          _ordersFilterEmployee == null ||
          order.cashierName == _ordersFilterEmployee;
      final bool matchesDate =
          _ordersFilterDate == null ||
          AppDateUtils.isSameDate(order.createdAt, _ordersFilterDate!);
      final bool matchesMethod =
          _ordersFilterMethod == null || order.method == _ordersFilterMethod;
      final bool matchesSearch =
          query.isEmpty || order.invoiceNo.toLowerCase().contains(query);

      final DateTime now = DateTime.now();
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
          matchesDate &&
          matchesMethod &&
          matchesSearch &&
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

  void _resetOrdersFilters() {
    _ordersFilterEmployee = null;
    _ordersFilterDate = null;
    _ordersFilterMethod = null;
    _ordersSearchQuery = '';
    _ordersFilterPeriod = _OrdersFilterPeriod.all;
    _ordersSortNewestFirst = true;
  }

  Future<void> _openCatalog() => _openAdminPage(AppRoutes.adminCatalog);

  Future<void> _openEmployees() => _openAdminPage(AppRoutes.adminEmployees);

  Future<void> _openSettings() async {
    await _openAdminPage(AppRoutes.adminSettings);
    // Settings can bulk-delete orders.
    if (mounted) {
      _load();
    }
  }

  /// Pushed admin pages pop with the navbar index the user tapped there.
  Future<void> _openAdminPage(String route) async {
    final Object? result = await Navigator.of(context).pushNamed(route);
    if (result is int && mounted) {
      _onNavSelected(result);
    }
  }

  void _openOrders() => _onNavSelected(AdminBottomNav.transactionsIndex);

  /// Opens the transaction history narrowed to what a dashboard card counted.
  void _openFilteredOrders({
    String? employee,
    DateTime? date,
    PaymentMethod? method,
  }) {
    setState(() {
      _pushHistory(_navIndex);
      _resetOrdersFilters();
      _ordersFilterEmployee = employee;
      _ordersFilterDate = date;
      _ordersFilterMethod = method;
      _navIndex = AdminBottomNav.transactionsIndex;
    });
    _load();
  }

  Future<void> _deleteOrder(Order order) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(order.invoiceNo),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(AppStrings.employeeDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.orderRepository.remove(order.id);
    } on ApiException catch (error) {
      if (mounted) {
        showAppDialog(
          context,
          title: AppStrings.orderDeleteFailed,
          message: error.message,
        );
      }
      return;
    }
    await _load();
  }

  void _onNavSelected(int index) {
    if (index == AdminBottomNav.catalogIndex) {
      _openCatalog();
      return;
    }
    if (index == _navIndex) {
      return;
    }
    setState(() {
      _pushHistory(_navIndex);
      if (_navIndex == AdminBottomNav.transactionsIndex) {
        _resetOrdersFilters();
      }
      _navIndex = index;
    });
    _refreshIfOnTransactions();
  }

  Widget _buildBody(BuildContext context) {
    if (_navIndex == AdminBottomNav.transactionsIndex) {
      return _buildOrdersTab(context);
    }
    return AdminReportsView(onOpenOrders: _openFilteredOrders);
  }

  Widget _buildOrdersTab(BuildContext context) {
    if (_orders == null || _employees == null) {
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
                        ? OrdersList.grid(
                            orders: _filteredOrders,
                            onDelete: _deleteOrder,
                          )
                        : OrdersList(
                            orders: _filteredOrders,
                            onDelete: _deleteOrder,
                          ),
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
            horizontal: 12,
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

  Widget _buildOrdersDateFilterChip(BuildContext context) {
    final DateTime? date = _ordersFilterDate;
    final String label = date == null
        ? 'Semua Tanggal'
        : AppDateUtils.formatDate(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
        ),
        if (date != null)
          IconButton(
            onPressed: () => setState(() => _ordersFilterDate = null),
            tooltip: 'Hapus filter tanggal',
            icon: Icon(Icons.close, size: 18, color: AppColors.onSurfaceMuted),
          ),
      ],
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
      drawer: AdminDrawer(
        onOpenDashboard: () => _onNavSelected(AdminBottomNav.dashboardIndex),
        onOpenCatalog: _openCatalog,
        onOpenOrders: _openOrders,
        onOpenEmployees: _openEmployees,
        onOpenSettings: _openSettings,
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
            child: _navIndex != AdminBottomNav.dashboardIndex
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
          text: _navIndex == AdminBottomNav.transactionsIndex
              ? AppStrings.adminTransactions
              : AppStrings.brandName,
        ),
        actions: <Widget>[
          if (_navIndex == AdminBottomNav.dashboardIndex)
            IconButton(
              onPressed: _openEmployees,
              tooltip: AppStrings.adminEmployees,
              icon: const Icon(Icons.people_outline),
            ),
          const ThemeToggleButton(),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _navIndex,
        onSelected: _onNavSelected,
      ),
    );
  }
}
