enum ApplicationStatus { pending, approved, rejected }

class Application {
  const Application({
    required this.id,
    required this.projectId,
    required this.artistId,
    required this.message,
    required this.specialty,
    required this.availability,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String artistId;
  final String message;
  final String specialty;
  final String availability;
  final ApplicationStatus status;
  final String createdAt;

  Application copyWith({
    String? id,
    String? projectId,
    String? artistId,
    String? message,
    String? specialty,
    String? availability,
    ApplicationStatus? status,
    String? createdAt,
  }) {
    return Application(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      artistId: artistId ?? this.artistId,
      message: message ?? this.message,
      specialty: specialty ?? this.specialty,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
