import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class RecalculateRatingsHelper {
  static Future<void> recalculateRatingForTechnician(String technicianId) async {
    try {
      debugPrint('Recalculating rating for technician: $technicianId');
      
      // Get all reviews for this technician
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: technicianId)
          .get();

      debugPrint('Found ${reviewsSnapshot.docs.length} reviews');

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews, set to 0
        await FirebaseFirestore.instance
            .collection(AppConstants.techniciansCollection)
            .doc(technicianId)
            .update({
          'rating': 0.0,
          'totalReviews': 0,
          'updatedAt': Timestamp.now(),
        });
        debugPrint('No reviews found, set rating to 0');
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final rating = (doc.data()['rating'] ?? 0.0).toDouble();
        totalRating += rating;
        debugPrint('Review ${doc.id}: rating $rating');
      }
      final averageRating = totalRating / reviewsSnapshot.docs.length;

      debugPrint('Average rating: $averageRating, Total reviews: ${reviewsSnapshot.docs.length}');

      // Update technician document
      await FirebaseFirestore.instance
          .collection(AppConstants.techniciansCollection)
          .doc(technicianId)
          .update({
        'rating': averageRating,
        'totalReviews': reviewsSnapshot.docs.length,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('Successfully updated technician rating!');
    } catch (e, stackTrace) {
      debugPrint('Error recalculating rating: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
