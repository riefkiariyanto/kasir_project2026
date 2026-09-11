import 'package:flutter/material.dart';

import '../../../../core/models/payment_method.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final PaymentMethod method in PaymentMethod.values) ...<Widget>[
          Expanded(
            child: _MethodButton(
              method: method,
              selected: selected == method,
              onTap: () => onSelected(method),
            ),
          ),
          if (method != PaymentMethod.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(8);

    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                method.icon,
                size: 16.5,
                color: selected ? AppColors.onPanel : AppColors.onSurfaceMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  method.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.onPanel : AppColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
