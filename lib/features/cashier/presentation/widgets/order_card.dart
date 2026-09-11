import 'package:flutter/material.dart';

import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onDelete,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(16));

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '${time.day.toString().padLeft(2, '0')}/'
        '${time.month.toString().padLeft(2, '0')}/'
        '${time.year} $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: _radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface,
                AppColors.surface.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: _radius,
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _methodColor(order.method).withValues(alpha: 0.9),
                        _methodColor(order.method).withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _methodColor(order.method).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    order.method.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          order.id,
                          style: TextStyle(
                            fontSize: 16.4,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _methodColor(order.method)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.method.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _methodColor(order.method),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(order.createdAt)} · ${order.itemCount} item',
                      style: TextStyle(
                        fontSize: 13.6,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.cashierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.8,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    CurrencyFormatter.rupiah(order.total),
                    style: TextStyle(
                      fontSize: 16.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (onDelete != null)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            iconSize: 18,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                            onPressed: onDelete,
                            tooltip: 'Hapus Transaksi',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _methodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.qris:
        return Colors.blue;
    }
  }
}
