import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../core/constants/app_constants.dart';

// Chat Messages Stream Provider
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, bookingId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection(AppConstants.messagesCollection)
      .where('bookingId', isEqualTo: bookingId)
      .snapshots()
      .map((snapshot) {
        final messages = snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return messages;
      });
});

// Loading States
final chatLoadingProvider = StateProvider<bool>((ref) => false);
final chatErrorProvider = StateProvider<String?>((ref) => null);
