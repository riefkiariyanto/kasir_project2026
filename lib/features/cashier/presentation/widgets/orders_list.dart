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
    this.isGrid = false,
    this.onDelete,
  });

  const OrdersList.grid({
    super.key,
    required this.orders,
    this.maxContentWidth = 1080,
    this.isGrid = true,
    this.onDelete,
  });

  final List<Order> orders;
  final double maxContentWidth;
  final bool isGrid;
  final ValueChanged<Order>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: orders.isEmpty
            ? const _OrdersEmptyState()
            : isGrid
            ? GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                itemCount: orders.length,
                // Fixed cell height: an aspect ratio shrinks the height
                // along with narrow columns and clips the card's content.
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 380,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 140,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final Order order = orders[index];
                  return OrderCard(
                    order: order,
                    onTap: () => OrderDetailDialog.show(context, order: order),
                    onDelete: onDelete != null ? () => onDelete!(order) : null,
                  );
                },
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                itemCount: orders.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final Order order = orders[index];
                  return OrderCard(
                    order: order,
                    onTap: () => OrderDetailDialog.show(context, order: order),
                    onDelete: onDelete != null ? () => onDelete!(order) : null,
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
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.ordersEmpty,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.ordersEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
