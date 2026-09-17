import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../data/auth_repository.dart';
import 'auth_text_field.dart';

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
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _submit() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);

    String? error;
    try {
      final bool isValid = await widget.authRepository.login(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      if (!isValid) {
        error = AppStrings.loginFailed;
      }
    } on ApiException catch (e) {
      error = e.message;
    }

    if (!mounted) {
      return;
    }
    setState(() => _isLoading = false);

    if (error == null) {
      widget.onSuccess();
      return;
    }

    showAppDialog(context, title: AppStrings.loginFailedTitle, message: error);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Text(
                  AppStrings.loginButton,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ],
    );
  }
}
