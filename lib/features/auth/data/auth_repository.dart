class AuthRepository {
  const AuthRepository();

  static const String _validUsername = 'admin';
  static String _password = 'admin';

  bool login({required String username, required String password}) {
    return username.trim() == _validUsername && password == _password;
  }

  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword != _password) {
      return false;
    }
    _password = newPassword;
    return true;
  }
}
