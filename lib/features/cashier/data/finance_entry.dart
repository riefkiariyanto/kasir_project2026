enum FinanceType { loan, transfer }

class FinanceEntry {
  const FinanceEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String employeeId;
  final String employeeName;
  final FinanceType type;
  final int amount;
  final DateTime createdAt;

  factory FinanceEntry.fromJson(Map<String, dynamic> json) {
    return FinanceEntry(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String,
      type: (json['type'] as String) == 'loan'
          ? FinanceType.loan
          : FinanceType.transfer,
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
