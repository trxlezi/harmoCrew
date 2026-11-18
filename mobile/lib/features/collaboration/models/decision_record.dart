enum DecisionStatus { registered, reviewed, canceled }

class DecisionRecord {
  const DecisionRecord({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.decidedByArtistId,
    required this.decidedAt,
    required this.impact,
    required this.status,
  });

  final String id;
  final String projectId;
  final String title;
  final String description;
  final String decidedByArtistId;
  final String decidedAt;
  final String impact;
  final DecisionStatus status;

  DecisionRecord copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? decidedByArtistId,
    String? decidedAt,
    String? impact,
    DecisionStatus? status,
  }) {
    return DecisionRecord(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      decidedByArtistId: decidedByArtistId ?? this.decidedByArtistId,
      decidedAt: decidedAt ?? this.decidedAt,
      impact: impact ?? this.impact,
      status: status ?? this.status,
    );
  }
}
