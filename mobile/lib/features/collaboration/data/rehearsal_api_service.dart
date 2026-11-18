import '../../../core/api/api_client.dart';
import '../models/rehearsal.dart';

class RehearsalApiService {
  RehearsalApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Rehearsal>> listRehearsals({String? projectId}) async {
    final path = projectId == null
        ? '/api/rehearsals'
        : '/api/projects/$projectId/rehearsals';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(rehearsalFromJson)
        .toList(growable: false);
  }

  Future<Rehearsal> createRehearsal(Rehearsal rehearsal) async {
    final response =
        await _client.post(
              '/api/projects/${rehearsal.projectId}/rehearsals',
              body: {
                'title': rehearsal.title,
                'date': rehearsal.date,
                'time': rehearsal.time,
                'location': rehearsal.location,
                'participantArtistIds': rehearsal.participantArtistIds
                    .map(int.parse)
                    .toList(growable: false),
                'notes': rehearsal.notes,
                'status': _statusToApi(rehearsal.status),
              },
            )
            as Map<String, dynamic>;
    return rehearsalFromJson(response);
  }

  Future<Rehearsal> updateStatus(
    String rehearsalId,
    RehearsalStatus status,
  ) async {
    final response =
        await _client.patch(
              '/api/rehearsals/$rehearsalId/status',
              body: {'status': _statusToApi(status)},
            )
            as Map<String, dynamic>;
    return rehearsalFromJson(response);
  }
}

Rehearsal rehearsalFromJson(Map<String, dynamic> json) {
  return Rehearsal(
    id: (json['id'] ?? '').toString(),
    projectId: (json['projectId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    date: (json['date'] ?? '').toString(),
    time: (json['time'] ?? '').toString(),
    location: (json['location'] ?? '').toString(),
    participantArtistIds: _stringList(json['participantArtistIds']),
    notes: (json['notes'] ?? '').toString(),
    status: _statusFromApi((json['status'] ?? '').toString()),
  );
}

RehearsalStatus _statusFromApi(String value) {
  return switch (value) {
    'COMPLETED' => RehearsalStatus.completed,
    'CANCELED' => RehearsalStatus.canceled,
    _ => RehearsalStatus.scheduled,
  };
}

String _statusToApi(RehearsalStatus status) {
  return switch (status) {
    RehearsalStatus.scheduled => 'SCHEDULED',
    RehearsalStatus.completed => 'COMPLETED',
    RehearsalStatus.canceled => 'CANCELED',
  };
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  return const [];
}
