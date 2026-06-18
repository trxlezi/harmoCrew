import '../../../core/api/api_config.dart';
import '../../../core/api/api_session.dart';
import '../domain/auth_user.dart';
import 'auth_api_service.dart';

class MockAuthStore {
  MockAuthStore._();

  static final List<AuthUser> _users = [
    const AuthUser(
      name: 'Marina Costa',
      email: 'marina@harmocrew.app',
      password: '123456',
    ),
  ];

  static AuthUser? currentUser;

  static final AuthApiService _api = AuthApiService();

  static Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    if (!ApiConfig.useMocks) {
      final user = await _api.login(email: email, password: password);
      currentUser = user;
      return user;
    }

    try {
      final user = _users.firstWhere(
        (user) =>
            user.email == email.trim() && user.password == password.trim(),
      );
      currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!ApiConfig.useMocks) {
      currentUser = await _api.register(
        name: name,
        email: email,
        password: password,
      );
      return true;
    }

    final normalizedEmail = email.trim().toLowerCase();
    final alreadyExists = _users.any(
      (user) => user.email.toLowerCase() == normalizedEmail,
    );

    if (alreadyExists) {
      return false;
    }

    _users.add(
      AuthUser(
        name: name.trim(),
        email: normalizedEmail,
        password: password.trim(),
      ),
    );
    return true;
  }

  static Future<void> logout() async {
    if (!ApiConfig.useMocks && ApiSession.isAuthenticated) {
      await _api.logout();
    }

    ApiSession.clear();
    currentUser = null;
  }
}
