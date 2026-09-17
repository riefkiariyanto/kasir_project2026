import 'package:flutter/material.dart';

import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.onDelete,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(24));

  /// Narrower than this (grid cells, small phones) the single-row layout
  /// can't fit the invoice, method badge and total side by side, so the
  /// total and actions move to a second row.
  static const double _compactBelowWidth = 420;

  final Order order;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
          decoration: ClayDecoration(borderRadius: _radius),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                constraints.maxWidth < _compactBelowWidth
                ? _buildCompact()
                : _buildWide(),
          ),
        ),
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      children: <Widget>[
        _buildMethodIcon(size: 48),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTitleRow(),
              const SizedBox(height: 4),
              _buildTimeText(),
              const SizedBox(height: 2),
              _buildCashierText(),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildTotalText(),
            const SizedBox(height: 8),
            _buildActions(),
          ],
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          children: <Widget>[
            _buildMethodIcon(size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildTitleRow(),
                  const SizedBox(height: 4),
                  _buildTimeText(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _buildCashierText()),
            const SizedBox(width: 8),
            // Scale a long total down rather than truncating an amount.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _buildTotalText(),
              ),
            ),
            const SizedBox(width: 8),
            _buildActions(),
          ],
        ),
      ],
    );
  }

  Widget _buildMethodIcon({required double size}) {
    final Color color = _methodColor(order.method);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(order.method.icon, color: color, size: size * 0.46),
    );
  }

  Widget _buildTitleRow() {
    final Color color = _methodColor(order.method);
    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            order.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.4,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.method.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeText() {
    return Text(
      '${AppDateUtils.formatDateTime(order.createdAt)} · ${order.itemCount} item',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13.6, color: AppColors.onSurfaceMuted),
    );
  }

  Widget _buildCashierText() {
    return Text(
      order.cashierName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12.8, color: AppColors.onSurfaceMuted),
    );
  }

  Widget _buildTotalText() {
    return Text(
      CurrencyFormatter.rupiah(order.total),
      maxLines: 1,
      style: TextStyle(
        fontSize: 16.4,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (onDelete != null) ...<Widget>[
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
        ],
        Icon(
          Icons.chevron_right_rounded,
          color: AppColors.onSurfaceMuted.withValues(alpha: 0.6),
          size: 22,
        ),
      ],
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
