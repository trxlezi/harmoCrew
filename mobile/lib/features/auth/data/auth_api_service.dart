import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../domain/auth_user.dart';

class AuthApiService {
  /*
   * Service de autenticacao do mobile.
   *
   * Ele traduz as acoes da tela de login/cadastro para chamadas HTTP reais:
   * POST /auth/register, POST /auth/login e POST /auth/logout.
   */
  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    /*
     * O mobile envia stageName e mainSpecialty junto do cadastro.
     * Isso faz o backend criar User e Artist na mesma transacao, permitindo que
     * a resposta ja volte com artistId para mensagens e candidaturas.
     */
    final response = await _client.post(
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'stageName': name.trim(),
        'mainSpecialty': 'Artista',
      },
    );

    return _saveSession(response, password);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    // Login recebe token/userId/artistId do backend quando as credenciais batem.
    final response = await _client.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password.trim()},
    );

    return _saveSession(response, password);
  }

  Future<void> logout() async {
    /*
     * Se existe token, avisamos o backend para invalidar esse JWT.
     * Depois limpamos a sessao local para o ApiClient parar de enviar Bearer.
     */
    if (ApiSession.isAuthenticated) {
      await _client.post('/auth/logout');
    }
    ApiSession.clear();
  }

  AuthUser _saveSession(dynamic response, String password) {
    /*
     * AuthResponse esperado do backend:
     * token, userId, artistId, name, email e role.
     *
     * artistId e muito importante: identifica o Artist vinculado ao usuario.
     * Sem isso o app poderia associar mensagem/candidatura ao artista errado.
     */
    final data = response as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token != null && token.isNotEmpty) {
      ApiSession.saveToken(token);
    }

    return AuthUser(
      name: (data['name'] ?? data['userName'] ?? data['email'] ?? 'Usuario')
          .toString(),
      email: (data['email'] ?? '').toString(),
      password: password,
      userId: data['userId']?.toString(),
      artistId: data['artistId']?.toString(),
    );
  }
}
