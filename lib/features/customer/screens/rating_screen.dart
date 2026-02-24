import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/booking_model.dart';
import '../../../models/review_model.dart';
import '../../../providers/auth_provider.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const RatingScreen({super.key, required this.booking});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Please select a rating'),
            ],
          ),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      debugPrint('🔍 Creating review for booking: ${widget.booking.id}');
      debugPrint(
        '   Booking technicianId (userId): ${widget.booking.technicianId}',
      );

      // Find the technician document ID from userId
      final technicianSnapshot = await FirebaseFirestore.instance
          .collection(AppConstants.techniciansCollection)
          .where('userId', isEqualTo: widget.booking.technicianId)
          .limit(1)
          .get();

      if (technicianSnapshot.docs.isEmpty) {
        debugPrint(
          '❌ Technician not found for userId: ${widget.booking.technicianId}',
        );
        throw Exception('Technician not found');
      }

      final technicianDocId = technicianSnapshot.docs.first.id;
      debugPrint('✅ Found technician document: $technicianDocId');

      final review = ReviewModel(
        id: '',
        bookingId: widget.booking.id,
        customerId: user.uid,
        technicianId: technicianDocId, // Use document ID for reviews
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        createdAt: DateTime.now(),
      );

      debugPrint('📝 Saving review with technicianId: $technicianDocId');

      // Add review to Firestore
      final reviewDoc = await FirebaseFirestore.instance
          .collection('reviews')
          .add(review.toMap());

      debugPrint('✅ Review saved with ID: ${reviewDoc.id}');

      // Update technician rating
      await _updateTechnicianRating(technicianDocId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Thank you for your review!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateTechnicianRating(String technicianDocId) async {
    try {
      debugPrint('📊 Updating rating for technician: $technicianDocId');

      // Get all reviews for this technician (using document ID)
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('technicianId', isEqualTo: technicianDocId)
          .get();

      debugPrint('   Found ${reviewsSnapshot.docs.length} reviews');

      if (reviewsSnapshot.docs.isEmpty) {
        debugPrint('   No reviews found, skipping rating update');
        return;
      }

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final rating = (doc.data()['rating'] ?? 0.0).toDouble();
        totalRating += rating;
        debugPrint('   Review ${doc.id}: rating=$rating');
      }
      final averageRating = totalRating / reviewsSnapshot.docs.length;

      debugPrint('   Average rating: $averageRating');
      debugPrint('   Total reviews: ${reviewsSnapshot.docs.length}');

      await FirebaseFirestore.instance
          .collection(AppConstants.techniciansCollection)
          .doc(technicianDocId)
          .update({
            'rating': averageRating,
            'totalReviews': reviewsSnapshot.docs.length,
            'updatedAt': Timestamp.now(),
          });

      debugPrint('✅ Rating updated successfully!');

      debugPrint('✅ Rating updated successfully!');
    } catch (e) {
      debugPrint('Error updating technician rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildRatingStars(),
                  const SizedBox(height: 20),
                  if (_rating > 0) _buildRatingText(),
                  const SizedBox(height: 40),
                  _buildCommentField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Rate Service',
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.booking.serviceCategory,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          final starValue = index + 1.0;
          return GestureDetector(
            onTap: () {
              setState(() => _rating = starValue);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                _rating >= starValue
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 56,
                color: _rating >= starValue
                    ? AppTheme.warningColor
                    : AppTheme.textSecondaryColor.withValues(alpha: 0.3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRatingText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withValues(alpha: 0.1),
            AppTheme.warningColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getEmoji(), size: 24, color: AppTheme.warningColor),
          const SizedBox(width: 8),
          Text(
            _getRatingText(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: TextField(
        controller: _commentController,
        decoration: InputDecoration(
          labelText: 'Add a comment (optional)',
          hintText: 'Tell us about your experience...',
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(Icons.comment_rounded, color: AppTheme.primaryColor),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          alignLabelWithHint: true,
        ),
        maxLines: 4,
        maxLength: 500,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 24),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Submit Review',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  IconData _getEmoji() {
    if (_rating == 5) return Icons.sentiment_very_satisfied_rounded;
    if (_rating == 4) return Icons.sentiment_satisfied_rounded;
    if (_rating == 3) return Icons.sentiment_neutral_rounded;
    if (_rating == 2) return Icons.sentiment_dissatisfied_rounded;
    return Icons.sentiment_very_dissatisfied_rounded;
  }

  String _getRatingText() {
    if (_rating == 5) return 'Excellent!';
    if (_rating == 4) return 'Good';
    if (_rating == 3) return 'Average';
    if (_rating == 2) return 'Poor';
    return 'Very Poor';
  }
}
