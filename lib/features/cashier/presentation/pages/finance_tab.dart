import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pull_to_refresh.dart';
import '../../../../core/theme/clay_decoration.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/finance_entry.dart';
import '../../data/finance_repository.dart';
import '../widgets/finance_action_dialog.dart';

class FinanceTab extends StatefulWidget {
  const FinanceTab({
    super.key,
    this.financeRepository = const FinanceRepository(),
  });

  final FinanceRepository financeRepository;

  @override
  State<FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<FinanceTab> {
  List<FinanceEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<FinanceEntry> entries = await widget.financeRepository
        .fetchAll();
    if (mounted) {
      setState(() => _entries = entries);
    }
  }

  Future<void> _openAction(FinanceType type) async {
    final result = await FinanceActionDialog.show(context, type: type);
    if (result != null && mounted) {
      await widget.financeRepository.add(
        employeeId: result.employee.id,
        employeeName: result.employee.name,
        type: type,
        amount: result.amount,
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<FinanceEntry> entries = _entries ?? const <FinanceEntry>[];

    if (_entries == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: PullToRefresh(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: <Widget>[
              Text(
                AppStrings.financeHeader,
                style: TextStyle(
                  fontSize: 19.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openAction(FinanceType.loan),
                      icon: const Icon(Icons.money_off_outlined),
                      label: const Text(AppStrings.financeLoan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openAction(FinanceType.transfer),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text(AppStrings.financeTransfer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Riwayat Kas Pegawai',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: ClayDecoration(
                    sunken: true,
                    color: AppColors.panelSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppStrings.financeEmpty,
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                )
              else
                for (final FinanceEntry entry in entries)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: ClayDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: entry.type == FinanceType.loan
                                ? Colors.orange.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            entry.type == FinanceType.loan
                                ? Icons.money_off
                                : Icons.swap_horiz,
                            size: 18,
                            color: entry.type == FinanceType.loan
                                ? Colors.orange
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.employeeName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.type == FinanceType.loan
                                    ? AppStrings.financeLoanOf
                                    : AppStrings.financeTransferOf,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.rupiah(entry.amount),
                          style: TextStyle(
                            fontSize: 15.6,
                            fontWeight: FontWeight.bold,
                            color: entry.type == FinanceType.loan
                                ? Colors.orange
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
