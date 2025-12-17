import 'package:car_maintenance_system_new/features/chatbot/domain/repositories/chatbot_repository.dart';

class ClearConversationUseCase {
  final ChatbotRepository repository;

  ClearConversationUseCase(this.repository);

  Future<void> call(String userId) async {
    return await repository.clearConversation(userId);
  }
}

