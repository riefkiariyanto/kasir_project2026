import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/route_results.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
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
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  DateTime _startOfWeek(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final DateTime startA = _startOfWeek(a);
    final DateTime startB = _startOfWeek(b);
    return _isSameDate(startA, startB);
  }

  List<Order> get _filteredOrders {
    final String query = _ordersSearchQuery.trim().toLowerCase();
    return widget.orderRepository.fetchAll().where((Order order) {
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

  String _formatFilterDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

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
      setState(() {
        if (targetIndex == 3) {
          _pushHistory(1);
        }
        _navIndex = targetIndex;
        if (result.containsKey('employee')) {
          _ordersFilterEmployee = result['employee'] as String?;
        }
        if (result.containsKey('date')) {
          _ordersFilterDate = result['date'] as DateTime?;
        }
        if (result.containsKey('method')) {
          _ordersFilterMethod = result['method'] as PaymentMethod?;
        }
        if (result.containsKey('filterMode')) {
          // Reset/apply filter mode if passed
        }
      });
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
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildOrdersFilterBar(context),
            ),
          ),
        ),
        Expanded(child: OrdersList(orders: _filteredOrders)),
      ],
    );
  }

  Widget _buildOrdersFilterBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildOrdersSearchField(),
        const SizedBox(height: 8),
        SingleChildScrollView(
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
              SizedBox(
                width: 170,
                child: _buildEmployeeDropdown(context),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 130,
                child: _buildMethodDropdown(context),
              ),
              const SizedBox(width: 6),
              _buildOrdersDateFilterChip(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, _OrdersFilterPeriod period) {
    final bool isSelected = _ordersFilterPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _ordersFilterPeriod = period),
      backgroundColor: AppColors.panelSurface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPanel : AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : AppColors.inputBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildMethodDropdown(BuildContext context) {
    return DropdownButtonFormField<PaymentMethod?>(
      isExpanded: true,
      initialValue: _ordersFilterMethod,
      onChanged: (PaymentMethod? value) =>
          setState(() => _ordersFilterMethod = value),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.panelSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      style: TextStyle(fontSize: 14, color: AppColors.onSurface),
      items: const <DropdownMenuItem<PaymentMethod?>>[
        DropdownMenuItem<PaymentMethod?>(
          value: null,
          child: Text('Semua'),
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
    );
  }

  Widget _buildEmployeeDropdown(BuildContext context) {
    final List<String> employeeNames = widget.employeeRepository
        .fetchAll()
        .map((Employee employee) => employee.name)
        .toList();

    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: _ordersFilterEmployee,
      hint: const Text('Semua Pegawai'),
      onChanged: (String? value) =>
          setState(() => _ordersFilterEmployee = value),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.panelSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      style: TextStyle(fontSize: 15, color: AppColors.onSurface),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Semua Pegawai'),
        ),
        for (final String name in employeeNames)
          DropdownMenuItem<String?>(value: name, child: Text(name)),
      ],
    );
  }

  Widget _buildOrdersSearchField() {
    return TextField(
      onChanged: (String value) => setState(() => _ordersSearchQuery = value),
      style: TextStyle(fontSize: 15, color: AppColors.onSurface),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Cari ID pesanan',
        prefixIcon: Icon(
          Icons.search,
          size: 18,
          color: AppColors.onSurfaceMuted,
        ),
        filled: true,
        fillColor: AppColors.panelSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.inputBorder),
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
        Material(
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _pickOrdersFilterDate(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBorder),
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
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () =>
                  showComingSoonDialog(context, AppStrings.cashierInbox),
              tooltip: AppStrings.cashierInbox,
              icon: const Icon(Icons.mail_outline),
            ),
          ),
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
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(item.icon, size: 36, color: AppColors.onSurface),
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
        );
      },
    );
  }
}

class _EmployeePerformanceSection extends StatelessWidget {
  const _EmployeePerformanceSection({
    required this.employees,
    required this.orders,
  });

  final List<Employee> employees;
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = <String, int>{};
    for (final Order order in orders) {
      counts[order.cashierName] = (counts[order.cashierName] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Performa Pegawai',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (employees.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Belum ada pegawai',
              style: TextStyle(color: AppColors.onSurfaceMuted),
            ),
          )
        else
          for (final Employee employee in employees)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      employee.name,
                      style: TextStyle(
                        fontSize: 15.6,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${counts[employee.name] ?? 0} transaksi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
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
