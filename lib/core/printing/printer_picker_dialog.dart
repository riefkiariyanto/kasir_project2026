import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'receipt_printer.dart';
import '../theme/app_colors.dart';

/// Lets the cashier pick which paired Bluetooth printer receipts go to.
/// Pairing itself is done in the phone's Bluetooth settings — this only
/// lists what's already paired.
class PrinterPickerDialog extends StatefulWidget {
  const PrinterPickerDialog({super.key, this.printer = const ReceiptPrinter()});

  final ReceiptPrinter printer;

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const PrinterPickerDialog(),
    );
  }

  @override
  State<PrinterPickerDialog> createState() => _PrinterPickerDialogState();
}

class _PrinterPickerDialogState extends State<PrinterPickerDialog> {
  List<PrinterDevice>? _devices;
  String? _error;
  String? _selectedMac;
  bool _needsAppSettings = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _devices = null;
      _error = null;
      _needsAppSettings = false;
    });
    try {
      final BluetoothPermission permission = await widget.printer
          .ensurePermission();
      if (permission != BluetoothPermission.granted) {
        if (mounted) {
          setState(() {
            _needsAppSettings =
                permission == BluetoothPermission.permanentlyDenied;
            _error = _needsAppSettings
                ? 'Izin "Perangkat di sekitar" ditolak. Buka Pengaturan '
                      'aplikasi, aktifkan izin tersebut, lalu tekan Muat Ulang.'
                : 'Izin "Perangkat di sekitar" diperlukan untuk menemukan '
                      'printer. Tekan Muat Ulang lalu pilih Izinkan.';
          });
        }
        return;
      }
      if (!await widget.printer.isBluetoothEnabled()) {
        if (mounted) {
          setState(() => _error = 'Bluetooth mati. Nyalakan dulu Bluetooth.');
        }
        return;
      }
      final List<PrinterDevice> devices = await widget.printer.pairedPrinters();
      final PrinterDevice? saved = await widget.printer.savedPrinter();
      if (mounted) {
        setState(() {
          _devices = devices;
          _selectedMac = saved?.macAddress;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _error = 'Tidak bisa membaca daftar printer: $e');
      }
    }
  }

  Future<void> _select(PrinterDevice device) async {
    await widget.printer.savePrinter(device);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pilih Printer Struk'),
      content: SizedBox(width: 340, child: _buildContent()),
      actions: <Widget>[
        if (_needsAppSettings)
          TextButton(
            onPressed: openAppSettings,
            child: const Text('Buka Pengaturan'),
          ),
        TextButton(onPressed: _load, child: const Text('Muat Ulang')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final String? error = _error;
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(error, style: TextStyle(color: AppColors.onSurface)),
      );
    }

    final List<PrinterDevice>? devices = _devices;
    if (devices == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Belum ada printer yang dipasangkan. Pasangkan printer lewat '
          'Pengaturan Bluetooth HP, lalu tekan Muat Ulang.',
          style: TextStyle(color: AppColors.onSurfaceMuted),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: devices.length,
      separatorBuilder: (BuildContext context, int index) =>
          Divider(height: 1, color: AppColors.divider),
      itemBuilder: (BuildContext context, int index) {
        final PrinterDevice device = devices[index];
        final bool isSelected = device.macAddress == _selectedMac;

        return ListTile(
          onTap: () => _select(device),
          leading: Icon(
            Icons.print_outlined,
            color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
          ),
          title: Text(
            device.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: Text(
            device.macAddress,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: AppColors.primary)
              : null,
        );
      },
    );
  }
}
