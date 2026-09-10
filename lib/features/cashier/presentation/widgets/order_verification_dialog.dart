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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: ListenableBuilder(
            listenable: widget.cart,
            builder: (BuildContext context, _) {
              final List<CartItem> items = widget.cart.items;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    AppStrings.verifyOrderTitle,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.verifyOrderItems,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
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
                  Divider(height: 24, color: AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        AppStrings.cartTotal,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.rupiah(widget.cart.total),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Icon(
                        widget.method.icon,
                        size: 16,
                        color: AppColors.onSurfaceMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.method.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    AppStrings.verifyOrderPinLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
