import '../../../core/api/api_client.dart';
import '../models/weekly_goal.dart';

class WeeklyGoalApiService {
  WeeklyGoalApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<WeeklyGoal>> listWeeklyGoals({String? projectId}) async {
    final path = projectId == null
        ? '/api/weekly-goals'
        : '/api/projects/$projectId/weekly-goals';
    final response = await _client.get(path) as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(weeklyGoalFromJson)
        .toList(growable: false);
  }

  Future<WeeklyGoal> createWeeklyGoal(WeeklyGoal goal) async {
    final response =
        await _client.post(
              '/api/projects/${goal.projectId}/weekly-goals',
              body: _request(goal),
            )
            as Map<String, dynamic>;
    return weeklyGoalFromJson(response);
  }

  Future<WeeklyGoal> updateWeeklyGoal(WeeklyGoal goal) async {
    final response =
        await _client.put('/api/weekly-goals/${goal.id}', body: _request(goal))
            as Map<String, dynamic>;
    return weeklyGoalFromJson(response);
  }

  Future<WeeklyGoal> updateStatus(String goalId, WeeklyGoalStatus status) async {
    final response =
        await _client.patch(
              '/api/weekly-goals/$goalId/status',
              body: {'status': _statusToApi(status)},
            )
            as Map<String, dynamic>;
    return weeklyGoalFromJson(response);
  }

  Future<void> deleteWeeklyGoal(String goalId) {
    return _client.delete('/api/weekly-goals/$goalId');
  }

  Map<String, dynamic> _request(WeeklyGoal goal) {
    return {
      'title': goal.title,
      'description': goal.description,
      'ownerArtistId': int.parse(goal.ownerArtistId),
      'weekLabel': goal.weekLabel,
      'dueDate': goal.dueDate,
      'status': _statusToApi(goal.status),
    };
  }
}

WeeklyGoal weeklyGoalFromJson(Map<String, dynamic> json) {
  return WeeklyGoal(
    id: (json['id'] ?? '').toString(),
    projectId: (json['projectId'] ?? '').toString(),
    title: (json['title'] ?? '').toString(),
    description: (json['description'] ?? '').toString(),
    ownerArtistId: (json['ownerArtistId'] ?? '').toString(),
    weekLabel: (json['weekLabel'] ?? '').toString(),
    dueDate: (json['dueDate'] ?? '').toString(),
    status: _statusFromApi((json['status'] ?? '').toString()),
  );
}

WeeklyGoalStatus _statusFromApi(String value) {
  return switch (value) {
    'IN_PROGRESS' => WeeklyGoalStatus.inProgress,
    'DONE' => WeeklyGoalStatus.done,
    _ => WeeklyGoalStatus.planned,
  };
}

String _statusToApi(WeeklyGoalStatus status) {
  return switch (status) {
    WeeklyGoalStatus.planned => 'PLANNED',
    WeeklyGoalStatus.inProgress => 'IN_PROGRESS',
    WeeklyGoalStatus.done => 'DONE',
  };
}
