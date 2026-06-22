import '../../../core/api/api_session.dart';
import '../domain/auth_user.dart';
import 'auth_api_service.dart';

class AuthStore {
  AuthStore._();

  /*
   * Guarda o usuario logado em memoria para as telas acessarem nome, email,
   * userId e artistId. E uma solucao simples de gerenciamento de estado para a
   * entrega mobile.
   */
  static AuthUser? currentUser;

  static final AuthApiService _api = AuthApiService();

  static Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    // Chama a API, salva o token no ApiSession e guarda o usuario atual.
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
    // Logout limpa tanto a sessao local quanto o token invalidado no backend.
    if (ApiSession.isAuthenticated) {
      await _api.logout();
    }

    ApiSession.clear();
    currentUser = null;
  }
}
