enum CollaborationMessageType { message, notice, decision, pending }

class CollaborationMessage {
  const CollaborationMessage({
    required this.id,
    required this.projectId,
    required this.senderArtistId,
    required this.content,
    required this.sentAt,
    required this.type,
  });

  final String id;
  final String projectId;
  final String senderArtistId;
  final String content;
  final String sentAt;
  final CollaborationMessageType type;

  CollaborationMessage copyWith({
    String? id,
    String? projectId,
    String? senderArtistId,
    String? content,
    String? sentAt,
    CollaborationMessageType? type,
  }) {
    return CollaborationMessage(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      senderArtistId: senderArtistId ?? this.senderArtistId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      type: type ?? this.type,
    );
  }
}
