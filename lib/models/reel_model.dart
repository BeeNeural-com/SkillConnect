import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a short video reel posted by vendors
class Reel {
  final String id;
  final String videoUrl;
  final String vendorId;
  final String vendorName;
  final String serviceCategory;
  final String description;
  final DateTime createdAt;
  final int likes;
  final String thumbnailUrl;

  Reel({
    required this.id,
    required this.videoUrl,
    required this.vendorId,
    required this.vendorName,
    required this.serviceCategory,
    required this.description,
    required this.createdAt,
    this.likes = 0,
    required this.thumbnailUrl,
  });

  /// Create a Reel from Firestore document data
  factory Reel.fromFirestore(Map<String, dynamic> data, String id) {
    // Handle likes field - it might be stored as int or List
    int likesCount = 0;
    final likesData = data['likes'];
    if (likesData is int) {
      likesCount = likesData;
    } else if (likesData is List) {
      likesCount = likesData.length;
    }

    return Reel(
      id: id,
      videoUrl: data['videoUrl'] ?? '',
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? 'Unknown Vendor',
      serviceCategory: data['serviceCategory'] ?? 'General',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: likesCount,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
    );
  }

  /// Convert Reel to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'videoUrl': videoUrl,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'serviceCategory': serviceCategory,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Create a copy of this Reel with updated fields
  Reel copyWith({
    String? id,
    String? videoUrl,
    String? vendorId,
    String? vendorName,
    String? serviceCategory,
    String? description,
    DateTime? createdAt,
    int? likes,
    String? thumbnailUrl,
  }) {
    return Reel(
      id: id ?? this.id,
      videoUrl: videoUrl ?? this.videoUrl,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }
}
