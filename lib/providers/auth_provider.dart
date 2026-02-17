import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Data Provider - Now properly invalidates on auth change
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authState = ref.watch(authStateProvider);
  
  // If not authenticated, return null
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      
      // Stream user data from Firestore
      return authService.getUserDataStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// Loading States
final loginLoadingProvider = StateProvider<bool>((ref) => false);
final registerLoadingProvider = StateProvider<bool>((ref) => false);

// Error States
final loginErrorProvider = StateProvider<String?>((ref) => null);
final registerErrorProvider = StateProvider<String?>((ref) => null);
