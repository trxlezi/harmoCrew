import '../../../core/api/api_client.dart';
import '../models/collaboration_message.dart';

class MessageApiService {
  /*
   * Service das mensagens no mobile.
   *
   * Ele chama os endpoints:
   * - GET /api/messages
   * - GET /api/projects/{id}/messages
   * - POST /api/projects/{id}/messages
   */
  MessageApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<CollaborationMessage>> listMessages({String? projectId}) async {
    // Se projectId vier nulo, lista geral; se vier preenchido, filtra projeto.
    final path = projectId == null
        ? '/api/messages'
        : '/api/projects/$projectId/messages';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(messageFromJson)
        .toList(growable: false);
  }

  Future<CollaborationMessage> createMessage(
    CollaborationMessage message,
  ) async {
    /*
     * O backend espera senderArtistId numerico. Por isso a tela precisa resolver
     * corretamente o artistId do usuario antes de chegar aqui.
     */
    final response =
        await _client.post(
              '/api/projects/${message.projectId}/messages',
              body: {
                'senderArtistId': int.parse(message.senderArtistId),
                'content': message.content,
                'type': _typeToApi(message.type),
              },
            )
            as Map<String, dynamic>;
    return messageFromJson(response);
  }
}

CollaborationMessage messageFromJson(Map<String, dynamic> json) {
  // Converte a resposta da API para o model usado pela interface Flutter.
  return CollaborationMessage(
    id: (json['id'] ?? '').toString(),
    projectId: (json['projectId'] ?? '').toString(),
    senderArtistId: (json['senderArtistId'] ?? '').toString(),
    content: (json['content'] ?? '').toString(),
    sentAt: (json['sentAt'] ?? '').toString(),
    type: _typeFromApi((json['type'] ?? '').toString()),
  );
}

CollaborationMessageType _typeFromApi(String value) {
  // A API usa enum em ingles/maiúsculo; o app usa enum Dart.
  return switch (value) {
    'NOTICE' => CollaborationMessageType.notice,
    'DECISION' => CollaborationMessageType.decision,
    'PENDING' => CollaborationMessageType.pending,
    _ => CollaborationMessageType.message,
  };
}

String _typeToApi(CollaborationMessageType type) {
  return switch (type) {
    CollaborationMessageType.message => 'MESSAGE',
    CollaborationMessageType.notice => 'NOTICE',
    CollaborationMessageType.decision => 'DECISION',
    CollaborationMessageType.pending => 'PENDING',
  };
}
