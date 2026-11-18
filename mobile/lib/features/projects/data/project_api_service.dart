import '../../../core/api/api_client.dart';
import '../../collaboration/models/project.dart';

class ProjectApiService {
  /*
   * Service dos projetos musicais.
   *
   * A tela cria um Project do Flutter. Este service transforma para o JSON que
   * a API Spring espera: title, description, musicalStyle, status, needs e
   * startDate.
   */
  ProjectApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Project>> listProjects() async {
    final response = await _client.get('/api/projects') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(projectFromJson)
        .toList(growable: false);
  }

  Future<Project> createProject(Project project) async {
    // POST /api/projects cria o projeto real no banco PostgreSQL.
    final response =
        await _client.post(
              '/api/projects',
              body: {
                'title': project.title,
                'description': project.summary,
                'musicalStyle': project.style,
                'status': _projectStatusForApi(project.status),
                'needs': project.needs,
                'startDate': project.startDate.isEmpty
                    ? DateTime.now().toIso8601String().substring(0, 10)
                    : project.startDate,
              },
            )
            as Map<String, dynamic>;
    return projectFromJson(response);
  }
}

Project projectFromJson(Map<String, dynamic> json) {
  // Traduz campos do backend para o model de colaboracao usado nas telas.
  return Project(
    id: (json['id'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    style: (json['musicalStyle'] ?? '').toString(),
    summary: (json['description'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    ownerArtistId: '',
    needs: _stringList(json['needs']),
    startDate: (json['startDate'] ?? '').toString(),
  );
}

String _projectStatusForApi(String status) {
  /*
   * Protecao contra status invalido vindo de UI/teste.
   * O backend aceita somente estes valores do enum; caso contrario usamos ACTIVE.
   */
  final normalized = status.trim().toUpperCase();
  if (normalized == 'ACTIVE' ||
      normalized == 'PAUSED' ||
      normalized == 'FINISHED' ||
      normalized == 'PLANNING') {
    return normalized;
  }

  return 'ACTIVE';
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList(growable: false);
  }

  return const [];
}
