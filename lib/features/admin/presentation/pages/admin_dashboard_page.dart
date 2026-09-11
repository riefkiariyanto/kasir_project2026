import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/route_results.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../cashier/data/category_repository.dart';
import '../../../cashier/data/employee.dart';
import '../../../cashier/data/employee_repository.dart';
import '../../../cashier/data/order.dart';
import '../../../cashier/data/order_repository.dart';
import '../../../cashier/presentation/widgets/orders_list.dart';
import '../../../cashier/presentation/widgets/promo_banner.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    this.categoryRepository = const CategoryRepository(),
    this.orderRepository = const OrderRepository(),
    this.employeeRepository = const EmployeeRepository(),
  });

  final CategoryRepository categoryRepository;
  final OrderRepository orderRepository;
  final EmployeeRepository employeeRepository;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

enum _OrdersFilterPeriod { all, day, week, month }

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _navIndex = 0;
  final List<int> _navHistory = <int>[];
  String? _ordersFilterEmployee;
  DateTime? _ordersFilterDate;
  String _ordersSearchQuery = '';
  PaymentMethod? _ordersFilterMethod;
  _OrdersFilterPeriod _ordersFilterPeriod = _OrdersFilterPeriod.all;
  bool _ordersGridView = false;
  List<Order>? _orders;
  List<Employee>? _employees;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Order> orders = await widget.orderRepository.fetchAll();
    final List<Employee> employees = await widget.employeeRepository.fetchAll();
    if (mounted) {
      setState(() {
        _orders = orders;
        _employees = employees;
      });
    }
  }

  void _pushHistory(int from) {
    _navHistory.add(from);
    if (_navHistory.length > 20) _navHistory.removeAt(0);
  }

  Future<void> _goBack() async {
    final int target = _navHistory.isNotEmpty ? _navHistory.removeLast() : 0;
    setState(() {
      _ordersFilterEmployee = null;
      _ordersFilterDate = null;
      _ordersFilterMethod = null;
      _ordersSearchQuery = '';
      _ordersFilterPeriod = _OrdersFilterPeriod.all;
    });
    if (target == 1) {
      await _openReports();
    } else {
      setState(() => _navIndex = target);
    }
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      AppDateUtils.isSameDate(a, b);

  bool _isSameMonth(DateTime a, DateTime b) =>
      AppDateUtils.isSameMonth(a, b);

  bool _isSameWeek(DateTime a, DateTime b) =>
      AppDateUtils.isSameWeek(a, b);

  List<Order> get _filteredOrders {
    final String query = _ordersSearchQuery.trim().toLowerCase();
    final List<Order> all = _orders ?? const <Order>[];
    return all.where((Order order) {
      final bool matchesEmployee =
          _ordersFilterEmployee == null ||
          order.cashierName == _ordersFilterEmployee;
      final bool matchesDate =
          _ordersFilterDate == null ||
          _isSameDate(order.createdAt, _ordersFilterDate!);
      final bool matchesMethod =
          _ordersFilterMethod == null || order.method == _ordersFilterMethod;
      final bool matchesSearch =
          query.isEmpty || order.id.toLowerCase().contains(query);

      final DateTime now = DateTime.now();
      bool matchesPeriod = true;
      switch (_ordersFilterPeriod) {
        case _OrdersFilterPeriod.all:
          matchesPeriod = true;
          break;
        case _OrdersFilterPeriod.day:
          matchesPeriod = _isSameDate(order.createdAt, now);
          break;
        case _OrdersFilterPeriod.week:
          matchesPeriod = _isSameWeek(order.createdAt, now);
          break;
        case _OrdersFilterPeriod.month:
          matchesPeriod = _isSameMonth(order.createdAt, now);
          break;
      }

      return matchesEmployee &&
          matchesDate &&
          matchesMethod &&
          matchesSearch &&
          matchesPeriod;
    }).toList();
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

  String _formatFilterDate(DateTime date) => AppDateUtils.formatDate(date);

  Future<void> _openTransaction() async {
    final Object? result = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.transaction);

    if (result == RouteResults.openOrders && mounted) {
      setState(() => _navIndex = 3);
    }
  }

  Future<void> _openReports() => _openAdminPage(AppRoutes.adminReports);

  Future<void> _openCatalogFromHome() => _openAdminPage(AppRoutes.adminCatalog);

  Future<void> _openEmployees() => _openAdminPage(AppRoutes.adminEmployees);

  Future<void> _openAdminPage(String route) async {
    final Object? result = await Navigator.of(context).pushNamed(route);

    if (result is int && mounted) {
      _onNavSelected(result);
    } else if (result is Map<String, dynamic> && mounted) {
      final int targetIndex = (result['index'] as int?) ?? 3;
      if (targetIndex == 1) {
        _openReports();
      } else if (targetIndex == 2) {
        _openCatalogFromHome();
      } else if (targetIndex == 3) {
        setState(() {
          _pushHistory(1);
          _navIndex = 3;
          if (result.containsKey('employee')) {
            _ordersFilterEmployee = result['employee'] as String?;
          }
          if (result.containsKey('date')) {
            _ordersFilterDate = result['date'] as DateTime?;
          }
          if (result.containsKey('method')) {
            _ordersFilterMethod = result['method'] as PaymentMethod?;
          }
        });
      } else {
        setState(() {
          _navIndex = targetIndex;
          _ordersFilterEmployee = null;
          _ordersFilterDate = null;
          _ordersFilterMethod = null;
          _ordersSearchQuery = '';
          _ordersFilterPeriod = _OrdersFilterPeriod.all;
        });
      }
    }
  }

  void _openOrders() {
    setState(() {
      _pushHistory(_navIndex);
      _ordersFilterEmployee = null;
      _ordersFilterDate = null;
      _ordersFilterMethod = null;
      _ordersSearchQuery = '';
      _ordersFilterPeriod = _OrdersFilterPeriod.all;
      _navIndex = 3;
    });
  }

  Future<void> _deleteOrder(Order order) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text(order.id),
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

    await widget.orderRepository.remove(order.id);
    await _load();
  }

  void _onNavSelected(int index) {
    if (index == 1) {
      _openReports();
      return;
    }
    if (index == 2) {
      _openCatalogFromHome();
      return;
    }
    if (index == _navIndex) {
      return;
    }
    setState(() {
      _pushHistory(_navIndex);
      if (_navIndex == 3 && index != 3) {
        _ordersFilterEmployee = null;
        _ordersFilterDate = null;
        _ordersFilterMethod = null;
        _ordersSearchQuery = '';
        _ordersFilterPeriod = _OrdersFilterPeriod.all;
      }
      _navIndex = index;
    });
  }

  Widget _buildBody(BuildContext context) {
    switch (_navIndex) {
      case 3:
        return _buildOrdersTab(context);
      default:
        return _AdminHomeTab(
          onBannerTap: _openTransaction,
          onDashboardLaporanTap: _openReports,
          onTransaksiTap: _openOrders,
          onCatalogTap: _openCatalogFromHome,
          onDataPegawaiTap: _openEmployees,
        );
    }
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
                        : OrdersList(orders: _filteredOrders, onDelete: _deleteOrder),
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
            IntrinsicWidth(
              child: _buildEmployeeDropdown(context),
            ),
            const SizedBox(width: 6),
            IntrinsicWidth(
              child: _buildMethodDropdown(context),
            ),
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
        color: isSelected ? AppColors.onPanel : AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? Colors.transparent
            : AppColors.onSurfaceMuted.withValues(alpha: 0.25),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: isSelected ? 2 : 0,
      shadowColor: AppColors.navShadow,
    );
  }

    Widget _buildMethodDropdown(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
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
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Pegawai'),
          ),
          for (final String name in employeeNames)
            DropdownMenuItem<String?>(value: name, child: Text(name)),
        ],
      ),
    );
  }

  Widget _buildOrdersSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
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
            borderRadius: BorderRadius.circular(12),
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
        : _formatFilterDate(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
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
      backgroundColor: AppColors.surface,
      extendBody: true,
      drawer: AdminDrawer(
        onOpenTransaction: _openTransaction,
        onOpenOrders: _openOrders,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
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
          text: _navIndex == 3 ? AppStrings.adminTransactions : null,
        ),
        actions: <Widget>[
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

class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab({
    required this.onBannerTap,
    required this.onDashboardLaporanTap,
    required this.onTransaksiTap,
    required this.onCatalogTap,
    required this.onDataPegawaiTap,
  });

  static const double _maxContentWidth = 1080;

  final VoidCallback onBannerTap;
  final VoidCallback onDashboardLaporanTap;
  final VoidCallback onTransaksiTap;
  final VoidCallback onCatalogTap;
  final VoidCallback onDataPegawaiTap;

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
              'Menu Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _AdminQuickMenuGrid(
              onDashboardLaporanTap: onDashboardLaporanTap,
              onTransaksiTap: onTransaksiTap,
              onCatalogTap: onCatalogTap,
              onDataPegawaiTap: onDataPegawaiTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminQuickMenuGrid extends StatelessWidget {
  const _AdminQuickMenuGrid({
    required this.onDashboardLaporanTap,
    required this.onTransaksiTap,
    required this.onCatalogTap,
    required this.onDataPegawaiTap,
  });

  final VoidCallback onDashboardLaporanTap;
  final VoidCallback onTransaksiTap;
  final VoidCallback onCatalogTap;
  final VoidCallback onDataPegawaiTap;

  @override
  Widget build(BuildContext context) {
    final List<_AdminMenuItem> items = <_AdminMenuItem>[
      _AdminMenuItem(
        icon: Icons.dashboard_outlined,
        label: AppStrings.adminDashboardReport,
        onTap: onDashboardLaporanTap,
      ),
      _AdminMenuItem(
        icon: Icons.receipt_long_outlined,
        label: AppStrings.adminTransactions,
        onTap: onTransaksiTap,
      ),
      _AdminMenuItem(
        icon: Icons.inventory_2_outlined,
        label: AppStrings.adminProducts,
        onTap: onCatalogTap,
      ),
      _AdminMenuItem(
        icon: Icons.people_outline,
        label: AppStrings.adminEmployees,
        onTap: onDataPegawaiTap,
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
        final _AdminMenuItem item = items[index];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.surface,
                  AppColors.surface.withValues(alpha: 0.94),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
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


class _AdminMenuItem {
  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
