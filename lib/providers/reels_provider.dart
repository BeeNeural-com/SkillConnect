import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/reel_model.dart';
import '../services/reels_service.dart';

/// Provider for ReelsService instance
final reelsServiceProvider = Provider<ReelsService>((ref) {
  return ReelsService();
});

/// Provider for fetching all reels
final reelsProvider = FutureProvider<List<Reel>>((ref) async {
  final service = ref.watch(reelsServiceProvider);
  return service.fetchReels();
});

/// Provider for streaming reels in real-time
final reelsStreamProvider = StreamProvider<List<Reel>>((ref) {
  final service = ref.watch(reelsServiceProvider);
  return service.getReelsStream();
});

/// Provider for tracking the current reel index
final currentReelIndexProvider = StateProvider<int>((ref) => 0);

/// Provider for fetching reels by category
final reelsByCategoryProvider = FutureProvider.family<List<Reel>, String>((
  ref,
  category,
) async {
  final service = ref.watch(reelsServiceProvider);
  return service.fetchReelsByCategory(category);
});

/// Provider for fetching reels by vendor
final reelsByVendorProvider = FutureProvider.family<List<Reel>, String>((
  ref,
  vendorId,
) async {
  final service = ref.watch(reelsServiceProvider);
  return service.fetchReelsByVendor(vendorId);
});

/// Provider for fetching a single reel by ID
final reelByIdProvider = FutureProvider.family<Reel?, String>((
  ref,
  reelId,
) async {
  final service = ref.watch(reelsServiceProvider);
  return service.getReelById(reelId);
});
