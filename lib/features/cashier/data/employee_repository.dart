import '../../../core/data/api_client.dart';
import 'employee.dart';

class EmployeeRepository {
  const EmployeeRepository({this.api = const ApiClient()});

  final ApiClient api;

  static const int pinLength = 6;

  Future<List<Employee>> fetchAll() async {
    final List<dynamic> data = await api.get('/api/employees') as List<dynamic>;
    return data.map((dynamic e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Public, id+name only — dipakai konteks kasir yang belum login admin (mis. filter pegawai di Riwayat Transaksi).
  Future<List<Employee>> fetchNames() async {
    final List<dynamic> data = await api.get('/api/employees/names') as List<dynamic>;
    return data.map((dynamic e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Employee> verifyPin(String pin) async {
    final dynamic data = await api.post('/api/employees/verify-pin', <String, dynamic>{
      'pin': pin,
    });
    return Employee.fromJson(data as Map<String, dynamic>);
  }

  Future<void> add({required String name, String? phone, required String pin}) async {
    await api.post('/api/employees', <String, dynamic>{
      'name': name,
      'phone': phone,
      'pin': pin,
    });
  }

  Future<void> update({
    required String id,
    required String name,
    String? phone,
    String? pin,
  }) async {
    await api.put('/api/employees/$id', <String, dynamic>{
      'name': name,
      'phone': phone,
      if (pin != null) 'pin': pin,
    });
  }

  Future<void> delete(String id) async {
    await api.delete('/api/employees/$id');
  }
}
