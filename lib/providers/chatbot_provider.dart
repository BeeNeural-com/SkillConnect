import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message_model.dart';
import '../services/chatbot_service.dart';

final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});

// Provider for chat messages
final chatMessagesProvider =
    StateProvider.family<List<ChatMessageModel>, String>((ref, userId) {
      return [];
    });

// Provider for loading state
final chatLoadingProvider = StateProvider.family<bool, String>((ref, userId) {
  return true;
});

// Initialize chat and load history
Future<void> initializeChat(WidgetRef ref, String userId) async {
  final chatbotService = ref.read(chatbotServiceProvider);
  ref.read(chatLoadingProvider(userId).notifier).state = true;

  try {
    final history = await chatbotService.loadChatHistory(userId);

    if (history.isEmpty) {
      // Send welcome message
      const uuid = Uuid();
      final welcomeMessage = ChatMessageModel(
        id: uuid.v4(),
        message:
            'Hello! 👋 I\'m your Skill Connect assistant. I can help you with:\n\n'
            '• Information about our services\n'
            '• How to book a technician\n'
            '• Pricing and payment\n'
            '• Account management\n\n'
            'What would you like to know?',
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider(userId).notifier).state = [welcomeMessage];
    } else {
      ref.read(chatMessagesProvider(userId).notifier).state = history;
    }
  } catch (e) {
    print('Error loading chat history: $e');
  } finally {
    ref.read(chatLoadingProvider(userId).notifier).state = false;
  }
}

// Send message
Future<void> sendChatMessage(
  WidgetRef ref,
  String userId,
  String message,
) async {
  if (message.trim().isEmpty) return;

  const uuid = Uuid();
  final chatbotService = ref.read(chatbotServiceProvider);
  final currentMessages = ref.read(chatMessagesProvider(userId));

  // Add user message
  final userMessage = ChatMessageModel(
    id: uuid.v4(),
    message: message.trim(),
    isUser: true,
    timestamp: DateTime.now(),
  );

  ref.read(chatMessagesProvider(userId).notifier).state = [
    ...currentMessages,
    userMessage,
  ];

  try {
    // Get bot response with conversation history
    final response = await chatbotService.processMessage(
      message,
      currentMessages,
    );

    // Add bot message
    final botMessage = ChatMessageModel(
      id: uuid.v4(),
      message: response,
      isUser: false,
      timestamp: DateTime.now(),
    );

    final updatedMessages = <ChatMessageModel>[
      ...currentMessages,
      userMessage,
      botMessage,
    ];
    ref.read(chatMessagesProvider(userId).notifier).state = updatedMessages;

    // Save to Firestore
    await chatbotService.saveChatHistory(userId, updatedMessages);
  } catch (e) {
    // On error, still keep user message but show error
    final errorMessage = ChatMessageModel(
      id: uuid.v4(),
      message: 'Sorry, I encountered an error. Please try again.',
      isUser: false,
      timestamp: DateTime.now(),
    );

    ref.read(chatMessagesProvider(userId).notifier).state = [
      ...currentMessages,
      userMessage,
      errorMessage,
    ];
  }
}

// Get quick replies
List<String> getQuickReplies(WidgetRef ref, String userId) {
  final chatbotService = ref.read(chatbotServiceProvider);
  final messages = ref.read(chatMessagesProvider(userId));

  final lastBotMessage = messages.lastWhere(
    (m) => !m.isUser,
    orElse: () => ChatMessageModel(
      id: '',
      message: '',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  );

  return chatbotService.getQuickReplies(
    lastBotMessage.message.isEmpty ? null : lastBotMessage.message,
  );
}

// Clear chat history
Future<void> clearChatHistory(WidgetRef ref, String userId) async {
  final chatbotService = ref.read(chatbotServiceProvider);
  ref.read(chatLoadingProvider(userId).notifier).state = true;

  await chatbotService.saveChatHistory(userId, []);
  await initializeChat(ref, userId);
}
