import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/clay_decoration.dart';
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

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(20));

  /// Room kept clear at the bottom for the app's floating nav pill.
  static const double _navClearance = 72;

  /// Below this height the header, payment choice, total and checkout
  /// button leave no room for the item list (a portrait phone/tablet gives
  /// the cart only a third of the screen), so the whole panel scrolls as
  /// one column instead of squeezing the list to nothing.
  static const double _minHeightForPinnedFooter = 520;

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
      decoration: ClayDecoration(
        color: AppColors.surface,
        borderRadius: _radius,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxHeight < _minHeightForPinnedFooter) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: _navClearance),
              child: Column(
                children: <Widget>[
                  _buildHeader(),
                  _buildMethodSelector(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: _EmptyCart(),
                          )
                        : _buildItemList(scrollable: false),
                  ),
                  _buildFooter(bottomPadding: 16),
                ],
              ),
            );
          }

          return Column(
            children: <Widget>[
              _buildHeader(),
              _buildMethodSelector(),
              // Only the item list scrolls; the total and checkout button
              // keep their normal place at the bottom of the panel.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: items.isEmpty
                      ? const _EmptyCart()
                      : _buildItemList(scrollable: true),
                ),
              ),
              _buildFooter(bottomPadding: _navClearance),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                fontSize: 16.5,
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
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: PaymentMethodSelector(
        selected: selectedMethod,
        onSelected: onMethodSelected,
      ),
    );
  }

  Widget _buildItemList({required bool scrollable}) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: !scrollable,
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
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
    );
  }

  Widget _buildFooter({required double bottomPadding}) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                AppStrings.cartTotal,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              Flexible(
                child: Text(
                  CurrencyFormatter.rupiah(total),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: items.isEmpty || selectedMethod == null
                  ? null
                  : onCheckout,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.panelSurface,
                disabledForegroundColor: AppColors.onSurfaceMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                AppStrings.cartCheckout,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
              ),
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
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.cartEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
