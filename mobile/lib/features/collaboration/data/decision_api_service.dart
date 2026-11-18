import '../../../core/api/api_client.dart';
import '../models/decision_record.dart';

class DecisionApiService {
  DecisionApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<DecisionRecord>> listDecisions({String? projectId}) async {
    final path = projectId == null
        ? '/api/decisions'
        : '/api/projects/$projectId/decisions';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(decisionFromJson)
        .toList(growable: false);
  }

  Future<DecisionRecord> createDecision(DecisionRecord decision) async {
    final response =
        await _client.post(
              '/api/projects/${decision.projectId}/decisions',
              body: {
                'title': decision.title,
                'description': decision.description,
                'impact': decision.impact,
                'decidedAt': decision.decidedAt,
                'decidedByArtistId': int.parse(decision.decidedByArtistId),
              },
            )
            as Map<String, dynamic>;
    return decisionFromJson(response);
  }

  Future<DecisionRecord> updateStatus(
    String decisionId,
    DecisionStatus status,
  ) async {
    final response =
        await _client.patch(
              '/api/decisions/$decisionId/status',
              body: {'status': _statusToApi(status)},
            )
            as Map<String, dynamic>;
    return decisionFromJson(response);
  }
}

DecisionRecord decisionFromJson(Map<String, dynamic> json) {
  return DecisionRecord(
    id: (json['id'] ?? '').toString(),
    projectId: (json['projectId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    decidedByArtistId: (json['decidedByArtistId'] ?? '').toString(),
    decidedAt: (json['decidedAt'] ?? '').toString(),
    impact: (json['impact'] ?? '').toString(),
    status: _statusFromApi((json['status'] ?? '').toString()),
  );
}

DecisionStatus _statusFromApi(String value) {
  return switch (value) {
    'REVIEWED' => DecisionStatus.reviewed,
    'CANCELED' => DecisionStatus.canceled,
    _ => DecisionStatus.registered,
  };
}

String _statusToApi(DecisionStatus status) {
  return switch (status) {
    DecisionStatus.registered => 'REGISTERED',
    DecisionStatus.reviewed => 'REVIEWED',
    DecisionStatus.canceled => 'CANCELED',
  };
}
