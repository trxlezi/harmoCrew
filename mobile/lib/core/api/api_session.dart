class ApiSession {
  ApiSession._();

  /*
   * Sessao simples em memoria.
   *
   * Depois do login/cadastro, AuthApiService salva aqui o JWT recebido.
   * ApiClient consulta este token e envia no header Authorization.
   *
   * Como esta sessao e em memoria, fechar o app limpa o token. Isso e simples
   * para a entrega academica; em producao, poderia ser salvo com secure storage.
   */
  static String? token;

  static bool get isAuthenticated => token != null && token!.isNotEmpty;

  static void saveToken(String value) {
    token = value;
  }

  static void clear() {
    token = null;
  }
}
