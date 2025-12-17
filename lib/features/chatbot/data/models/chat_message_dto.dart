import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';

class ChatMessageDTO {
  final String id;
  final String text;
  final String type; // 'user' or 'assistant'
  final Timestamp timestamp;

  ChatMessageDTO({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
  });

  // Convert to Entity
  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      text: text,
      type: type == 'user' ? MessageType.user : MessageType.assistant,
      timestamp: timestamp.toDate(),
    );
  }

  // Convert from Entity
  factory ChatMessageDTO.fromEntity(ChatMessageEntity entity) {
    return ChatMessageDTO(
      id: entity.id,
      text: entity.text,
      type: entity.type == MessageType.user ? 'user' : 'assistant',
      timestamp: Timestamp.fromDate(entity.timestamp),
    );
  }

  // Convert from Firestore
  factory ChatMessageDTO.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessageDTO(
      id: id,
      text: data['text'] ?? '',
      type: data['type'] ?? 'user',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'type': type,
      'timestamp': timestamp,
    };
  }
}

