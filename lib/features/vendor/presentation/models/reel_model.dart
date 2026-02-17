import 'package:cloud_firestore/cloud_firestore.dart';

class ReelModel {
  final String id;
  final String videoUrl;
  final String caption;
  final String userName;
  final List<String> likes;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  const ReelModel({
    required this.id,
    required this.videoUrl,
    this.caption = '',
    this.userName = 'Vendor',
    this.likes = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  factory ReelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final likes =
        data['likes'] is List ? List<String>.from(data['likes']) : <String>[];
    return ReelModel(
      id: doc.id,
      videoUrl: (data['videoUrl'] ?? '') as String,
      caption: (data['caption'] ?? '') as String,
      userName: (data['userName'] ?? 'Vendor') as String,
      likes: likes,
      likeCount: (data['likeCount'] ?? likes.length) as int,
      commentCount: (data['commentCount'] ?? 0) as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  ReelModel copyWith({
    String? videoUrl,
    int? likeCount,
    int? commentCount,
    List<String>? likes,
  }) {
    return ReelModel(
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption,
      userName: userName,
      likes: likes ?? this.likes,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt,
    );
  }
}
