import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';
import '../../data/employee.dart';
import '../../data/employee_repository.dart';
import '../../data/finance_entry.dart';

class FinanceActionDialog extends StatefulWidget {
  const FinanceActionDialog({
    super.key,
    required this.type,
    this.employeeRepository = const EmployeeRepository(),
  });

  final FinanceType type;
  final EmployeeRepository employeeRepository;

  static Future<({Employee employee, int amount})?> show(
    BuildContext context, {
    required FinanceType type,
    EmployeeRepository employeeRepository = const EmployeeRepository(),
  }) {
    return showDialog<({Employee employee, int amount})>(
      context: context,
      builder: (_) => FinanceActionDialog(
        type: type,
        employeeRepository: employeeRepository,
      ),
    );
  }

  @override
  State<FinanceActionDialog> createState() => _FinanceActionDialogState();
}

class _FinanceActionDialogState extends State<FinanceActionDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  String? _amountError;
  String? _pinError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final int amount = CurrencyFormatter.parseRupiah(_amountController.text);
    final String pin = _pinController.text.trim();

    bool hasError = false;

    if (amount <= 0) {
      setState(() => _amountError = AppStrings.financeAmountInvalid);
      hasError = true;
    } else {
      setState(() => _amountError = null);
    }

    if (pin.length != EmployeeRepository.pinLength) {
      setState(() => _pinError = AppStrings.verifyOrderPinHint);
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _pinError = null;
    });

    try {
      final Employee employee = await widget.employeeRepository.verifyPin(pin);
      if (mounted) {
        Navigator.of(context).pop((employee: employee, amount: amount));
      }
    } on ApiException {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _pinError = AppStrings.verifyOrderPinWrong;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoan = widget.type == FinanceType.loan;
    final String title = isLoan
        ? AppStrings.financeLoan
        : AppStrings.financeTransfer;
    final String subtitle = isLoan
        ? AppStrings.financeLoanHint
        : 'Diambil dari uang tunai kasir, dipindah ke QRIS';

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
              Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isLoan ? Colors.orange : AppColors.primary)
                          .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLoan ? Icons.money_off : Icons.swap_horiz,
                      size: 22,
                      color: isLoan ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.financeAmount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  RupiahInputFormatter(),
                ],
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  hintText: '0',
                  isDense: true,
                  errorText: _amountError,
                  filled: true,
                  fillColor: AppColors.panelSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                ),
                onChanged: (_) {
                  if (_amountError != null) {
                    setState(() => _amountError = null);
                  }
                },
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
              const SizedBox(height: 6),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: EmployeeRepository.pinLength,
                style: const TextStyle(fontSize: 22, letterSpacing: 12),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: AppStrings.verifyOrderPinHint,
                  hintStyle: const TextStyle(fontSize: 13, letterSpacing: 0),
                  isDense: true,
                  errorText: _pinError,
                  filled: true,
                  fillColor: AppColors.panelSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                ),
                onChanged: (_) {
                  if (_pinError != null) {
                    setState(() => _pinError = null);
                  }
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPanel,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPanel,
                              ),
                            )
                          : const Text(AppStrings.financeSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
