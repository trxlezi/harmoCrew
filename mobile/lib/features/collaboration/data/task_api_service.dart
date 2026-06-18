import '../../../core/api/api_client.dart';
import '../models/project_task.dart';

class TaskApiService {
  TaskApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ProjectTask>> listTasks({String? projectId}) async {
    final path = projectId == null
        ? '/api/tasks'
        : '/api/projects/$projectId/tasks';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(taskFromJson)
        .toList(growable: false);
  }

  Future<ProjectTask> createTask(ProjectTask task) async {
    final response =
        await _client.post(
              '/api/projects/${task.projectId}/tasks',
              body: {
                'title': task.title,
                'description': task.description,
                'status': _statusToApi(task.status),
                'priority': _priorityToApi(task.priority),
                'dueDate': task.dueDate,
                'responsibleName': task.assignedToArtistId,
              },
            )
            as Map<String, dynamic>;
    return taskFromJson(response);
  }

  Future<ProjectTask> updateStatus(
    String taskId,
    ProjectTaskStatus status,
  ) async {
    final response =
        await _client.patch(
              '/api/tasks/$taskId/status',
              body: {'status': _statusToApi(status)},
            )
            as Map<String, dynamic>;
    return taskFromJson(response);
  }
}

ProjectTask taskFromJson(Map<String, dynamic> json) {
  final project = json['project'] as Map<String, dynamic>?;
  final projectId = json['projectId'] ?? project?['id'] ?? '';

  return ProjectTask(
    id: (json['id'] ?? '').toString(),
    projectId: projectId.toString(),
    title: (json['title'] ?? '').toString(),
    assignedToArtistId: (json['responsibleName'] ?? '').toString(),
    dueDate: (json['dueDate'] ?? '').toString(),
    priority: _priorityFromApi((json['priority'] ?? '').toString()),
    status: _statusFromApi((json['status'] ?? '').toString()),
    description: (json['description'] ?? '').toString(),
  );
}

ProjectTaskStatus _statusFromApi(String value) {
  return switch (value) {
    'DONE' => ProjectTaskStatus.done,
    'IN_PROGRESS' => ProjectTaskStatus.doing,
    _ => ProjectTaskStatus.todo,
  };
}

String _statusToApi(ProjectTaskStatus status) {
  return switch (status) {
    ProjectTaskStatus.todo => 'TODO',
    ProjectTaskStatus.doing => 'IN_PROGRESS',
    ProjectTaskStatus.done => 'DONE',
  };
}

ProjectTaskPriority _priorityFromApi(String value) {
  return switch (value) {
    'HIGH' => ProjectTaskPriority.high,
    'LOW' => ProjectTaskPriority.low,
    _ => ProjectTaskPriority.medium,
  };
}

String _priorityToApi(ProjectTaskPriority priority) {
  return switch (priority) {
    ProjectTaskPriority.low => 'LOW',
    ProjectTaskPriority.medium => 'MEDIUM',
    ProjectTaskPriority.high => 'HIGH',
  };
}
