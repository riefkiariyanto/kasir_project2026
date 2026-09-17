import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/data/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_utils.dart';
import '../../../cashier/data/order_repository.dart';

/// Deletes all orders in a picked date range after the admin re-enters
/// their password. Pops with the number of orders deleted.
class BulkDeleteOrdersDialog extends StatefulWidget {
  const BulkDeleteOrdersDialog({
    super.key,
    this.orderRepository = const OrderRepository(),
  });

  final OrderRepository orderRepository;

  @override
  State<BulkDeleteOrdersDialog> createState() => _BulkDeleteOrdersDialogState();
}

class _BulkDeleteOrdersDialogState extends State<BulkDeleteOrdersDialog> {
  final TextEditingController _password = TextEditingController();
  DateTimeRange? _range;
  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _range = picked);
    }
  }

  Future<void> _submit() async {
    final DateTimeRange? range = _range;
    if (range == null || _password.text.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final int deleted = await widget.orderRepository.removeRange(
        from: range.start,
        // The picked end day is inclusive.
        to: DateUtils.addDaysToDate(range.end, 1),
        password: _password.text,
      );
      if (mounted) {
        Navigator.of(context).pop(deleted);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTimeRange? range = _range;
    return AlertDialog(
      title: const Text(AppStrings.bulkDeleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              AppStrings.bulkDeleteHint,
              style: TextStyle(color: AppColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _pickRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                range == null
                    ? AppStrings.bulkDeletePickRange
                    : '${AppDateUtils.formatDate(range.start)} – '
                          '${AppDateUtils.formatDate(range.end)}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_isLoading,
              onChanged: (_) => setState(() => _errorText = null),
              decoration: InputDecoration(
                labelText: AppStrings.bulkDeletePasswordLabel,
                errorText: _errorText,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _isLoading || range == null || _password.text.isEmpty
              ? null
              : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.bulkDeleteConfirm),
        ),
      ],
    );
  }
}
