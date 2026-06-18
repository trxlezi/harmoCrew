class ApiSession {
  ApiSession._();

  static String? token;

  static bool get isAuthenticated => token != null && token!.isNotEmpty;

  static void saveToken(String value) {
    token = value;
  }

  static void clear() {
    token = null;
  }
}
