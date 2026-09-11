import 'package:flutter/material.dart';

import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../cashier/data/employee_repository.dart';
import '../../../cashier/data/order_repository.dart';

enum OrdersFilterPeriod { all, day, week, month }

class OrderFilterBar extends StatefulWidget {
  const OrderFilterBar({
    super.key,
    required this.orderRepository,
    required this.employeeRepository,
    required this.ordersFilterEmployee,
    required this.ordersFilterDate,
    required this.ordersFilterMethod,
    required this.ordersFilterPeriod,
    required this.ordersSearchQuery,
    required this.onOrdersFilterEmployeeChanged,
    required this.onOrdersFilterDateChanged,
    required this.onOrdersFilterMethodChanged,
    required this.onOrdersFilterPeriodChanged,
    required this.onOrdersSearchQueryChanged,
    required this.onPickOrdersFilterDate,
  });

  final OrderRepository orderRepository;
  final EmployeeRepository employeeRepository;
  final String? ordersFilterEmployee;
  final DateTime? ordersFilterDate;
  final PaymentMethod? ordersFilterMethod;
  final OrdersFilterPeriod ordersFilterPeriod;
  final String ordersSearchQuery;
  final ValueChanged<String?> onOrdersFilterEmployeeChanged;
  final ValueChanged<DateTime?> onOrdersFilterDateChanged;
  final ValueChanged<PaymentMethod?> onOrdersFilterMethodChanged;
  final ValueChanged<OrdersFilterPeriod> onOrdersFilterPeriodChanged;
  final ValueChanged<String> onOrdersSearchQueryChanged;
  final VoidCallback onPickOrdersFilterDate;

  @override
  State<OrderFilterBar> createState() => _OrderFilterBarState();
}

class _OrderFilterBarState extends State<OrderFilterBar> {
  String _formatFilterDate(DateTime date) => AppDateUtils.formatDate(date);

  List<String> get _employeeNames =>
      widget.employeeRepository.fetchAll().map((e) => e.name).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildOrdersSearchField(),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              _buildPeriodChip('Hari Ini', OrdersFilterPeriod.day),
              const SizedBox(width: 4),
              _buildPeriodChip('Minggu Ini', OrdersFilterPeriod.week),
              const SizedBox(width: 4),
              _buildPeriodChip('Bulan Ini', OrdersFilterPeriod.month),
              const SizedBox(width: 4),
              _buildPeriodChip('Semua', OrdersFilterPeriod.all),
              const SizedBox(width: 4),
              SizedBox(width: 170, child: _buildEmployeeDropdown()),
              const SizedBox(width: 4),
              SizedBox(width: 130, child: _buildMethodDropdown()),
              const SizedBox(width: 4),
              _buildOrdersDateFilterChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersSearchField() {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: widget.onOrdersSearchQueryChanged,
        style: TextStyle(fontSize: 15, color: AppColors.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Cari ID pesanan',
          prefixIcon: Icon(Icons.search, size: 18, color: AppColors.onSurfaceMuted),
          filled: true,
          fillColor: AppColors.panelSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppColors.inputBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, OrdersFilterPeriod period) {
    final bool isSelected = widget.ordersFilterPeriod == period;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => widget.onOrdersFilterPeriodChanged(period),
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

  Widget _buildMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod?>(
      isExpanded: true,
      initialValue: widget.ordersFilterMethod,
      onChanged: widget.onOrdersFilterMethodChanged,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.panelSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      style: TextStyle(fontSize: 14, color: AppColors.onSurface),
      items: const <DropdownMenuItem<PaymentMethod?>>[
        DropdownMenuItem<PaymentMethod?>(value: null, child: Text('Pembayaran')),
        DropdownMenuItem<PaymentMethod?>(value: PaymentMethod.cash, child: Text('Tunai')),
        DropdownMenuItem<PaymentMethod?>(value: PaymentMethod.qris, child: Text('QRIS')),
      ],
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: widget.ordersFilterEmployee,
      hint: const Text('Pegawai'),
      onChanged: widget.onOrdersFilterEmployeeChanged,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.panelSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
      ),
      style: TextStyle(fontSize: 15, color: AppColors.onSurface),
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(value: null, child: Text('Pegawai')),
        for (final String name in _employeeNames)
          DropdownMenuItem<String?>(value: name, child: Text(name)),
      ],
    );
  }

  Widget _buildOrdersDateFilterChip() {
    final DateTime? date = widget.ordersFilterDate;
    final String label = date == null ? 'Semua Tanggal' : _formatFilterDate(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: AppColors.panelSurface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onPickOrdersFilterDate,
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
                  Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                ],
              ),
            ),
          ),
        ),
        if (date != null)
          IconButton(
            onPressed: () => widget.onOrdersFilterDateChanged(null),
            tooltip: 'Hapus filter tanggal',
            icon: Icon(Icons.close, size: 18, color: AppColors.onSurfaceMuted),
          ),
      ],
    );
  }
}
