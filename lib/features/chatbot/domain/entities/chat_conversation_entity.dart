import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';

class ChatConversationEntity {
  final String id;
  final String userId;
  final List<ChatMessageEntity> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversationEntity({
    required this.id,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  ChatConversationEntity copyWith({
    String? id,
    String? userId,
    List<ChatMessageEntity>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

