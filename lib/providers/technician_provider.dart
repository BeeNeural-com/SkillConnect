import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/technician_model.dart';
import '../core/constants/app_constants.dart';

// Firestore Service Provider
final technicianFirestoreProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Technician Profile Provider
final technicianProfileProvider = StreamProvider.family<TechnicianModel?, String>((
  ref,
  userId,
) {
  final firestore = FirebaseFirestore.instance;
  debugPrint('🔍 technicianProfileProvider: Querying for userId: $userId');
  return firestore
      .collection(AppConstants.techniciansCollection)
      .where('userId', isEqualTo: userId)
      .limit(1)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          debugPrint('❌ No technician found for userId: $userId');
          return null;
        }
        final tech = TechnicianModel.fromFirestore(snapshot.docs.first);
        debugPrint(
          '✅ Technician found: docId=${snapshot.docs.first.id}, rating=${tech.rating}, totalReviews=${tech.totalReviews}',
        );
        return tech;
      });
});

// Loading States
final technicianLoadingProvider = StateProvider<bool>((ref) => false);
final technicianErrorProvider = StateProvider<String?>((ref) => null);
