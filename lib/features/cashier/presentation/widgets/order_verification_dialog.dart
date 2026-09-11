import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/cart_controller.dart';
import '../../data/cart_item.dart';
import '../../data/employee.dart';
import '../../data/employee_repository.dart';
import 'cart_item_tile.dart';

class OrderVerificationDialog extends StatefulWidget {
  const OrderVerificationDialog({
    super.key,
    required this.cart,
    required this.method,
    this.employeeRepository = const EmployeeRepository(),
  });

  final CartController cart;
  final PaymentMethod method;
  final EmployeeRepository employeeRepository;

  static Future<Employee?> show(
    BuildContext context, {
    required CartController cart,
    required PaymentMethod method,
  }) {
    return showDialog<Employee>(
      context: context,
      builder: (_) => OrderVerificationDialog(cart: cart, method: method),
    );
  }

  @override
  State<OrderVerificationDialog> createState() =>
      _OrderVerificationDialogState();
}

class _OrderVerificationDialogState extends State<OrderVerificationDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (widget.cart.items.isEmpty) {
      return;
    }

    final String pin = _pinController.text;

    if (pin.length != EmployeeRepository.pinLength) {
      setState(() => _errorText = AppStrings.verifyOrderPinHint);
      return;
    }

    final Employee? employee = widget.employeeRepository.findByPin(pin);
    if (employee == null) {
      setState(() => _errorText = AppStrings.verifyOrderPinWrong);
      return;
    }

    Navigator.of(context).pop(employee);
  }

  Color _methodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Colors.green;
      case PaymentMethod.qris:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color methodColor = _methodColor(widget.method);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: ListenableBuilder(
            listenable: widget.cart,
            builder: (BuildContext context, _) {
              final List<CartItem> items = widget.cart.items;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              methodColor.withValues(alpha: 0.9),
                              methodColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.method.icon,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AppStrings.verifyOrderTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AppStrings.verifyOrderItems,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: methodColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.method.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: methodColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              AppStrings.cartEmpty,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.onSurfaceMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: items.length,
                            separatorBuilder:
                                (BuildContext context, int index) => Divider(
                                  height: 1,
                                  color: AppColors.divider,
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final CartItem item = items[index];

                              return CartItemTile(
                                item: item,
                                onIncrement: () =>
                                    widget.cart.increment(item.product),
                                onDecrement: () =>
                                    widget.cart.decrement(item.product),
                                onRemove: () =>
                                    widget.cart.remove(item.product),
                              );
                            },
                          ),
                  ),
                  _DashedDivider(color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        AppStrings.cartTotal,
                        style: TextStyle(
                          fontSize: 15.6,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.rupiah(widget.cart.total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.verifyOrderPinLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: EmployeeRepository.pinLength,
                    style: const TextStyle(fontSize: 22, letterSpacing: 12),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      if (_errorText != null) {
                        setState(() => _errorText = null);
                      }
                    },
                    onSubmitted: (_) => _confirm(),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: AppStrings.verifyOrderPinHint,
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        letterSpacing: 0,
                      ),
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(AppStrings.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: items.isEmpty ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPanel,
                            disabledBackgroundColor: AppColors.panelSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(AppStrings.verifyOrderConfirm),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < 60; i++)
            Expanded(
              child: Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}