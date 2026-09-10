import 'package:flutter/material.dart';

enum PaymentMethod {
  qris('QRIS', Icons.qr_code_2_outlined),
  cash('Tunai', Icons.payments_outlined);

  const PaymentMethod(this.label, this.icon);

  final String label;
  final IconData icon;
}
