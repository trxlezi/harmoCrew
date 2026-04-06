import '../domain/auth_user.dart';

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

  static AuthUser? login({required String email, required String password}) {
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

  static bool register({
    required String name,
    required String email,
    required String password,
  }) {
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

  static void logout() {
    currentUser = null;
  }
}
