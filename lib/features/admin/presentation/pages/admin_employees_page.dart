import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_title.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../widgets/admin_bottom_nav.dart';
import '../../../cashier/data/employee.dart';
import '../../../cashier/data/employee_repository.dart';

class AdminEmployeesPage extends StatefulWidget {
  const AdminEmployeesPage({
    super.key,
    this.employeeRepository = const EmployeeRepository(),
  });

  final EmployeeRepository employeeRepository;

  @override
  State<AdminEmployeesPage> createState() => _AdminEmployeesPageState();
}

class _AdminEmployeesPageState extends State<AdminEmployeesPage> {
  late final EmployeeRepository _repository = widget.employeeRepository;
  late List<Employee> _employees = _repository.fetchAll();
  String _searchQuery = '';

  List<Employee> get _visibleEmployees {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _employees;
    }
    return _employees
        .where(
          (Employee employee) =>
              employee.name.toLowerCase().contains(query) ||
              (employee.phone?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _openEditor({Employee? employee}) async {
    final Employee? result = await showDialog<Employee>(
      context: context,
      builder: (BuildContext context) => _EmployeeEditorDialog(
        employee: employee,
        employeeRepository: _repository,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      if (employee == null) {
        _repository.add(result);
      } else {
        _repository.update(result);
      }
      _employees = _repository.fetchAll();
    });
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(AppStrings.employeeDeleteTitle),
        content: Text(employee.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.employeeDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _repository.delete(employee.id);
      _employees = _repository.fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) =>
          _buildScaffold(context),
    );
  }

  void _onNavSelected(int index) {
    Navigator.of(context).pop(index);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: BrandTitle(text: AppStrings.employeesTitle),
        actions: <Widget>[
          const ThemeToggleButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPanel),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: -1,
        onSelected: _onNavSelected,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildSearchField(),
              ),
              Expanded(child: _buildEmployeeList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextField(
        onChanged: (String value) => setState(() => _searchQuery = value),
        style: TextStyle(fontSize: 15, color: AppColors.onSurface),
        decoration: InputDecoration(
          hintText: AppStrings.employeeSearchHint,
          prefixIcon: Icon(Icons.search, color: AppColors.onSurfaceMuted),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    final List<Employee> employees = _visibleEmployees;

    return employees.isEmpty
        ? Center(
            child: Text(
              _searchQuery.trim().isEmpty
                  ? AppStrings.employeesEmpty
                  : 'Tidak ada pegawai yang cocok',
              style: TextStyle(color: AppColors.onSurfaceMuted),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
            itemCount: employees.length,
            itemBuilder: (BuildContext context, int index) {
              final Employee employee = employees[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              employee.name,
                              style: TextStyle(
                                fontSize: 16.2,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'PIN: ${employee.pin}',
                              style: TextStyle(
                                fontSize: 14.4,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                            if (employee.phone != null &&
                                employee.phone!.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 2),
                              Text(
                                'Telp: ${employee.phone}',
                                style: TextStyle(
                                  fontSize: 14.4,
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openEditor(employee: employee),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteEmployee(employee),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class _EmployeeEditorDialog extends StatefulWidget {
  const _EmployeeEditorDialog({
    this.employee,
    required this.employeeRepository,
  });

  final Employee? employee;
  final EmployeeRepository employeeRepository;

  @override
  State<_EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<_EmployeeEditorDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.employee?.name,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.employee?.phone,
  );
  late final TextEditingController _pin = TextEditingController(
    text: widget.employee?.pin,
  );
  String? _errorText;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _name.text.trim();
    final String phone = _phone.text.trim();
    final String pin = _pin.text.trim();

    if (pin.length != EmployeeRepository.pinLength) {
      setState(() => _errorText = AppStrings.verifyOrderPinHint);
      return;
    }

    final Employee? existingWithPin = widget.employeeRepository.findByPin(pin);
    if (existingWithPin != null && existingWithPin.id != widget.employee?.id) {
      setState(() => _errorText = AppStrings.employeePinDuplicate);
      return;
    }

    final String id =
        widget.employee?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    Navigator.of(context).pop(
      Employee(
        id: id,
        name: name,
        pin: pin,
        phone: phone.isEmpty ? null : phone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.employee == null
            ? AppStrings.employeeAddTitle
            : AppStrings.employeeEditTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: AppStrings.employeeNameLabel,
              filled: true,
              fillColor: AppColors.panelSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: AppStrings.employeePhoneLabel,
              filled: true,
              fillColor: AppColors.panelSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pin,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: EmployeeRepository.pinLength,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              counterText: '',
              labelText: AppStrings.employeePinLabel,
              errorText: _errorText,
              filled: true,
              fillColor: AppColors.panelSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text(AppStrings.employeeSave),
        ),
      ],
    );
  }
}
