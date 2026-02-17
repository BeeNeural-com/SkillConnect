import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message_model.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // API key is automatically loaded from .env file at app startup
  // The .env file is loaded in main.dart: await dotenv.load(fileName: ".env");
  // To configure: Add your key to .env file as GEMINI_API_KEY=your_key_here
  static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  late final GenerativeModel _model;

  ChatbotService() {
    // Initialize Gemini model
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite', // Updated model name
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  // Knowledge base for context
  final String _systemContext = '''
You are a helpful AI assistant for Skill Connect, a home services platform that connects customers with skilled technicians.

SERVICES WE OFFER:
1. Plumbing - Pipe repairs, leak fixing, drain cleaning, faucet installation, water heater maintenance. Available 24/7 for emergencies.
2. Electrical - Wiring, fixture installation, circuit repairs, panel upgrades, troubleshooting. All electricians are certified.
3. Carpentry - Furniture repair, custom woodwork, door/window installation, cabinet making, general wood repairs.
4. Painting - Interior and exterior painting, wall preparation, color consultation, finishing work for homes and offices.
5. AC/Appliance Repair - Air conditioner repair, maintenance, installation, general appliance troubleshooting.
6. Cleaning - Home and office cleaning, deep cleaning, move-in/out cleaning, regular maintenance cleaning.

HOW TO BOOK:
1. Select service category from home screen
2. Choose preferred technician
3. Select date and time
4. Confirm location
5. Submit request

PRICING:
- Pricing varies by service and technician
- Each technician sets their own hourly rates
- View rates on technician profiles before booking
- Payment after service completion
- Cash and digital payments accepted

TECHNICIANS:
- All verified professionals
- Ratings and reviews from previous customers
- View profiles, ratings, and experience before booking
- Rate and review after service completion

BOOKING MANAGEMENT:
- Cancel bookings before technician accepts
- After acceptance, contact technician directly
- To reschedule: cancel and create new booking
- View booking history in profile

SUPPORT:
- Contact support through app
- Chat with technicians directly
- Email support available
- Emergency services: look for 24/7 availability technicians

IMPORTANT GUIDELINES:
- Be friendly, helpful, and concise
- Focus on Skill Connect services only
- If asked about booking, guide them through the app
- If asked about specific technicians, tell them to browse in the app
- Keep responses under 150 words
- Use emojis sparingly for friendliness
- If you don't know something, be honest and suggest contacting support
''';

  // Get quick reply suggestions based on context
  List<String> getQuickReplies(String? lastBotMessage) {
    if (lastBotMessage == null) {
      return [
        'What services do you offer?',
        'How do I book a service?',
        'What are your prices?',
      ];
    }

    if (lastBotMessage.contains('services') ||
        lastBotMessage.contains('offer')) {
      return [
        'Tell me about plumbing',
        'Tell me about electrical',
        'How do I book?',
      ];
    }

    if (lastBotMessage.contains('book') || lastBotMessage.contains('booking')) {
      return [
        'What are your prices?',
        'How do I cancel?',
        'Tell me about technicians',
      ];
    }

    if (lastBotMessage.contains('price') || lastBotMessage.contains('cost')) {
      return [
        'How do I book?',
        'Tell me about payment',
        'What services do you offer?',
      ];
    }

    return [
      'What services do you offer?',
      'How do I book a service?',
      'Tell me about pricing',
    ];
  }

  // Save chat history to Firestore
  Future<void> saveChatHistory(
    String userId,
    List<ChatMessageModel> messages,
  ) async {
    try {
      final batch = _firestore.batch();
      final chatRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('chatbot_history');

      // Delete old messages
      final oldMessages = await chatRef.get();
      for (var doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }

      // Save new messages (last 50)
      final messagesToSave = messages.length > 50
          ? messages.sublist(messages.length - 50)
          : messages;

      for (var message in messagesToSave) {
        batch.set(chatRef.doc(message.id), message.toJson());
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Load chat history from Firestore
  Future<List<ChatMessageModel>> loadChatHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chatbot_history')
          .orderBy('timestamp')
          .get();

      return snapshot.docs
          .map((doc) => ChatMessageModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      return [];
    }
  }

  // Process user message with AI
  Future<String> processMessage(
    String userMessage,
    List<ChatMessageModel> history,
  ) async {
    try {
      // Check if API key is configured (loaded from .env)
      if (_geminiApiKey.isEmpty) {
        return _getFallbackResponse(userMessage);
      }

      // Build conversation history for context
      final conversationHistory = history
          .where(
            (msg) => !msg.message.contains('Hello! 👋'),
          ) // Skip welcome message
          .take(10) // Last 10 messages for context
          .map((msg) => '${msg.isUser ? "User" : "Assistant"}: ${msg.message}')
          .join('\n');

      // Create prompt with context
      final prompt =
          '''
$_systemContext

CONVERSATION HISTORY:
$conversationHistory

USER QUESTION: $userMessage

Please provide a helpful, friendly response based on the Skill Connect services and information above. Keep it concise and relevant.
''';

      // Get AI response
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  // Fallback response when AI is not available
  String _getFallbackResponse(String userMessage) {
    final lowerQuery = userMessage.toLowerCase();

    // Services
    if (lowerQuery.contains('service') && lowerQuery.contains('what')) {
      return 'We offer 6 main services: Plumbing, Electrical, Carpentry, Painting, AC/Appliance Repair, and Cleaning. Each service is provided by verified and skilled technicians. Which service are you interested in?';
    }
    if (lowerQuery.contains('plumb')) {
      return 'Our plumbing services include pipe repairs, leak fixing, drain cleaning, faucet installation, and water heater maintenance. Available 24/7 for emergencies! Would you like to book a plumber?';
    }
    if (lowerQuery.contains('electric')) {
      return 'Electrical services cover wiring, fixture installation, circuit repairs, panel upgrades, and troubleshooting. All our electricians are certified professionals. Need an electrician?';
    }
    if (lowerQuery.contains('carpen')) {
      return 'Carpentry services include furniture repair, custom woodwork, door/window installation, cabinet making, and general wood repairs. Looking for a carpenter?';
    }
    if (lowerQuery.contains('paint')) {
      return 'Painting services offer interior and exterior painting, wall preparation, color consultation, and finishing work for homes and offices. Need a painter?';
    }
    if (lowerQuery.contains('ac') || lowerQuery.contains('appliance')) {
      return 'AC and appliance services include air conditioner repair, maintenance, installation, and general appliance troubleshooting. How can we help with your appliances?';
    }
    if (lowerQuery.contains('clean')) {
      return 'Cleaning services provide home and office cleaning, deep cleaning, move-in/out cleaning, and regular maintenance cleaning. What type of cleaning do you need?';
    }

    // Booking
    if (lowerQuery.contains('book') || lowerQuery.contains('hire')) {
      return 'To book a service:\n1. Select the service category from home screen\n2. Choose your preferred technician\n3. Select date and time\n4. Confirm your location\n5. Submit the request\n\nIt\'s that simple! What service would you like to book?';
    }
    if (lowerQuery.contains('cancel')) {
      return 'You can cancel a booking from the booking details screen before the technician accepts it. Once accepted, please contact the technician directly through the in-app chat.';
    }

    // Pricing
    if (lowerQuery.contains('price') ||
        lowerQuery.contains('cost') ||
        lowerQuery.contains('how much')) {
      return 'Pricing varies by service and technician. Each technician sets their own hourly rates, which you can view on their profile before booking. Payment is made after service completion, and we accept both cash and digital payments.';
    }

    // Technicians
    if (lowerQuery.contains('technician') || lowerQuery.contains('worker')) {
      return 'All our technicians are verified professionals with ratings and reviews from previous customers. You can view their profiles, ratings, experience, and hourly rates before booking. After service completion, you can rate and review them too!';
    }

    // Support
    if (lowerQuery.contains('help') ||
        lowerQuery.contains('support') ||
        lowerQuery.contains('contact')) {
      return 'I\'m here to help! You can also contact support through the app, chat with technicians directly, or reach out via email. For emergency services, look for technicians with 24/7 availability. What do you need help with?';
    }

    // Default
    return 'I\'m here to help! I can answer questions about:\n\n• Our services (plumbing, electrical, carpentry, etc.)\n• How to book a technician\n• Pricing and payment\n• Technician ratings and reviews\n• Account management\n\nWhat would you like to know?';
  }
}
