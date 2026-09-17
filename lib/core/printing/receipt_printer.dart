import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_assets.dart';
import '../data/store_repository.dart';
import '../utils/app_date_utils.dart';
import '../utils/currency_formatter.dart';
import '../../features/cashier/data/cart_item.dart';
import '../../features/cashier/data/order.dart';
import 'thermal_image.dart';

class PrinterException implements Exception {
  PrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum BluetoothPermission { granted, denied, permanentlyDenied }

/// A Bluetooth thermal printer the app can print receipts to.
class PrinterDevice {
  const PrinterDevice({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}

/// Prints order receipts to a paired 58mm Bluetooth thermal printer.
///
/// The chosen printer's MAC address is remembered on the device so the
/// cashier only picks it once.
class ReceiptPrinter {
  const ReceiptPrinter();

  static const String _savedPrinterKey = 'receipt_printer_mac';
  static const String _savedPrinterNameKey = 'receipt_printer_name';

  /// Logo width in printer dots: fits a 58mm head (384 dots) with margin.
  static const int _logoWidth = 320;
  static img.Image? _cachedLogo;

  /// Asks for the Android 12+ "Nearby devices" permissions if needed.
  ///
  /// Must succeed before any other call: print_bluetooth_thermal never
  /// requests them itself. Without CONNECT the plugin silently drops every
  /// call (the Dart future never completes); without SCAN its connect()
  /// fails, because it calls cancelDiscovery() before opening the socket.
  Future<BluetoothPermission> ensurePermission() async {
    final Map<Permission, PermissionStatus> statuses = await <Permission>[
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    if (statuses.values.every((PermissionStatus s) => s.isGranted)) {
      return BluetoothPermission.granted;
    }
    return statuses.values.any((PermissionStatus s) => s.isPermanentlyDenied)
        ? BluetoothPermission.permanentlyDenied
        : BluetoothPermission.denied;
  }

  /// Bluetooth must be on and [ensurePermission] granted before listing
  /// devices.
  Future<bool> isBluetoothEnabled() => PrintBluetoothThermal.bluetoothEnabled;

  /// Printers already paired in the phone's Bluetooth settings. Pairing
  /// itself happens in Android settings, not in the app.
  Future<List<PrinterDevice>> pairedPrinters() async {
    final List<BluetoothInfo> devices =
        await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map(
          (BluetoothInfo device) =>
              PrinterDevice(name: device.name, macAddress: device.macAdress),
        )
        .toList();
  }

  Future<PrinterDevice?> savedPrinter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mac = prefs.getString(_savedPrinterKey);
    if (mac == null || mac.isEmpty) {
      return null;
    }
    return PrinterDevice(
      name: prefs.getString(_savedPrinterNameKey) ?? mac,
      macAddress: mac,
    );
  }

  Future<void> savePrinter(PrinterDevice printer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPrinterKey, printer.macAddress);
    await prefs.setString(_savedPrinterNameKey, printer.name);
    // Drop any open socket so the next print connects to the new choice
    // instead of reusing a connection to the previously selected printer.
    await PrintBluetoothThermal.disconnect;
  }

  Future<void> forgetPrinter() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPrinterKey);
    await prefs.remove(_savedPrinterNameKey);
  }

  /// Prints [order]. Throws [PrinterException] with a message meant for the
  /// cashier when there's no printer set up or it can't be reached.
  Future<void> printReceipt(Order order) async {
    final PrinterDevice? printer = await savedPrinter();
    if (printer == null) {
      throw PrinterException(
        'Printer belum dipilih. Atur di Pengaturan > Printer Struk.',
      );
    }

    if (await ensurePermission() != BluetoothPermission.granted) {
      throw PrinterException(
        'Izin "Perangkat di sekitar" belum diberikan. '
        'Aktifkan di Pengaturan aplikasi.',
      );
    }

    if (!await isBluetoothEnabled()) {
      throw PrinterException('Bluetooth mati. Nyalakan dulu Bluetooth.');
    }

    bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.macAddress,
      );
    }
    if (!connected) {
      throw PrinterException(
        'Gagal terhubung ke printer "${printer.name}". '
        'Pastikan printer menyala dan dalam jangkauan.',
      );
    }

    final List<int> bytes = await _buildReceipt(order);
    final bool sent = await PrintBluetoothThermal.writeBytes(bytes);
    if (!sent) {
      throw PrinterException('Struk gagal dikirim ke printer.');
    }
  }

  Future<List<int>> _buildReceipt(Order order) async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final Generator generator = Generator(PaperSize.mm58, profile);
    final StoreInfo store = StoreRepository.data;

    List<int> bytes = <int>[];

    bytes += generator.imageRaster(await _logo(), align: PosAlign.center);
    bytes += generator.feed(1);
    if (store.address.isNotEmpty) {
      bytes += generator.text(
        store.address,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (store.phone.isNotEmpty) {
      bytes += generator.text(
        store.phone,
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr();
    bytes += _twoColumns(generator, 'No', order.invoiceNo);
    bytes += _twoColumns(
      generator,
      'Tanggal',
      AppDateUtils.formatDateTime(order.createdAt),
    );
    bytes += _twoColumns(generator, 'Kasir', order.cashierName);
    bytes += _twoColumns(generator, 'Bayar', order.method.label);
    bytes += generator.hr();

    for (final CartItem item in order.items) {
      bytes += generator.text(item.product.name);
      bytes += _twoColumns(
        generator,
        '${item.quantity} x ${CurrencyFormatter.rupiah(item.product.price)}',
        CurrencyFormatter.rupiah(item.subtotal),
      );
    }

    bytes += generator.hr();
    bytes += generator.row(<PosColumn>[
      PosColumn(text: 'TOTAL', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(
        text: CurrencyFormatter.rupiah(order.total),
        width: 7,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.hr();

    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima kasih',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'Sampai jumpa kembali',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<img.Image> _logo() async {
    final img.Image? cached = _cachedLogo;
    if (cached != null) {
      return cached;
    }
    final ByteData data = await rootBundle.load(AppAssets.logo);
    return _cachedLogo = toThermalImage(
      data.buffer.asUint8List(),
      width: _logoWidth,
    );
  }

  List<int> _twoColumns(Generator generator, String left, String right) {
    return generator.row(<PosColumn>[
      PosColumn(text: left, width: 5),
      PosColumn(
        text: right,
        width: 7,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
  }
}
