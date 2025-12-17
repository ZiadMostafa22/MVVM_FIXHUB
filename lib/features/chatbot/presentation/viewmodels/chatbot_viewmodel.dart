import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/entities/chat_message_entity.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/di/chatbot_usecases_di.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/send_message_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/get_conversations_usecase.dart';
import 'package:car_maintenance_system_new/features/chatbot/domain/usecases/clear_conversation_usecase.dart';

final chatbotViewModelProvider = StateNotifierProvider<ChatbotViewModel, ChatbotState>((ref) {
  final sendMessageUseCase = ref.watch(sendMessageUseCaseProvider);
  final getConversationsUseCase = ref.watch(getConversationsUseCaseProvider);
  final clearConversationUseCase = ref.watch(clearConversationUseCaseProvider);
  return ChatbotViewModel(
    sendMessageUseCase,
    getConversationsUseCase,
    clearConversationUseCase,
  );
});

class ChatbotState {
  final List<ChatMessageEntity> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  ChatbotState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatbotState copyWith({
    List<ChatMessageEntity>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}

class ChatbotViewModel extends StateNotifier<ChatbotState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final ClearConversationUseCase clearConversationUseCase;

  ChatbotViewModel(
    this.sendMessageUseCase,
    this.getConversationsUseCase,
    this.clearConversationUseCase,
  ) : super(ChatbotState());

  /// Load conversation history for a user
  Future<void> loadConversation(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final conversation = await getConversationsUseCase(userId);
      
      if (conversation != null) {
        state = state.copyWith(
          messages: conversation.messages,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String userId, String message) async {
    if (message.trim().isEmpty) return;

    try {
      state = state.copyWith(isSending: true, error: null);

      // Add user message to state immediately
      final userMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        type: MessageType.user,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, userMessage],
      );

      // Get AI response
      final response = await sendMessageUseCase(userId, message, state.messages);

      // Add AI response to state
      final assistantMessage = ChatMessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: response,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isSending: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Clear conversation
  Future<void> clearConversation(String userId) async {
    try {
      await clearConversationUseCase(userId);
      state = state.copyWith(messages: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

