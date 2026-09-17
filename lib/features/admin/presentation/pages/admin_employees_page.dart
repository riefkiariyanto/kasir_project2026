import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/widgets/app_dialog.dart';
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
  List<Employee>? _employees;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Employee> employees = await _repository.fetchAll();
    if (mounted) {
      setState(() => _employees = employees);
    }
  }

  List<Employee> get _visibleEmployees {
    final List<Employee> employees = _employees ?? const <Employee>[];
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return employees;
    }
    return employees
        .where(
          (Employee employee) =>
              employee.name.toLowerCase().contains(query) ||
              (employee.phone?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _openEditor({Employee? employee}) async {
    final _EmployeeFormResult? result = await showDialog<_EmployeeFormResult>(
      context: context,
      builder: (BuildContext context) =>
          _EmployeeEditorDialog(employee: employee),
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      if (employee == null) {
        await _repository.add(
          name: result.name,
          phone: result.phone,
          pin: result.pin!,
        );
      } else {
        await _repository.update(
          id: employee.id,
          name: result.name,
          phone: result.phone,
          pin: result.pin,
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        showAppDialog(
          context,
          title: AppStrings.employeeAddTitle,
          message: e.message,
        );
      }
    }
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

    await _repository.delete(employee.id);
    await _load();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.onSurface, size: 28),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: AppStrings.back,
          icon: const Icon(Icons.arrow_back),
        ),
        title: BrandTitle(text: AppStrings.employeesTitle),
        actions: <Widget>[const ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.onPrimary),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: -1,
        onSelected: _onNavSelected,
      ),
      body: _employees == null
          ? const Center(child: CircularProgressIndicator())
          : Align(
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
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
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

    return PullToRefresh(
      onRefresh: _load,
      child: employees.isEmpty
          ? PullToRefresh.fillViewport(
              Center(
                child: Text(
                  _searchQuery.trim().isEmpty
                      ? AppStrings.employeesEmpty
                      : 'Tidak ada pegawai yang cocok',
                  style: TextStyle(color: AppColors.onSurfaceMuted),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: employees.length,
              itemBuilder: (BuildContext context, int index) {
                final Employee employee = employees[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: ClayDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
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
            ),
    );
  }
}

class _EmployeeEditorDialog extends StatefulWidget {
  const _EmployeeEditorDialog({this.employee});

  final Employee? employee;

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
  late final TextEditingController _pin = TextEditingController();
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

    Navigator.of(context).pop(
      _EmployeeFormResult(
        name: name,
        phone: phone.isEmpty ? null : phone,
        pin: pin,
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
                borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(16),
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

class _EmployeeFormResult {
  const _EmployeeFormResult({required this.name, this.phone, this.pin});

  final String name;
  final String? phone;
  final String? pin;
}
