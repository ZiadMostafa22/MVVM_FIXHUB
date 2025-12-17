import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_conversation_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/models/chat_message_dto.dart';

class ChatConversationDTO {
  final String id;
  final String userId;
  final List<ChatMessageDTO> messages;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ChatConversationDTO({
    required this.id,
    required this.userId,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Entity
  ChatConversationEntity toEntity() {
    return ChatConversationEntity(
      id: id,
      userId: userId,
      messages: messages.map((dto) => dto.toEntity()).toList(),
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }

  // Convert from Entity
  factory ChatConversationDTO.fromEntity(ChatConversationEntity entity) {
    return ChatConversationDTO(
      id: entity.id,
      userId: entity.userId,
      messages: entity.messages.map((msg) => ChatMessageDTO.fromEntity(msg)).toList(),
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: Timestamp.fromDate(entity.updatedAt),
    );
  }

  // Convert from Firestore
  factory ChatConversationDTO.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final messagesData = data['messages'] as List<dynamic>? ?? [];
    
    return ChatConversationDTO(
      id: doc.id,
      userId: data['userId'] ?? '',
      messages: messagesData.map((msgData) {
        if (msgData is Map<String, dynamic>) {
          return ChatMessageDTO.fromFirestore(msgData, msgData['id'] ?? '');
        }
        return ChatMessageDTO(
          id: '',
          text: '',
          type: 'user',
          timestamp: Timestamp.now(),
        );
      }).toList(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'messages': messages.map((msg) => {
        'id': msg.id,
        ...msg.toFirestore(),
      }).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

