import '../../../core/data/api_client.dart';
import 'finance_entry.dart';

class FinanceRepository {
  const FinanceRepository({this.api = const ApiClient()});

  final ApiClient api;

  Future<List<FinanceEntry>> fetchAll() async {
    final List<dynamic> data = await api.get('/api/finance') as List<dynamic>;
    return data
        .map((dynamic e) => FinanceEntry.fromJson(e as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<FinanceEntry> add({
    required String employeeId,
    required String employeeName,
    required FinanceType type,
    required int amount,
  }) async {
    final dynamic data = await api.post('/api/finance', <String, dynamic>{
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type == FinanceType.loan ? 'loan' : 'transfer',
      'amount': amount,
    });
    return FinanceEntry.fromJson(data as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await api.delete('/api/finance/$id');
  }
}
