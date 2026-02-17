import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/reel_model.dart';

class ReelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sanitizes a video URL by stripping leading / trailing quotes and
  /// extracting the first valid http(s) URL found in the string.
  static String sanitizeUrl(String raw) {
    final trimmed = raw.trim();
    final match = RegExp(r'https?://\S+').firstMatch(trimmed);
    if (match != null) {
      return match.group(0)!.trim();
    }
    var url = trimmed;
    while (url.isNotEmpty && '`"\''.contains(url[0])) {
      url = url.substring(1);
    }
    while (url.isNotEmpty && '`"\''.contains(url[url.length - 1])) {
      url = url.substring(0, url.length - 1);
    }
    return url.trim();
  }

  /// Returns a live stream of reels sorted newest-first.
  /// Automatically sanitizes URLs and writes back cleaned values.
  Stream<List<ReelModel>> reelsStream() {
    final cleanedIds = <String>{};

    return _firestore.collection('reels').snapshots().map((snapshot) {
      final reels = <ReelModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['videoUrl'] is! String) continue;

        final rawUrl = (data['videoUrl'] ?? '') as String;
        final cleanUrl = sanitizeUrl(rawUrl);

        // Write the sanitized URL back to Firestore once per reel
        if (!cleanedIds.contains(doc.id) && rawUrl.trim() != cleanUrl) {
          cleanedIds.add(doc.id);
          Future.microtask(() {
            _firestore
                .collection('reels')
                .doc(doc.id)
                .update({'videoUrl': cleanUrl});
          });
        }

        final reel = ReelModel.fromFirestore(doc).copyWith(videoUrl: cleanUrl);
        reels.add(reel);
      }

      reels.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(0);
        final bTime = b.createdAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      return reels;
    });
  }

  /// Toggles the like state for a reel.
  Future<void> toggleLike({
    required String reelId,
    required bool isLiked,
    required int newLikeCount,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('reels').doc(reelId).update({
      'likes': isLiked
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
      'likeCount': newLikeCount,
    });
  }

  /// Returns a stream of comments for a given reel.
  Stream<QuerySnapshot> commentsStream(String reelId) {
    return _firestore
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Adds a comment to a reel and increments the comment counter.
  Future<void> addComment({
    required String reelId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    final userName = userDoc.data()?['name'] as String? ?? 'Vendor';

    final commentsRef =
        _firestore.collection('reels').doc(reelId).collection('comments');
    await commentsRef.add({
      'userId': user.uid,
      'userName': userName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('reels')
        .doc(reelId)
        .update({'commentCount': FieldValue.increment(1)});
  }

  /// Returns the current user's UID, or null if unauthenticated.
  String? get currentUserId => _auth.currentUser?.uid;
}
