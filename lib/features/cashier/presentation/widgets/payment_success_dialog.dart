import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/printing/print_receipt_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/order.dart';

/// Shown after a successful checkout. Prints the receipt to the paired
/// Bluetooth thermal printer right away, with a button to reprint.
class PaymentSuccessDialog extends StatelessWidget {
  const PaymentSuccessDialog({super.key, required this.order});

  final Order order;

  static Future<void> show(BuildContext context, {required Order order}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentSuccessDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
      title: const Text(AppStrings.paymentSuccess),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            CurrencyFormatter.rupiah(order.total),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.invoiceNo} · ${order.method.label}',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 16),
          PrintReceiptButton(order: order, autoPrint: true),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
