import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../data/store_repository.dart';
import '../theme/app_colors.dart';

/// Asks for the store's print PIN before a receipt is reprinted.
/// Pops true once the PIN is accepted by the server.
class PrintPinDialog extends StatefulWidget {
  const PrintPinDialog({
    super.key,
    this.storeRepository = const StoreRepository(),
  });

  final StoreRepository storeRepository;

  /// True when printing may go ahead: the PIN was accepted, or the store
  /// has no print PIN set.
  static Future<bool> confirm(
    BuildContext context, {
    StoreRepository storeRepository = const StoreRepository(),
  }) async {
    if (!StoreRepository.data.hasPrintPin) {
      return true;
    }
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          PrintPinDialog(storeRepository: storeRepository),
    );
    return ok ?? false;
  }

  @override
  State<PrintPinDialog> createState() => _PrintPinDialogState();
}

class _PrintPinDialogState extends State<PrintPinDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  bool _isChecking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isChecking || _controller.text.isEmpty) {
      return;
    }
    setState(() {
      _isChecking = true;
      _errorText = null;
    });
    bool valid;
    try {
      valid = await widget.storeRepository.verifyPrintPin(_controller.text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorText = 'Tidak dapat memeriksa PIN, coba lagi';
        });
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (!valid) {
      setState(() {
        _isChecking = false;
        _errorText = AppStrings.printPinWrong;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.printPinTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              AppStrings.printPinHint,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              enabled: !_isChecking,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: AppStrings.printPinLabel,
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isChecking
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isChecking ? null : _submit,
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.printPinConfirm),
        ),
      ],
    );
  }
}
