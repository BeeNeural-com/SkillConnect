import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic create
  Future<DocumentReference> create(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      data['createdAt'] = Timestamp.now();
      data['updatedAt'] = Timestamp.now();
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic read
  Future<DocumentSnapshot> read(String collection, String docId) async {
    try {
      return await _firestore.collection(collection).doc(docId).get();
    } catch (e) {
      rethrow;
    }
  }

  // Generic update
  Future<void> update(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Generic delete
  Future<void> delete(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get all documents
  Stream<QuerySnapshot> getAll(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Get with query
  Stream<QuerySnapshot> getWhere(
    String collection, {
    required String field,
    required dynamic value,
  }) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: value)
        .snapshots();
  }

  // Get with multiple conditions
  Stream<QuerySnapshot> getWhereMultiple(
    String collection,
    Map<String, dynamic> conditions,
  ) {
    Query query = _firestore.collection(collection);
    
    conditions.forEach((field, value) {
      query = query.where(field, isEqualTo: value);
    });

    return query.snapshots();
  }

  // Get ordered
  Stream<QuerySnapshot> getOrdered(
    String collection, {
    required String orderBy,
    bool descending = false,
  }) {
    return _firestore
        .collection(collection)
        .orderBy(orderBy, descending: descending)
        .snapshots();
  }

  // Get with limit
  Stream<QuerySnapshot> getWithLimit(
    String collection, {
    required int limit,
    String? orderBy,
  }) {
    Query query = _firestore.collection(collection);
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: true);
    }
    
    return query.limit(limit).snapshots();
  }
}
