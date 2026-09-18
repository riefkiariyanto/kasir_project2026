import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import '../data/api_client.dart';
import '../data/store_repository.dart';
import '../theme/app_colors.dart';
import '../theme/clay_decoration.dart';
import '../widgets/app_dialog.dart';

/// Admin-only settings card for the PIN cashiers must enter to reprint a
/// receipt from the transaction history. Stored on the server, so one
/// change applies to every device.
class PrintPinTile extends StatelessWidget {
  const PrintPinTile({
    super.key,
    this.storeRepository = const StoreRepository(),
  });

  final StoreRepository storeRepository;

  Future<void> _openEditor(BuildContext context) async {
    final String? pin = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _PrintPinEditorDialog(),
    );
    if (pin == null) {
      return;
    }
    try {
      await storeRepository.setPrintPin(pin);
    } on ApiException catch (error) {
      if (context.mounted) {
        showAppDialog(
          context,
          title: AppStrings.printPinSettingsTitle,
          message: error.message,
        );
      }
      return;
    }
    if (context.mounted) {
      showAppDialog(
        context,
        title: AppStrings.printPinSettingsTitle,
        message: pin.isEmpty
            ? AppStrings.printPinRemoved
            : AppStrings.printPinSaved,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StoreInfo>(
      valueListenable: StoreRepository.store,
      builder: (BuildContext context, StoreInfo store, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.printPinSettingsTitle,
            style: TextStyle(
              fontSize: 14.4,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: ClayDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              onTap: () => _openEditor(context),
              leading: Icon(Icons.pin_outlined, color: AppColors.primary),
              title: Text(
                'PIN cetak ulang struk',
                style: TextStyle(
                  fontSize: 15.6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              subtitle: Text(
                store.hasPrintPin
                    ? AppStrings.printPinActive
                    : AppStrings.printPinInactive,
                style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintPinEditorDialog extends StatefulWidget {
  const _PrintPinEditorDialog();

  @override
  State<_PrintPinEditorDialog> createState() => _PrintPinEditorDialogState();
}

class _PrintPinEditorDialogState extends State<_PrintPinEditorDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String pin = _controller.text;
    if (pin.isNotEmpty && pin.length != 6) {
      setState(() => _errorText = AppStrings.printPinInvalid);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.printPinSettingsTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              AppStrings.printPinRule,
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(onPressed: _submit, child: const Text(AppStrings.save)),
      ],
    );
  }
}
