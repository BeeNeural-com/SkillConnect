import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/booking_model.dart';
import '../core/constants/app_constants.dart';

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// User Bookings Stream Provider (for customers)
final userBookingsProvider = StreamProvider.family<List<BookingModel>, String>((
  ref,
  userId,
) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection(AppConstants.bookingsCollection)
      .where('customerId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        final bookings = snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList();
        // Sort in memory instead of Firestore
        bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return bookings;
      });
});

// Vendor Bookings Stream Provider (for vendors)
final vendorBookingsProvider = StreamProvider.family<List<BookingModel>, String>(
  (ref, technicianId) {
    final firestore = FirebaseFirestore.instance;
    debugPrint(
      '📋 vendorBookingsProvider: Querying for technicianId: $technicianId',
    );
    return firestore
        .collection(AppConstants.bookingsCollection)
        .where('technicianId', isEqualTo: technicianId)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '📋 vendorBookingsProvider: Found ${snapshot.docs.length} bookings',
          );
          if (snapshot.docs.isNotEmpty) {
            for (var doc in snapshot.docs) {
              final data = doc.data();
              debugPrint('  - Booking ${doc.id}: status=${data['status']}');
            }
          }
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromFirestore(doc))
              .toList();
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  },
);

// Vendor Pending Requests Provider
final vendorPendingRequestsProvider =
    StreamProvider.family<List<BookingModel>, String>((ref, technicianId) {
      final firestore = FirebaseFirestore.instance;
      debugPrint(
        '📋 vendorPendingRequestsProvider querying for technicianId: $technicianId',
      );
      return firestore
          .collection(AppConstants.bookingsCollection)
          .where('technicianId', isEqualTo: technicianId)
          .where('status', isEqualTo: AppConstants.statusPending)
          .snapshots()
          .map((snapshot) {
            debugPrint('📋 Found ${snapshot.docs.length} pending bookings');
            if (snapshot.docs.isNotEmpty) {
              for (var doc in snapshot.docs) {
                final data = doc.data();
                debugPrint(
                  '  - Booking ${doc.id}: technicianId=${data['technicianId']}, status=${data['status']}',
                );
              }
            }
            final bookings = snapshot.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList();
            bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return bookings;
          });
    });

// Loading States
final bookingLoadingProvider = StateProvider<bool>((ref) => false);
final bookingErrorProvider = StateProvider<String?>((ref) => null);
