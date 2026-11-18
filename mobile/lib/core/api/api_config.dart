class ApiConfig {
  const ApiConfig._();

  /*
   * API_BASE_URL permite trocar o endereco da API sem recompilar codigo.
   *
   * No emulador Android, localhost aponta para o proprio emulador. Por isso
   * usamos 10.0.2.2, que e o alias do host Windows onde o Docker esta rodando.
   *
   * Exemplo:
   * flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
   */
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
