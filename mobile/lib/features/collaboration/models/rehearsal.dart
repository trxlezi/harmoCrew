enum RehearsalStatus { scheduled, completed, canceled }

class Rehearsal {
  const Rehearsal({
    required this.id,
    required this.projectId,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.participantArtistIds,
    required this.notes,
    required this.status,
  });

  final String id;
  final String projectId;
  final String title;
  final String date;
  final String time;
  final String location;
  final List<String> participantArtistIds;
  final String notes;
  final RehearsalStatus status;

  Rehearsal copyWith({
    String? id,
    String? projectId,
    String? title,
    String? date,
    String? time,
    String? location,
    List<String>? participantArtistIds,
    String? notes,
    RehearsalStatus? status,
  }) {
    return Rehearsal(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      participantArtistIds: participantArtistIds ?? this.participantArtistIds,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}
