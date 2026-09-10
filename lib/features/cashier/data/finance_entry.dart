enum FinanceType { loan, transfer }

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.employeeName,
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String employeeName;
  final FinanceType type;
  final int amount;
  final DateTime createdAt;
}
