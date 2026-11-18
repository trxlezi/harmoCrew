import '../../../core/api/api_client.dart';

/*
 * Endpoints das 4 funcionalidades novas:
 * 1) matching/ranking de musicos   2) arquivos versionados, enquetes e auditoria
 * 3) timeline + alertas            4) dashboard de metricas
 *
 * As respostas sao mantidas como Map (JSON) e lidas pelos helpers de
 * json_helpers.dart, para manter o modulo enxuto.
 */
class ProductionApiService {
  ProductionApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  ApiClient get client => _client;

  String mediaUrl(String path) => _client.absoluteUrl(path);

  // ---------------------------------------------------------- Funcionalidade 1
  Future<List<Map<String, dynamic>>> matches(
    String projectId, {
    String? style,
    String? instrument,
    String? city,
    int? minScore,
  }) async {
    final query = <String, String>{
      if (style != null && style.isNotEmpty) 'style': style,
      if (instrument != null && instrument.isNotEmpty) 'instrument': instrument,
      if (city != null && city.isNotEmpty) 'city': city,
      if (minScore != null && minScore > 0) 'minScore': '$minScore',
    };
    final qs = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return _list(await _client.get('/api/projects/$projectId/matches$qs'));
  }

  Future<List<Map<String, dynamic>>> rankedApplications(
    String projectId,
  ) async {
    return _list(
      await _client.get('/api/projects/$projectId/applications/ranked'),
    );
  }

  Future<Map<String, dynamic>> updateApplication(
    String applicationId,
    String status, {
    String? note,
  }) async {
    return await _client.patch(
          '/api/applications/$applicationId/status',
          body: {'status': status, 'evaluationNote': ?note},
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> project(String projectId) async {
    return await _client.get('/api/projects/$projectId')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProject(
    String projectId,
    Map<String, dynamic> body,
  ) async {
    return await _client.put('/api/projects/$projectId', body: body)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> artist(String artistId) async {
    return await _client.get('/api/artists/$artistId') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateArtist(
    String artistId,
    Map<String, dynamic> body,
  ) async {
    return await _client.put('/api/artists/$artistId', body: body)
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadArtistAudio(
    String artistId,
    List<int> bytes,
    String filename,
  ) async {
    return await _client.upload(
          '/api/artists/$artistId/audio',
          bytes: bytes,
          filename: filename,
        )
        as Map<String, dynamic>;
  }

  // ---------------------------------------------------------- Funcionalidade 2
  Future<List<Map<String, dynamic>>> files(String projectId) async {
    return _list(await _client.get('/api/projects/$projectId/files'));
  }

  Future<Map<String, dynamic>> createFile(
    String projectId, {
    required List<int> bytes,
    required String filename,
    required String name,
    required String category,
    String? description,
    String? note,
    String? artistId,
  }) async {
    return await _client.upload(
          '/api/projects/$projectId/files',
          bytes: bytes,
          filename: filename,
          fields: {
            'name': name,
            'category': category,
            'description': ?description,
            'note': ?note,
            'artistId': ?artistId,
          },
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadVersion(
    String fileId, {
    required List<int> bytes,
    required String filename,
    String? note,
    String? artistId,
  }) async {
    return await _client.upload(
          '/api/files/$fileId/versions',
          bytes: bytes,
          filename: filename,
          fields: {'note': ?note, 'artistId': ?artistId},
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlockFile(
    String fileId,
    String reason,
    String? artistId,
  ) async {
    return await _client.post(
          '/api/files/$fileId/unlock',
          body: {'reason': reason, 'artistId': ?_id(artistId)},
        )
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> polls(String projectId) async {
    return _list(await _client.get('/api/projects/$projectId/polls'));
  }

  Future<Map<String, dynamic>> createPoll(
    String projectId, {
    required String question,
    String? description,
    DateTime? closesAt,
    String? artistId,
    required List<({String label, int? fileVersionId})> options,
  }) async {
    return await _client.post(
          '/api/projects/$projectId/polls',
          body: {
            'question': question,
            'description': ?description,
            'closesAt': ?closesAt?.toIso8601String(),
            'createdByArtistId': ?_id(artistId),
            'options': options
                .map(
                  (o) => {'label': o.label, 'fileVersionId': ?o.fileVersionId},
                )
                .toList(),
          },
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> vote(
    int pollId,
    int optionId,
    String? artistId,
  ) async {
    return await _client.post(
          '/api/polls/$pollId/votes',
          body: {'optionId': optionId, 'artistId': ?_id(artistId)},
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closePoll(
    int pollId,
    String? artistId, {
    int? tieBreakOptionId,
  }) async {
    return await _client.post(
          '/api/polls/$pollId/close',
          body: {
            'artistId': ?_id(artistId),
            'tieBreakOptionId': ?tieBreakOptionId,
          },
        )
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> auditLogs(String projectId) async {
    return _list(await _client.get('/api/projects/$projectId/audit-logs'));
  }

  // ---------------------------------------------------------- Funcionalidade 3
  Future<Map<String, dynamic>> timeline(String projectId) async {
    return await _client.get('/api/projects/$projectId/timeline')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTaskStatus(
    int taskId,
    String status,
  ) async {
    return await _client.patch(
          '/api/tasks/$taskId/status',
          body: {'status': status},
        )
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTask(
    String projectId,
    Map<String, dynamic> body,
  ) async {
    return await _client.post('/api/projects/$projectId/tasks', body: body)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> notifications(String artistId) async {
    return _list(await _client.get('/api/notifications?artistId=$artistId'));
  }

  Future<void> markNotificationRead(int id) async {
    await _client.patch('/api/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead(String artistId) async {
    await _client.patch('/api/notifications/read-all?artistId=$artistId');
  }

  // ---------------------------------------------------------- Funcionalidade 4
  Future<Map<String, dynamic>> dashboard({
    String? projectId,
    String? artistId,
  }) async {
    final path = projectId != null
        ? '/api/projects/$projectId/dashboard'
        : '/api/dashboard${artistId == null ? '' : '?artistId=$artistId'}';
    return await _client.get(path) as Map<String, dynamic>;
  }

  Future<void> registerAttendance(int rehearsalId, Set<int> attended) async {
    await _client.patch(
      '/api/rehearsals/$rehearsalId/attendance',
      body: {'attendedArtistIds': attended.toList()},
    );
  }

  static int? _id(String? value) => value == null ? null : int.tryParse(value);

  static List<Map<String, dynamic>> _list(dynamic response) {
    if (response is! List) {
      return const [];
    }
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
