import '../../../core/data/api_client.dart';

class AuthRepository {
  const AuthRepository({this.api = const ApiClient()});

  final ApiClient api;

  Future<bool> login({required String username, required String password}) async {
    try {
      await api.post('/api/auth/login', <String, dynamic>{
        'username': username,
        'password': password,
      });
      return true;
    } on ApiException {
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await api.post('/api/auth/change-password', <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return true;
    } on ApiException {
      return false;
    }
  }
}
