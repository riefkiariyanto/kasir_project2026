import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/order.dart';
import 'order_card.dart';
import 'order_detail_dialog.dart';

class OrdersList extends StatelessWidget {
  const OrdersList({
    super.key,
    required this.orders,
    this.maxContentWidth = 1080,
  });

  final List<Order> orders;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: orders.isEmpty
            ? const _OrdersEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                itemCount: orders.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  final Order order = orders[index];

                  return OrderCard(
                    order: order,
                    onTap: () => OrderDetailDialog.show(context, order: order),
                  );
                },
              ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            AppStrings.ordersEmpty,
            style: TextStyle(fontSize: 16.8, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.ordersEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.4, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
