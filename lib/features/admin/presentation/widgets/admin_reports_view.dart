import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cashier/data/cart_item.dart';
import '../../../cashier/data/employee.dart';
import '../../../cashier/data/employee_repository.dart';
import '../../../cashier/data/finance_entry.dart';
import '../../../cashier/data/finance_repository.dart';
import '../../../cashier/data/order.dart';
import '../../../cashier/data/order_repository.dart';

/// Called when a summary card's detail link is tapped, to open the
/// transaction history pre-filtered to what that card counted.
typedef OpenFilteredOrders =
    void Function({String? employee, DateTime? date, PaymentMethod? method});

/// Sales report shown as the admin home tab.
class AdminReportsView extends StatefulWidget {
  const AdminReportsView({
    super.key,
    required this.onOpenOrders,
    this.orderRepository = const OrderRepository(),
    this.financeRepository = const FinanceRepository(),
    this.employeeRepository = const EmployeeRepository(),
  });

  final OpenFilteredOrders onOpenOrders;
  final OrderRepository orderRepository;
  final FinanceRepository financeRepository;
  final EmployeeRepository employeeRepository;

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

enum _ReportFilterMode { all, day, week, month }

class _AdminReportsViewState extends State<AdminReportsView> {
  static const List<String> _monthNames = <String>[
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  _ReportFilterMode _filterMode = _ReportFilterMode.all;
  DateTime? _selectedDate;
  bool _donutByCategory = false;
  String? _employeeFilter;

  List<Order>? _orders;
  List<FinanceEntry>? _financeEntries;
  List<Employee>? _employees;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (
      List<Order> orders,
      List<FinanceEntry> finance,
      List<Employee> employees,
    ) = await (
      widget.orderRepository.fetchAll(),
      widget.financeRepository.fetchAll(),
      widget.employeeRepository.fetchAll(),
    ).wait;
    if (mounted) {
      setState(() {
        _orders = orders;
        _financeEntries = finance;
        _employees = employees;
      });
    }
  }

  bool _isSameDate(DateTime a, DateTime b) => AppDateUtils.isSameDate(a, b);

  bool _isSameMonth(DateTime a, DateTime b) => AppDateUtils.isSameMonth(a, b);

  bool _isSameWeek(DateTime a, DateTime b) => AppDateUtils.isSameWeek(a, b);

  List<Order> get _filteredOrders {
    final List<Order> all = _orders ?? const <Order>[];
    final DateTime anchor = _selectedDate ?? DateTime.now();
    List<Order> byPeriod;
    switch (_filterMode) {
      case _ReportFilterMode.all:
        byPeriod = all;
        break;
      case _ReportFilterMode.day:
        byPeriod = all
            .where((Order order) => _isSameDate(order.createdAt, anchor))
            .toList();
        break;
      case _ReportFilterMode.week:
        byPeriod = all
            .where((Order order) => _isSameWeek(order.createdAt, anchor))
            .toList();
        break;
      case _ReportFilterMode.month:
        byPeriod = all
            .where((Order order) => _isSameMonth(order.createdAt, anchor))
            .toList();
        break;
    }
    if (_employeeFilter != null) {
      byPeriod = byPeriod
          .where((Order o) => o.cashierName == _employeeFilter)
          .toList();
    }
    return byPeriod;
  }

  int get _totalTransactions => _filteredOrders.length;

  int get _totalItemsSold =>
      _filteredOrders.fold(0, (int sum, Order order) => sum + order.itemCount);

  List<FinanceEntry> get _filteredFinance {
    final List<FinanceEntry> all = _financeEntries ?? const <FinanceEntry>[];
    final DateTime anchor = _selectedDate ?? DateTime.now();
    List<FinanceEntry> byPeriod;
    switch (_filterMode) {
      case _ReportFilterMode.all:
        byPeriod = all;
        break;
      case _ReportFilterMode.day:
        byPeriod = all
            .where((FinanceEntry e) => _isSameDate(e.createdAt, anchor))
            .toList();
        break;
      case _ReportFilterMode.week:
        byPeriod = all
            .where((FinanceEntry e) => _isSameWeek(e.createdAt, anchor))
            .toList();
        break;
      case _ReportFilterMode.month:
        byPeriod = all
            .where((FinanceEntry e) => _isSameMonth(e.createdAt, anchor))
            .toList();
        break;
    }
    if (_employeeFilter != null) {
      byPeriod = byPeriod
          .where((FinanceEntry e) => e.employeeName == _employeeFilter)
          .toList();
    }
    return byPeriod;
  }

  int get _totalLoan => _filteredFinance
      .where((FinanceEntry e) => e.type == FinanceType.loan)
      .fold(0, (int sum, FinanceEntry e) => sum + e.amount);

  int get _totalTransfer => _filteredFinance
      .where((FinanceEntry e) => e.type == FinanceType.transfer)
      .fold(0, (int sum, FinanceEntry e) => sum + e.amount);

  int get _totalRevenue =>
      _filteredOrders.fold(0, (int sum, Order order) => sum + order.total);

  int get _netRevenue => _totalRevenue - _totalLoan;

  int _revenueByMethod(PaymentMethod method) {
    int base = _filteredOrders
        .where((Order order) => order.method == method)
        .fold(0, (int sum, Order order) => sum + order.total);
    if (method == PaymentMethod.cash) {
      base -= _totalTransfer;
    } else if (method == PaymentMethod.qris) {
      base += _totalTransfer;
    }
    return base;
  }

  List<({String name, int quantity, int revenue})> get _productSales {
    final Map<String, ({int quantity, int revenue})> totals =
        <String, ({int quantity, int revenue})>{};
    for (final Order order in _filteredOrders) {
      for (final CartItem item in order.items) {
        final ({int quantity, int revenue})? existing =
            totals[item.product.name];
        totals[item.product.name] = (
          quantity: (existing?.quantity ?? 0) + item.quantity,
          revenue: (existing?.revenue ?? 0) + item.subtotal,
        );
      }
    }
    final List<({String name, int quantity, int revenue})> entries =
        totals.entries
            .map(
              (MapEntry<String, ({int quantity, int revenue})> entry) => (
                name: entry.key,
                quantity: entry.value.quantity,
                revenue: entry.value.revenue,
              ),
            )
            .toList()
          ..sort(
            (
              ({String name, int quantity, int revenue}) a,
              ({String name, int quantity, int revenue}) b,
            ) => b.quantity.compareTo(a.quantity),
          );
    return entries;
  }

  List<({String name, int value})> get _categoryOrderCounts {
    final Map<String, int> totals = <String, int>{};
    for (final Order order in _filteredOrders) {
      for (final CartItem item in order.items) {
        totals[item.product.category] =
            (totals[item.product.category] ?? 0) + item.quantity;
      }
    }
    final List<({String name, int value})> entries =
        totals.entries
            .map(
              (MapEntry<String, int> entry) =>
                  (name: entry.key, value: entry.value),
            )
            .toList()
          ..sort(
            (({String name, int value}) a, ({String name, int value}) b) =>
                b.value.compareTo(a.value),
          );
    return entries;
  }

  List<({String name, int value})> get _productOrderCounts {
    final List<({String name, int value})> entries =
        _productSales
            .map(
              (({String name, int quantity, int revenue}) e) =>
                  (name: e.name, value: e.quantity),
            )
            .toList()
          ..sort(
            (({String name, int value}) a, ({String name, int value}) b) =>
                b.value.compareTo(a.value),
          );
    return entries;
  }

  List<({String name, int value})> _capForDonut(
    List<({String name, int value})> entries,
  ) {
    const int maxSlices = 5;
    if (entries.length <= maxSlices + 1) {
      return entries;
    }
    final List<({String name, int value})> top = entries
        .take(maxSlices)
        .toList();
    final int othersTotal = entries
        .skip(maxSlices)
        .fold(0, (int sum, ({String name, int value}) e) => sum + e.value);
    return <({String name, int value})>[
      ...top,
      (name: 'Lainnya', value: othersTotal),
    ];
  }

  Future<void> _pickAnchorDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectFilterMode(_ReportFilterMode mode) {
    setState(() {
      _filterMode = mode;
      if (mode != _ReportFilterMode.all) {
        _selectedDate ??= DateTime.now();
      }
    });
  }

  String get _periodLabel {
    final DateTime anchor = _selectedDate ?? DateTime.now();
    switch (_filterMode) {
      case _ReportFilterMode.all:
        return 'Semua Waktu';
      case _ReportFilterMode.day:
        return _formatDate(anchor);
      case _ReportFilterMode.week:
        final DateTime start = AppDateUtils.startOfWeek(anchor);
        final DateTime end = start.add(const Duration(days: 6));
        return '${_formatDate(start)} - ${_formatDate(end)}';
      case _ReportFilterMode.month:
        return '${_monthNames[anchor.month - 1]} ${anchor.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<({String name, int quantity, int revenue})> productSales =
        _productSales;
    final String revenueLabel = 'Pendapatan $_periodLabel';
    final bool hasData = productSales.isNotEmpty;

    return _orders == null || _financeEntries == null || _employees == null
        ? const Center(child: CircularProgressIndicator())
        : Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: <Widget>[
                  Text(
                    'Ringkasan Penjualan',
                    style: TextStyle(
                      fontSize: 19.2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(context),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ReportCard(
                          title: 'Transaksi',
                          value: '$_totalTransactions',
                          icon: Icons.receipt_long_outlined,
                          onDetailTap: () => widget.onOpenOrders(
                            employee: _employeeFilter,
                            date: _selectedDate,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'Produk Terjual',
                          value: '$_totalItemsSold',
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ReportCard(
                          title: 'Tunai',
                          value:
                              '+${CurrencyFormatter.rupiah(_revenueByMethod(PaymentMethod.cash))}',
                          icon: Icons.money_outlined,
                          isPositive: true,
                          onDetailTap: () => widget.onOpenOrders(
                            employee: _employeeFilter,
                            date: _selectedDate,
                            method: PaymentMethod.cash,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'QRIS',
                          value:
                              '+${CurrencyFormatter.rupiah(_revenueByMethod(PaymentMethod.qris))}',
                          icon: Icons.qr_code_2_outlined,
                          isPositive: true,
                          onDetailTap: () => widget.onOpenOrders(
                            employee: _employeeFilter,
                            date: _selectedDate,
                            method: PaymentMethod.qris,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ReportCard(
                          title: revenueLabel,
                          value: '+${CurrencyFormatter.rupiah(_netRevenue)}',
                          icon: Icons.payments_outlined,
                          isPositive: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          title: 'Pengeluaran $_periodLabel',
                          value: _totalLoan > 0
                              ? '-${CurrencyFormatter.rupiah(_totalLoan)}'
                              : CurrencyFormatter.rupiah(0),
                          icon: Icons.money_off_outlined,
                          isPositive: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildFinanceHistorySection(),
                  if (hasData) ...<Widget>[
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final Widget productList =
                                _buildProductSalesSection(productSales);
                            final Widget donut = _buildDonutSection();

                            if (constraints.maxWidth >= 700) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(flex: 3, child: productList),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 2, child: donut),
                                ],
                              );
                            }

                            return Column(
                              children: <Widget>[
                                donut,
                                const SizedBox(height: 24),
                                productList,
                              ],
                            );
                          },
                    ),
                  ],
                ],
              ),
            ),
          );
  }

  Widget _buildFinanceHistorySection() {
    final List<FinanceEntry> entries = _filteredFinance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Riwayat Pinjam & Transfer Tunai',
          style: TextStyle(
            fontSize: 19.2,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: ClayDecoration(
              sunken: true,
              color: AppColors.panelSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Belum ada riwayat pinjam / transfer tunai pada periode ini',
              style: TextStyle(color: AppColors.onSurfaceMuted),
            ),
          )
        else
          for (final FinanceEntry entry in entries)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: ClayDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.type == FinanceType.loan
                          ? Colors.red.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      entry.type == FinanceType.loan
                          ? Icons.money_off
                          : Icons.swap_horiz,
                      size: 18,
                      color: entry.type == FinanceType.loan
                          ? Colors.red
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.employeeName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.type == FinanceType.loan
                              ? AppStrings.financeLoanOf
                              : AppStrings.financeTransferOf,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.rupiah(entry.amount),
                    style: TextStyle(
                      fontSize: 15.6,
                      fontWeight: FontWeight.bold,
                      color: entry.type == FinanceType.loan
                          ? Colors.red
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildProductSalesSection(
    List<({String name, int quantity, int revenue})> productSales,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Penjualan per Produk',
          style: TextStyle(
            fontSize: 19.2,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < productSales.length; i++)
          _ProductSalesRow(
            rank: i + 1,
            name: productSales[i].name,
            quantity: productSales[i].quantity,
            revenue: productSales[i].revenue,
          ),
      ],
    );
  }

  Widget _buildDonutSection() {
    final List<({String name, int value})> donutData = _capForDonut(
      _donutByCategory ? _categoryOrderCounts : _productOrderCounts,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Distribusi Pesanan',
          style: TextStyle(
            fontSize: 19.2,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _buildDonutToggleChip('Per Produk', byCategory: false),
            _buildDonutToggleChip('Per Kategori', byCategory: true),
          ],
        ),
        const SizedBox(height: 12),
        _DonutChart(data: donutData, total: _totalItemsSold),
      ],
    );
  }

  Widget _buildDonutToggleChip(String label, {required bool byCategory}) {
    final bool isSelected = _donutByCategory == byCategory;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _donutByCategory = byCategory),
      backgroundColor: AppColors.panelSurface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : AppColors.inputBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _buildModeChip('Semua', _ReportFilterMode.all),
              _buildModeChip('Harian', _ReportFilterMode.day),
              _buildModeChip('Mingguan', _ReportFilterMode.week),
              _buildModeChip('Bulanan', _ReportFilterMode.month),
              if (_filterMode != _ReportFilterMode.all)
                _buildAnchorPicker(context),
              _buildEmployeeFilterButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeFilterButton(BuildContext context) {
    final List<Employee> employees = _employees ?? const <Employee>[];
    final String label = _employeeFilter ?? 'Semua Pegawai';

    return PopupMenuButton<String?>(
      initialValue: _employeeFilter,
      onSelected: (String? value) => setState(() => _employeeFilter = value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: AppColors.panelSurface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String?>>[
        PopupMenuItem<String?>(
          value: null,
          child: Row(
            children: <Widget>[
              Icon(Icons.people_outline, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Semua Pegawai'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final Employee emp in employees)
          PopupMenuItem<String?>(
            value: emp.name,
            child: Row(
              children: <Widget>[
                Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Text(emp.name),
              ],
            ),
          ),
      ],
      child: Material(
        color: AppColors.panelSurface,
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
              Icon(Icons.badge_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: AppColors.onSurfaceMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, _ReportFilterMode mode) {
    final bool isSelected = _filterMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _selectFilterMode(mode),
      backgroundColor: AppColors.panelSurface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      side: BorderSide(
        color: isSelected ? Colors.transparent : AppColors.inputBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildAnchorPicker(BuildContext context) {
    return Material(
      color: AppColors.panelSurface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _pickAnchorDate(context),
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
                _periodLabel,
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
    );
  }

  String _formatDate(DateTime date) => AppDateUtils.formatDate(date);
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isPositive,
    this.onDetailTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool? isPositive;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.4, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 21.6,
                      fontWeight: FontWeight.bold,
                      color: isPositive == null
                          ? AppColors.onSurface
                          : (isPositive! ? Colors.green : Colors.red),
                    ),
                  ),
                ),
                if (onDetailTap != null)
                  TextButton(
                    onPressed: onDetailTap,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Detail'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSalesRow extends StatelessWidget {
  const _ProductSalesRow({
    required this.rank,
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final int rank;
  final String name;
  final int quantity;
  final int revenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'x$quantity dipesan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.rupiah(revenue),
                  style: TextStyle(
                    fontSize: 15.6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.data, required this.total});

  final List<({String name, int value})> data;
  final int total;

  // Pastel clay tones: brand pink first, then hues far enough apart on the
  // colour wheel that neighbouring slices stay distinguishable.
  static const List<Color> _palette = <Color>[
    Color(0xFFE0569E),
    Color(0xFF6CC3A0),
    Color(0xFFF2B447),
    Color(0xFF7F9CF0),
    Color(0xFFF08A7E),
    Color(0xFFAE85DE),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: ClayDecoration(
          sunken: true,
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Belum ada data untuk ditampilkan',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
      );
    }

    final List<double> proportions = data
        .map((({String name, int value}) e) => e.value / total)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 210,
            height: 210,
            child: CustomPaint(
              painter: _DonutChartPainter(
                values: proportions,
                colors: _palette,
                trackColor: AppColors.panelSurface,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$total kali\ndipesan',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < data.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${data[i].value}x • ${(data[i].value / total * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.22;
    final Rect arcRect = (Offset.zero & size).deflate(strokeWidth / 2);

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, trackPaint);

    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final double sweep = values[i] * 2 * math.pi;
      final Paint segmentPaint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(arcRect, startAngle, sweep, false, segmentPaint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor;
  }
}
