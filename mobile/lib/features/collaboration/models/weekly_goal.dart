enum WeeklyGoalStatus { planned, inProgress, done }

class WeeklyGoal {
  const WeeklyGoal({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.ownerArtistId,
    required this.weekLabel,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String ownerArtistId;
  final String weekLabel;
  final String dueDate;
  final WeeklyGoalStatus status;

  WeeklyGoal copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? ownerArtistId,
    String? weekLabel,
    String? dueDate,
    WeeklyGoalStatus? status,
  }) {
    return WeeklyGoal(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      ownerArtistId: ownerArtistId ?? this.ownerArtistId,
      weekLabel: weekLabel ?? this.weekLabel,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }
}
