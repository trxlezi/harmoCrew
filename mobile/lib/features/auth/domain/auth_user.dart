class AuthUser {
  const AuthUser({
    required this.name,
    required this.email,
    required this.password,
    this.userId,
    this.artistId,
  });

  final String name;
  final String email;
  final String password;
  final String? userId;
  final String? artistId;
}
