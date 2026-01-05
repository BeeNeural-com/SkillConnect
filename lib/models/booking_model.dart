import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String customerId;
  final String technicianId;
  final String serviceCategory;
  final String description;
  final String status; // pending, accepted, in_progress, completed, cancelled, rejected
  final double? estimatedPrice;
  final double? finalPrice;
  final List<String> imageUrls;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.customerId,
    required this.technicianId,
    required this.serviceCategory,
    required this.description,
    required this.status,
    this.estimatedPrice,
    this.finalPrice,
    required this.imageUrls,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.scheduledDate,
    required this.createdAt,
    required this.updatedAt,
  });

  // From Firestore
  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      technicianId: data['technicianId'] ?? '',
      serviceCategory: data['serviceCategory'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      estimatedPrice: data['estimatedPrice']?.toDouble(),
      finalPrice: data['finalPrice']?.toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      address: data['address'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      scheduledDate: (data['scheduledDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // To Firestore
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'technicianId': technicianId,
      'serviceCategory': serviceCategory,
      'description': description,
      'status': status,
      'estimatedPrice': estimatedPrice,
      'finalPrice': finalPrice,
      'imageUrls': imageUrls,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with
  BookingModel copyWith({
    String? id,
    String? customerId,
    String? technicianId,
    String? serviceCategory,
    String? description,
    String? status,
    double? estimatedPrice,
    double? finalPrice,
    List<String>? imageUrls,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? scheduledDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      technicianId: technicianId ?? this.technicianId,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      description: description ?? this.description,
      status: status ?? this.status,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      imageUrls: imageUrls ?? this.imageUrls,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
