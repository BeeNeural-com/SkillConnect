import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianModel {
  final String id;
  final String userId;
  final List<String> skills;
  final String experience;
  final String description;
  final double rating;
  final int totalReviews;
  final bool isAvailable;
  final double? latitude;
  final double? longitude;
  final String? address;
  final List<String> certifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  TechnicianModel({
    required this.id,
    required this.userId,
    required this.skills,
    required this.experience,
    required this.description,
    required this.rating,
    required this.totalReviews,
    required this.isAvailable,
    this.latitude,
    this.longitude,
    this.address,
    required this.certifications,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore
  factory TechnicianModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TechnicianModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      experience: data['experience'] ?? '',
      description: data['description'] ?? '',
      rating: data['rating']?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      address: data['address'],
      certifications: List<String>.from(data['certifications'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'skills': skills,
      'experience': experience,
      'description': description,
      'rating': rating,
      'totalReviews': totalReviews,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'certifications': certifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with
  TechnicianModel copyWith({
    String? id,
    String? userId,
    List<String>? skills,
    String? experience,
    String? description,
    double? rating,
    int? totalReviews,
    bool? isAvailable,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? certifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skills: skills ?? this.skills,
      experience: experience ?? this.experience,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      isAvailable: isAvailable ?? this.isAvailable,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      certifications: certifications ?? this.certifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
