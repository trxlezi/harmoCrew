import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_session.dart';

class ApiClient {
  /*
   * Cliente HTTP central do app.
   *
   * Todas as chamadas REST passam por aqui para evitar repeticao de headers,
   * baseUrl, tratamento de erro e token JWT. Na apresentacao, este arquivo e o
   * melhor ponto para explicar a integracao Flutter -> API Spring Boot.
   */
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), '');

  final http.Client _httpClient;
  final String _baseUrl;

  Future<dynamic> get(String path) {
    return _send('GET', path);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _send('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) {
    return _send('PATCH', path, body: body);
  }

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  /// URL absoluta para links da API (ex.: /media/{chave} de audios e PDFs).
  String absoluteUrl(String path) =>
      path.startsWith('http') ? path : '$_baseUrl$path';

  /// Upload multipart (campo "file") usado por arquivos versionados e audio
  /// do perfil. [fields] vira campos de formulario simples.
  Future<dynamic> upload(
    String path, {
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    request.headers['Accept'] = 'application/json';
    if (ApiSession.isAuthenticated) {
      request.headers['Authorization'] = 'Bearer ${ApiSession.token}';
    }

    late http.Response response;
    try {
      response = await http.Response.fromStream(
        await _httpClient.send(request),
      );
    } catch (_) {
      throw const ApiException('Nao foi possivel conectar com a API.');
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractMessage(decoded) ?? 'Erro ao enviar arquivo.',
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }

  /// Abre um stream Server-Sent Events e devolve cada evento como
  /// (nome, dados JSON). Usado pelos alertas em tempo real.
  Stream<({String event, dynamic data})> events(String path) async* {
    final request = http.Request('GET', Uri.parse('$_baseUrl$path'));
    request.headers['Accept'] = 'text/event-stream';
    if (ApiSession.isAuthenticated) {
      request.headers['Authorization'] = 'Bearer ${ApiSession.token}';
    }
    final response = await _httpClient.send(request);
    if (response.statusCode != 200) {
      throw ApiException(
        'Falha ao abrir canal de alertas.',
        statusCode: response.statusCode,
      );
    }
    var event = 'message';
    final data = StringBuffer();
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          final raw = data.toString();
          dynamic parsed;
          try {
            parsed = jsonDecode(raw);
          } catch (_) {
            parsed = raw;
          }
          yield (event: event, data: parsed);
        }
        event = 'message';
        data.clear();
      } else if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        if (data.isNotEmpty) {
          data.writeln();
        }
        data.write(line.substring(5).trimLeft());
      }
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    /*
     * Monta a URL final juntando API_BASE_URL com o path do endpoint.
     * Exemplo no emulador Android:
     * baseUrl = http://10.0.2.2:8080
     * path = /api/projects
     */
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      /*
       * Se houver token salvo no ApiSession, todas as chamadas protegidas
       * recebem Authorization: Bearer <token>, exatamente como o backend espera.
       */
      if (ApiSession.isAuthenticated)
        'Authorization': 'Bearer ${ApiSession.token}',
    };

    late http.Response response;
    try {
      // O switch escolhe o verbo HTTP correto: GET, POST, PUT, PATCH ou DELETE.
      response = await switch (method) {
        'GET' => _httpClient.get(uri, headers: headers),
        'POST' => _httpClient.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'PUT' => _httpClient.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'PATCH' => _httpClient.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'DELETE' => _httpClient.delete(uri, headers: headers),
        _ => throw ApiException('Metodo HTTP nao suportado: $method'),
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      // Erros de rede, backend fora do ar ou URL errada caem aqui.
      throw const ApiException('Nao foi possivel conectar com a API.');
    }

    if (response.statusCode == 204) {
      // 204 No Content e sucesso sem corpo, comum em DELETE.
      return null;
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // A API pode devolver "message" ou "error"; o app mostra isso ao usuario.
      throw ApiException(
        _extractMessage(decoded) ?? 'Erro ao chamar a API.',
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return null;
  }
}
