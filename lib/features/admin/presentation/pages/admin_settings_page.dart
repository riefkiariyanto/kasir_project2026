import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/brand_title.dart';
import '../widgets/admin_bottom_nav.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../cashier/data/category_repository.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({
    super.key,
    this.categoryRepository = const CategoryRepository(),
    this.authRepository = const AuthRepository(),
  });

  final CategoryRepository categoryRepository;
  final AuthRepository authRepository;

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late final CategoryRepository _repository = widget.categoryRepository;
  late List<ProductCategory> _categories = _repository.fetchAll();

  Future<void> _openChangePassword() async {
    final bool? changed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          _ChangePasswordDialog(authRepository: widget.authRepository),
    );

    if (changed == true && mounted) {
      showAppDialog(
        context,
        title: AppStrings.changePasswordTitle,
        message: AppStrings.passwordChanged,
      );
    }
  }

  Future<void> _addCategory() async {
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(AppStrings.categoryAddTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: AppStrings.categoryNameHint,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text(AppStrings.categoryAdd),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }

    setState(() {
      _repository.add(
        ProductCategory(name: name, icon: Icons.category_outlined),
      );
      _categories = _repository.fetchAll();
    });
  }

  Future<void> _deleteCategory(ProductCategory category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text(AppStrings.categoryDeleteTitle),
        content: Text(category.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.categoryDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _repository.delete(category.name);
      _categories = _repository.fetchAll();
    });
  }

  void _onNavSelected(int index) {
    Navigator.of(context).pop(index);
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
        title: BrandTitle(text: AppStrings.adminSettings),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: -1,
        onSelected: _onNavSelected,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildCategoryChips(),
                const SizedBox(height: 28),
                _buildAccountSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.categorySettingsTitle,
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ..._categories.map(
              (ProductCategory category) => InputChip(
                label: Text(category.name),
                labelStyle: TextStyle(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15.6,
                ),
                backgroundColor: AppColors.panelSurface,
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.onSurfaceMuted,
                ),
                onDeleted: () => _deleteCategory(category),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            ActionChip(
              avatar: Icon(Icons.add, size: 16, color: AppColors.primary),
              label: Text(AppStrings.categoryAdd),
              onPressed: _addCategory,
              backgroundColor: AppColors.panelSurface,
              labelStyle: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 15.6,
              ),
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          AppStrings.accountSectionTitle,
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.cardShadow,
          ),
          child: ListTile(
            onTap: _openChangePassword,
            leading: Icon(Icons.lock_outline, color: AppColors.primary),
            title: Text(
              AppStrings.changePasswordTitle,
              style: TextStyle(
                fontSize: 15.6,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    final String current = _currentPassword.text;
    final String newPassword = _newPassword.text;
    final String confirm = _confirmPassword.text;

    if (newPassword.length < 4) {
      setState(() => _errorText = AppStrings.passwordTooShort);
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorText = AppStrings.passwordMismatch);
      return;
    }

    final bool success = widget.authRepository.changePassword(
      currentPassword: current,
      newPassword: newPassword,
    );

    if (!success) {
      setState(() => _errorText = AppStrings.currentPasswordWrong);
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.changePasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _currentPassword,
            obscureText: true,
            decoration: InputDecoration(
              labelText: AppStrings.currentPasswordLabel,
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
            controller: _newPassword,
            obscureText: true,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: AppStrings.newPasswordLabel,
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
            controller: _confirmPassword,
            obscureText: true,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              labelText: AppStrings.confirmPasswordLabel,
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
        FilledButton(onPressed: _submit, child: const Text(AppStrings.save)),
      ],
    );
  }
}
