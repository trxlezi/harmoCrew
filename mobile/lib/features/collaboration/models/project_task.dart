enum ProjectTaskStatus { todo, doing, done }

enum ProjectTaskPriority { low, medium, high }

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.projectId,
    required this.title,
    required this.assignedToArtistId,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.description = '',
  });

  final String id;
  final String projectId;
  final String title;
  final String assignedToArtistId;
  final String dueDate;
  final ProjectTaskPriority priority;
  final ProjectTaskStatus status;
  final String description;

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? assignedToArtistId,
    String? dueDate,
    ProjectTaskPriority? priority,
    ProjectTaskStatus? status,
    String? description,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      assignedToArtistId: assignedToArtistId ?? this.assignedToArtistId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}
