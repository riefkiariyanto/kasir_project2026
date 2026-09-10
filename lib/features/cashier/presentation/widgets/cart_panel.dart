import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/cart_item.dart';
import 'cart_item_tile.dart';
import 'payment_method_selector.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    required this.items,
    required this.total,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.selectedMethod,
    required this.onMethodSelected,
    required this.onCheckout,
  });

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(12));

  final List<CartItem> items;
  final int total;
  final ValueChanged<CartItem> onIncrement;
  final ValueChanged<CartItem> onDecrement;
  final ValueChanged<CartItem> onRemove;
  final PaymentMethod? selectedMethod;
  final ValueChanged<PaymentMethod> onMethodSelected;
  final VoidCallback onCheckout;

  int get _itemCount =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: _radius,
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    AppStrings.cartTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                if (_itemCount > 0) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    '($_itemCount)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: PaymentMethodSelector(
              selected: selectedMethod,
              onSelected: onMethodSelected,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: items.isEmpty
                  ? const _EmptyCart()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (BuildContext context, int index) {
                        final CartItem item = items[index];

                        return CartItemTile(
                          item: item,
                          onIncrement: () => onIncrement(item),
                          onDecrement: () => onDecrement(item),
                          onRemove: () => onRemove(item),
                        );
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      AppStrings.cartTotal,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        CurrencyFormatter.rupiah(total),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: items.isEmpty || selectedMethod == null
                        ? null
                        : onCheckout,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPanel,
                      disabledBackgroundColor: AppColors.panelSurface,
                      disabledForegroundColor: AppColors.onSurfaceMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      AppStrings.cartCheckout,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.shopping_bag_outlined,
            size: 32,
            color: AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.cartEmpty,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cartEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
