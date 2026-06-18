import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/application.dart';

class ApplicationApiService {
  ApplicationApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Application>> listApplications({String? projectId}) async {
    final path = projectId == null
        ? '/api/applications'
        : '/api/projects/$projectId/applications';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(applicationFromJson)
        .toList(growable: false);
  }

  Future<Application> createApplication(Application application) async {
    final artistId = int.tryParse(application.artistId);
    if (artistId == null) {
      throw const ApiException('Selecione um artista valido para candidatura.');
    }

    final response =
        await _client.post(
              '/api/projects/${application.projectId}/applications',
              body: {
                'artistId': artistId,
                'message': application.message,
                'specialty': application.specialty,
                'availability': application.availability,
              },
            )
            as Map<String, dynamic>;
    return applicationFromJson(response);
  }

  Future<Application> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    final response =
        await _client.patch(
              '/api/applications/$applicationId/status',
              body: {'status': _statusToApi(status)},
            )
            as Map<String, dynamic>;
    return applicationFromJson(response);
  }
}

Application applicationFromJson(Map<String, dynamic> json) {
  final project = json['project'] as Map<String, dynamic>?;
  final artist = json['artist'] as Map<String, dynamic>?;
  final projectId = json['projectId'] ?? project?['id'] ?? '';
  final artistId = json['artistId'] ?? artist?['id'] ?? '';

  return Application(
    id: (json['id'] ?? '').toString(),
    projectId: projectId.toString(),
    artistId: artistId.toString(),
    message: (json['message'] ?? '').toString(),
    specialty: (json['specialty'] ?? '').toString(),
    availability: (json['availability'] ?? '').toString(),
    status: _statusFromApi((json['status'] ?? '').toString()),
    createdAt: (json['createdAt'] ?? '').toString().split('T').first,
  );
}

ApplicationStatus _statusFromApi(String value) {
  return switch (value) {
    'APPROVED' => ApplicationStatus.approved,
    'REJECTED' => ApplicationStatus.rejected,
    _ => ApplicationStatus.pending,
  };
}

String _statusToApi(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.pending => 'PENDING',
    ApplicationStatus.approved => 'APPROVED',
    ApplicationStatus.rejected => 'REJECTED',
  };
}
