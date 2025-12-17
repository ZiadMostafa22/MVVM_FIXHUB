import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/send_message_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/get_conversations_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/clear_conversation_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/data/di/chatbot_di.dart';

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  final repository = ref.watch(chatbotRepositoryProvider);
  return SendMessageUseCase(repository);
});

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  final repository = ref.watch(chatbotRepositoryProvider);
  return GetConversationsUseCase(repository);
});

final clearConversationUseCaseProvider = Provider<ClearConversationUseCase>((ref) {
  final repository = ref.watch(chatbotRepositoryProvider);
  return ClearConversationUseCase(repository);
});

