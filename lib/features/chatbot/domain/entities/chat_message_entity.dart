enum MessageType {
  user,
  assistant,
}

class ChatMessageEntity {
  final String id;
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ChatMessageEntity({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
  });

  ChatMessageEntity copyWith({
    String? id,
    String? text,
    MessageType? type,
    DateTime? timestamp,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

