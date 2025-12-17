import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_conversation_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/repositories/chatbot_repository.dart';

class GetConversationsUseCase {
  final ChatbotRepository repository;

  GetConversationsUseCase(this.repository);

  Future<ChatConversationEntity?> call(String userId) async {
    return await repository.getConversation(userId);
  }
}

