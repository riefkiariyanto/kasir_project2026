import 'finance_entry.dart';

class FinanceRepository {
  const FinanceRepository();

  static final List<FinanceEntry> _entries = <FinanceEntry>[];

  List<FinanceEntry> fetchAll() => List<FinanceEntry>.from(_entries.reversed);

  void add(FinanceEntry entry) {
    _entries.add(entry);
  }

  String nextId() {
    return 'FIN-${(_entries.length + 1).toString().padLeft(3, '0')}';
  }
}
