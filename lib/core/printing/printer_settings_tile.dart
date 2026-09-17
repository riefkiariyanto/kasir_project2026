import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/clay_decoration.dart';
import 'printer_picker_dialog.dart';
import 'receipt_printer.dart';

/// "Printer Struk" settings card: shows the currently chosen Bluetooth
/// printer and opens the picker to change it. Shared by the admin and
/// cashier settings pages.
class PrinterSettingsTile extends StatefulWidget {
  const PrinterSettingsTile({super.key, this.printer = const ReceiptPrinter()});

  final ReceiptPrinter printer;

  @override
  State<PrinterSettingsTile> createState() => _PrinterSettingsTileState();
}

class _PrinterSettingsTileState extends State<PrinterSettingsTile> {
  String? _printerName;

  @override
  void initState() {
    super.initState();
    _loadPrinter();
  }

  Future<void> _loadPrinter() async {
    final PrinterDevice? printer = await widget.printer.savedPrinter();
    if (mounted) {
      setState(() => _printerName = printer?.name);
    }
  }

  Future<void> _openPicker() async {
    final bool? changed = await PrinterPickerDialog.show(context);
    if (changed == true) {
      await _loadPrinter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Printer Struk',
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
            onTap: _openPicker,
            leading: Icon(Icons.print_outlined, color: AppColors.primary),
            title: Text(
              'Printer Bluetooth',
              style: TextStyle(
                fontSize: 15.6,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            subtitle: Text(
              _printerName ?? 'Belum dipilih',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
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
