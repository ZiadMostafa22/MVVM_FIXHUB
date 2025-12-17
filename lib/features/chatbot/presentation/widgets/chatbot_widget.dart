import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/viewmodels/chatbot_viewmodel.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/widgets/chat_message_bubble.dart';
import 'package:car_maintenance_system_new/features/chatbot/presentation/widgets/chat_input_field.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class ChatbotWidget extends ConsumerStatefulWidget {
  const ChatbotWidget({super.key});

  @override
  ConsumerState<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends ConsumerState<ChatbotWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadConversation() {
    final user = ref.read(authViewModelProvider).user;
    if (user != null) {
      ref.read(chatbotViewModelProvider.notifier).loadConversation(user.id);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatbotState = ref.watch(chatbotViewModelProvider);
    final user = ref.watch(authViewModelProvider).user;

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    final defaultFont = GoogleFonts.rubik();

    return DefaultTextStyle(
      style: defaultFont.copyWith(color: Colors.black87),
      child: Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'مساعد الذكي',
                  style: GoogleFonts.rubik(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (chatbotState.messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () {
                      if (user != null) {
                        ref.read(chatbotViewModelProvider.notifier)
                            .clearConversation(user.id);
                      }
                    },
                    tooltip: 'مسح المحادثة',
                  ),
              ],
            ),
          ),
          // Messages List - Use Expanded to take available space
          Expanded(
            child: chatbotState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatbotState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'مرحباً! كيف يمكنني مساعدتك؟',
                              style: GoogleFonts.rubik(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'اسألني عن خدماتنا، الأسعار، أو أي استفسار آخر',
                                style: GoogleFonts.rubik(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: chatbotState.messages.length,
                        itemBuilder: (context, index) {
                          return ChatMessageBubble(
                            message: chatbotState.messages[index],
                          );
                        },
                      ),
          ),
          // Error message
          if (chatbotState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatbotState.error!,
                      style: GoogleFonts.rubik(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Input Field
          ChatInputField(
            onSend: (message) {
              if (user != null) {
                ref.read(chatbotViewModelProvider.notifier)
                    .sendMessage(user.id, message);
              }
            },
            isLoading: chatbotState.isSending,
          ),
        ],
      ),
      ),
    );
  }
}

