import 'package:flutter/material.dart';

import '../../features/cashier/data/order.dart';
import 'receipt_printer.dart';

/// Full-width "Cetak Struk" button that prints [order] to the saved
/// Bluetooth printer and shows the outcome right below itself. Used after
/// checkout and from transaction history, so both print the same way.
class PrintReceiptButton extends StatefulWidget {
  const PrintReceiptButton({
    super.key,
    required this.order,
    this.printer = const ReceiptPrinter(),
  });

  final Order order;
  final ReceiptPrinter printer;

  @override
  State<PrintReceiptButton> createState() => _PrintReceiptButtonState();
}

class _PrintReceiptButtonState extends State<PrintReceiptButton> {
  bool _isPrinting = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _print() async {
    setState(() {
      _isPrinting = true;
      _message = null;
    });

    try {
      await widget.printer.printReceipt(widget.order);
      _showResult('Struk berhasil dicetak.', isError: false);
    } on PrinterException catch (e) {
      _showResult(e.message, isError: true);
    } on Exception catch (e) {
      _showResult('Gagal mencetak struk: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _showResult(String message, {required bool isError}) {
    if (mounted) {
      setState(() {
        _message = message;
        _messageIsError = isError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? message = _message;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FilledButton.icon(
          onPressed: _isPrinting ? null : _print,
          icon: _isPrinting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.print_outlined, size: 18),
          label: const Text('Cetak Struk'),
        ),
        if (message != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _messageIsError ? Colors.red : Colors.green,
            ),
          ),
        ],
      ],
    );
  }
}
