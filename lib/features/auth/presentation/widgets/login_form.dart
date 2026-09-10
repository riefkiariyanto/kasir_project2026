import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/auth_repository.dart';
import 'auth_text_field.dart';
import 'translucent_panel.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.onSuccess,
    this.authRepository = const AuthRepository(),
  });

  final VoidCallback onSuccess;
  final AuthRepository authRepository;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  static final ButtonStyle _buttonStyle = ElevatedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPanel,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final bool isValid = widget.authRepository.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (isValid) {
      widget.onSuccess();
      return;
    }

    showAppDialog(
      context,
      title: AppStrings.loginFailedTitle,
      message: AppStrings.loginFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TranslucentPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AuthTextField(
            controller: _usernameController,
            label: AppStrings.usernameLabel,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: AppStrings.passwordLabel,
            icon: Icons.lock_outline,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: _buttonStyle,
            child: const Text(
              AppStrings.loginButton,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
