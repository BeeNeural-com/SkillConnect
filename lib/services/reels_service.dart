import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reel_model.dart';

/// Service for managing reels data from Firestore
class ReelsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get a stream of all reels ordered by creation date (newest first)
  Stream<List<Reel>> getReelsStream() {
    return _firestore
        .collection('reels')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Fetch all reels as a one-time operation
  Future<List<Reel>> fetchReels() async {
    try {
      final snapshot = await _firestore
          .collection('reels')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Reel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reels: $e');
    }
  }

  /// Fetch reels filtered by service category
  Future<List<Reel>> fetchReelsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('reels')
          .where('serviceCategory', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Reel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reels by category: $e');
    }
  }

  /// Fetch reels by a specific vendor
  Future<List<Reel>> fetchReelsByVendor(String vendorId) async {
    try {
      final snapshot = await _firestore
          .collection('reels')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Reel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reels by vendor: $e');
    }
  }

  /// Get a single reel by ID
  Future<Reel?> getReelById(String reelId) async {
    try {
      final doc = await _firestore.collection('reels').doc(reelId).get();

      if (!doc.exists) {
        return null;
      }

      return Reel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch reel: $e');
    }
  }

  /// Update like count for a reel
  Future<void> updateLikes(String reelId, int newLikeCount) async {
    try {
      await _firestore.collection('reels').doc(reelId).update({
        'likes': newLikeCount,
      });
    } catch (e) {
      throw Exception('Failed to update likes: $e');
    }
  }
}
