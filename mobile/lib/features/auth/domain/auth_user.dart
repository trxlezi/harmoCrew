class AuthUser {
  /*
   * Representa a sessao do usuario no app.
   *
   * userId vem da tabela users do backend.
   * artistId vem da tabela artists e e usado quando o app precisa criar algo em
   * nome do artista logado, como mensagem ou candidatura.
   */
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
