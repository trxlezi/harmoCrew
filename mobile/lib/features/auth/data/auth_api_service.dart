import '../../../core/api/api_client.dart';
import '../../../core/api/api_session.dart';
import '../domain/auth_user.dart';

class AuthApiService {
  AuthApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
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
    final response = await _client.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password.trim()},
    );

    return _saveSession(response, password);
  }

  Future<void> logout() async {
    if (ApiSession.isAuthenticated) {
      await _client.post('/auth/logout');
    }
    ApiSession.clear();
  }

  AuthUser _saveSession(dynamic response, String password) {
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
