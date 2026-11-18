class Project {
  const Project({
    required this.id,
    required this.title,
    required this.style,
    required this.summary,
    required this.status,
    required this.ownerArtistId,
    required this.needs,
    this.startDate = '',
  });

  final String id;
  final String title;
  final String style;
  final String summary;
  final String status;
  final String ownerArtistId;
  final List<String> needs;
  final String startDate;

  Project copyWith({
    String? id,
    String? title,
    String? style,
    String? summary,
    String? status,
    String? ownerArtistId,
    List<String>? needs,
    String? startDate,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      style: style ?? this.style,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      ownerArtistId: ownerArtistId ?? this.ownerArtistId,
      needs: needs ?? this.needs,
      startDate: startDate ?? this.startDate,
    );
  }
}
