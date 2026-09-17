import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/printing/printer_settings_tile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_title.dart';

/// Cashier-side settings. Deliberately limited to connecting the receipt
/// printer — store data, categories and passwords stay admin-only.
class CashierSettingsPage extends StatelessWidget {
  const CashierSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppColors.darkNotifier,
      builder: (BuildContext context, bool isDark, _) => Scaffold(
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
          title: BrandTitle(text: AppStrings.adminSettings),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: PrinterSettingsTile(),
            ),
          ),
        ),
      ),
    );
  }
}
