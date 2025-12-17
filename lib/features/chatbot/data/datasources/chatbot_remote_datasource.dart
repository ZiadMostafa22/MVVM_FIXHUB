import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/services/firebase_service.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/models/chat_message_dto.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/models/chat_conversation_dto.dart';

class ChatbotRemoteDatasource {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  /// Get conversation for a user
  Future<ChatConversationDTO?> getConversation(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chatbot_conversations')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ChatConversationDTO.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Error getting conversation: $e');
    }
  }

  /// Save a message to conversation
  Future<void> saveMessage(String userId, ChatMessageDTO message) async {
    try {
      // Get or create conversation
      final conversation = await getConversation(userId);
      
      if (conversation == null) {
        // Create new conversation
        final newConversation = ChatConversationDTO(
          id: _firestore.collection('chatbot_conversations').doc().id,
          userId: userId,
          messages: [message],
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
        );

        await _firestore
            .collection('chatbot_conversations')
            .doc(newConversation.id)
            .set(newConversation.toFirestore());
      } else {
        // Update existing conversation
        final updatedMessages = [...conversation.messages, message];
        await _firestore
            .collection('chatbot_conversations')
            .doc(conversation.id)
            .update({
          'messages': updatedMessages.map((msg) => {
            'id': msg.id,
            ...msg.toFirestore(),
          }).toList(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      throw Exception('Error saving message: $e');
    }
  }

  /// Clear conversation for a user
  Future<void> clearConversation(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chatbot_conversations')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error clearing conversation: $e');
    }
  }
}

