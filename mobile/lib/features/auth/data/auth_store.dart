import '../../../core/api/api_session.dart';
import '../domain/auth_user.dart';
import 'auth_api_service.dart';

class AuthStore {
  AuthStore._();

  static AuthUser? currentUser;

  static final AuthApiService _api = AuthApiService();

  static Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    final user = await _api.login(email: email, password: password);
    currentUser = user;
    return user;
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    currentUser = await _api.register(
      name: name,
      email: email,
      password: password,
    );
    return true;
  }

  static Future<void> logout() async {
    if (ApiSession.isAuthenticated) {
      await _api.logout();
    }

    ApiSession.clear();
    currentUser = null;
  }
}
