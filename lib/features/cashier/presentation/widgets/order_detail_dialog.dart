import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/cart_item.dart';
import '../../data/order.dart';

class OrderDetailDialog extends StatelessWidget {
  const OrderDetailDialog({super.key, required this.order});

  final Order order;

  static Future<void> show(BuildContext context, {required Order order}) {
    return showDialog<void>(
      context: context,
      builder: (_) => OrderDetailDialog(order: order),
    );
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                AppStrings.orderDetailTitle,
                style: TextStyle(fontSize: 20.4, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                order.id,
                style: TextStyle(
                  fontSize: 14.4,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      for (final CartItem item in order.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${item.product.name} x${item.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15.6),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.rupiah(item.subtotal),
                                style: const TextStyle(
                                  fontSize: 15.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Divider(height: 24, color: AppColors.divider),
              _DetailRow(
                label: AppStrings.orderDetailTime,
                value: _formatTime(order.createdAt),
              ),
              const SizedBox(height: 6),
              _DetailRow(
                label: AppStrings.orderDetailMethod,
                value: order.method.label,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                label: AppStrings.orderDetailCashier,
                value: order.cashierName,
              ),
              const SizedBox(height: 6),
              _DetailRow(
                label: AppStrings.cartTotal,
                value: CurrencyFormatter.rupiah(order.total),
                valueColor: AppColors.primary,
                valueWeight: FontWeight.bold,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(AppStrings.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 14.4, color: AppColors.onSurfaceMuted),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.6,
            fontWeight: valueWeight ?? FontWeight.w600,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
