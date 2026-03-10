import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user document exists
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .get();

      // If user doesn't exist, create a basic user document with Google info
      if (!userDoc.exists) {
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? 'User',
          phone: '', // Will be collected later
          role: '', // Will be collected later
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userCredential.user!.uid)
            .set(userModel.toMap());
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      // Check if required fields are filled
      final phone = data['phone'] as String?;
      final role = data['role'] as String?;

      return phone != null &&
          phone.isNotEmpty &&
          role != null &&
          role.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Validate and filter sub-skills to remove orphaned ones
  List<String> _validateSubSkills(
    List<String>? subSkills,
    List<String>? selectedSkills,
  ) {
    if (subSkills == null || subSkills.isEmpty) {
      return [];
    }

    if (selectedSkills == null || selectedSkills.isEmpty) {
      return [];
    }

    // Create a set of selected skills for O(1) lookup
    final selectedSkillsSet = selectedSkills.toSet();

    // Map of sub-skill IDs to their parent skill IDs
    final subSkillParentMap = {
      'electrical_wiring': 'electrical',
      'electrical_appliance_repair': 'electrical',
      'solar_installation': 'electrical',
    };

    // Filter out orphaned sub-skills
    final validSubSkills = subSkills.where((subSkillId) {
      final parentSkillId = subSkillParentMap[subSkillId];
      if (parentSkillId == null) {
        print('Warning: Unknown sub-skill ID: $subSkillId');
        return false;
      }

      final isValid = selectedSkillsSet.contains(parentSkillId);
      if (!isValid) {
        print(
          'Warning: Orphaned sub-skill detected: $subSkillId (parent: $parentSkillId not selected)',
        );
      }

      return isValid;
    }).toList();

    return validSubSkills;
  }

  // Complete user profile after Google Sign-In
  Future<void> completeProfile({
    required String userId,
    required String phone,
    required String role,
    String? experience,
    List<String>? skills,
    List<String>? subSkills,
    String? description,
  }) async {
    try {
      // Validate and filter sub-skills
      final validatedSubSkills = _validateSubSkills(subSkills, skills);

      final updateData = {
        'phone': phone,
        'role': role,
        'skills': skills ?? [],
        'subSkills': validatedSubSkills,
        'updatedAt': Timestamp.now(),
      };

      // Update user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);

      // If role is vendor, create technician profile
      if (role == AppConstants.roleVendor) {
        final technicianData = {
          'userId': userId,
          'experience': experience ?? '',
          'skills': skills ?? [],
          'subSkills': validatedSubSkills,
          'description': description ?? '',
          'isAvailable': true,
          'rating': 0.0,
          'totalReviews': 0,
          'certifications': [],
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        await _firestore
            .collection(AppConstants.techniciansCollection)
            .add(technicianData);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user data stream (real-time updates)
  Stream<UserModel?> getUserDataStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Deactivate account (soft delete - sets isActive flag to false)
  Future<void> deactivateAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Update user document to mark as inactive
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
            'isActive': false,
            'deactivatedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });

      // If vendor, also deactivate technician profile
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['role'] == AppConstants.roleVendor) {
          final technicianQuery = await _firestore
              .collection(AppConstants.techniciansCollection)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (technicianQuery.docs.isNotEmpty) {
            await technicianQuery.docs.first.reference.update({
              'isActive': false,
              'updatedAt': Timestamp.now(),
            });
          }
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete account permanently
  Future<void> deleteAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Get user data to check role
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();

        // If vendor, delete technician profile and related data
        if (userData != null && userData['role'] == AppConstants.roleVendor) {
          // Delete technician profile
          final technicianQuery = await _firestore
              .collection(AppConstants.techniciansCollection)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

          if (technicianQuery.docs.isNotEmpty) {
            await technicianQuery.docs.first.reference.delete();
          }

          // Delete vendor's reviews (if reviews collection exists)
          try {
            final reviewsQuery = await _firestore
                .collection('reviews')
                .where('technicianId', isEqualTo: userId)
                .get();

            for (var doc in reviewsQuery.docs) {
              await doc.reference.delete();
            }
          } catch (e) {
            // Reviews collection might not exist
          }
        }

        // Delete user's bookings
        final bookingsQuery = await _firestore
            .collection(AppConstants.bookingsCollection)
            .where('customerId', isEqualTo: userId)
            .get();

        for (var doc in bookingsQuery.docs) {
          await doc.reference.delete();
        }

        // Delete vendor's bookings
        final vendorBookingsQuery = await _firestore
            .collection(AppConstants.bookingsCollection)
            .where('technicianId', isEqualTo: userId)
            .get();

        for (var doc in vendorBookingsQuery.docs) {
          await doc.reference.delete();
        }

        // Delete user's notifications (if notifications collection exists)
        try {
          final notificationsQuery = await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: userId)
              .get();

          for (var doc in notificationsQuery.docs) {
            await doc.reference.delete();
          }
        } catch (e) {
          // Notifications collection might not exist
        }
      }

      // Delete user document
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .delete();

      // Delete Firebase Auth account
      await _auth.currentUser?.delete();

      // Sign out from Google
      await _googleSignIn.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
