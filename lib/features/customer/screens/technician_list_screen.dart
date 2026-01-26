import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/booking_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/technician_model.dart';
import '../../shared/widgets/loading_widget.dart';
import 'technician_profile_screen.dart';

class TechnicianListScreen extends ConsumerStatefulWidget {
  final String serviceCategory;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final DateTime scheduledDate;

  const TechnicianListScreen({
    super.key,
    required this.serviceCategory,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.scheduledDate,
  });

  @override
  ConsumerState<TechnicianListScreen> createState() =>
      _TechnicianListScreenState();
}

class _TechnicianListScreenState extends ConsumerState<TechnicianListScreen> {
  String _searchQuery = '';
  double _minRating = 0.0;
  bool _availableOnly = false;
  String _sortBy = 'default'; // default, rating, reviews

  Future<void> _createBooking(
    BuildContext context,
    WidgetRef ref,
    String technicianId,
  ) async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      // Check for duplicate pending bookings
      final existingBookings = await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('customerId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: technicianId)
          .where('serviceCategory', isEqualTo: widget.serviceCategory)
          .where(
            'status',
            whereIn: [
              AppConstants.statusPending,
              AppConstants.statusAccepted,
              AppConstants.statusInProgress,
            ],
          )
          .get();

      if (existingBookings.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You already have an active booking with this technician for this service',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      final booking = BookingModel(
        id: '',
        customerId: user.uid,
        technicianId: technicianId,
        serviceCategory: widget.serviceCategory,
        description: widget.description,
        status: AppConstants.statusPending,
        imageUrls: widget.imageUrls,
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        scheduledDate: widget.scheduledDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .add(booking.toMap());

      // Send notification to vendor
      try {
        await ref
            .read(notificationServiceProvider)
            .sendNotificationToUser(
              userId: technicianId,
              title: 'New Booking Request',
              body: 'You have a new ${widget.serviceCategory} request',
              type: NotificationType.bookingRequest,
              data: {'bookingId': docRef.id},
            );
        print('✓ Notification sent to technician: $technicianId');
      } catch (e) {
        print('Error sending notification: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Booking request sent successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<bool> _hasActiveBooking(String technicianId) async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return false;

      final existingBookings = await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('customerId', isEqualTo: user.uid)
          .where('technicianId', isEqualTo: technicianId)
          .where('serviceCategory', isEqualTo: widget.serviceCategory)
          .where(
            'status',
            whereIn: [
              AppConstants.statusPending,
              AppConstants.statusAccepted,
              AppConstants.statusInProgress,
            ],
          )
          .limit(1)
          .get();

      return existingBookings.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  List<DocumentSnapshot> _filterAndSortTechnicians(
    List<DocumentSnapshot> technicians,
  ) {
    var filtered = technicians.where((tech) {
      final data = tech.data() as Map<String, dynamic>;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final skills = (data['skills'] as List?)?.join(' ').toLowerCase() ?? '';
        final description =
            (data['description'] as String?)?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        if (!skills.contains(query) && !description.contains(query)) {
          return false;
        }
      }

      // Rating filter
      final rating = (data['rating'] ?? 0.0).toDouble();
      if (rating < _minRating) {
        return false;
      }

      // Availability filter
      if (_availableOnly && !(data['isAvailable'] ?? false)) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    if (_sortBy == 'rating') {
      filtered.sort((a, b) {
        final ratingA = ((a.data() as Map)['rating'] ?? 0.0).toDouble();
        final ratingB = ((b.data() as Map)['rating'] ?? 0.0).toDouble();
        return ratingB.compareTo(ratingA);
      });
    } else if (_sortBy == 'reviews') {
      filtered.sort((a, b) {
        final reviewsA = ((a.data() as Map)['totalReviews'] ?? 0) as int;
        final reviewsB = ((b.data() as Map)['totalReviews'] ?? 0) as int;
        return reviewsB.compareTo(reviewsA);
      });
    }

    return filtered;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Minimum Rating: ${_minRating.toStringAsFixed(1)} ⭐',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
                    thumbColor: AppTheme.primaryColor,
                    overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: _minRating.toStringAsFixed(1),
                    onChanged: (value) {
                      setModalState(() => _minRating = value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Available Only',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text('Show only available technicians'),
                    value: _availableOnly,
                    activeColor: AppTheme.successColor,
                    onChanged: (value) {
                      setModalState(() => _availableOnly = value);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _minRating = 0.0;
                            _availableOnly = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Refresh main screen
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [_buildSearchBar(), const SizedBox(height: 16)],
            ),
          ),
          _buildTechnicianList(),
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
            color: AppTheme.primaryColor.withOpacity(0.1),
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
        'Available Technicians',
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sort_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          onSelected: (value) {
            setState(() => _sortBy = value);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'default',
              child: Row(
                children: [
                  Icon(Icons.list_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Default'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rating',
              child: Row(
                children: [
                  Icon(Icons.star_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Highest Rating'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reviews',
              child: Row(
                children: [
                  Icon(Icons.reviews_rounded, size: 20),
                  SizedBox(width: 12),
                  Text('Most Reviews'),
                ],
              ),
            ),
          ],
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          onPressed: _showFilterSheet,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search by skills or description...',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.search_rounded, color: AppTheme.primaryColor),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildTechnicianList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.techniciansCollection)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: LoadingWidget(message: 'Loading technicians...'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No Technicians Found',
              message: 'No technicians available',
            ),
          );
        }

        // Filter technicians by service category
        final categoryLower = widget.serviceCategory.toLowerCase();
        final matchingTechnicians = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final skills = (data['skills'] as List?)?.cast<String>() ?? [];

          // Check if any skill matches the service category (case-insensitive)
          return skills.any(
            (skill) =>
                skill.toLowerCase() == categoryLower ||
                skill.toLowerCase().contains(categoryLower) ||
                categoryLower.contains(skill.toLowerCase()),
          );
        }).toList();

        if (matchingTechnicians.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.person_search_rounded,
              title: 'No Technicians Found',
              message: 'No technicians available for this service',
            ),
          );
        }

        final filteredTechnicians = _filterAndSortTechnicians(
          matchingTechnicians,
        );

        if (filteredTechnicians.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.filter_alt_off_rounded,
              title: 'No Results',
              message: 'No technicians match your filters',
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final tech = filteredTechnicians[index];
              final data = tech.data() as Map<String, dynamic>;
              return _buildTechnicianCard(tech, data);
            }, childCount: filteredTechnicians.length),
          ),
        );
      },
    );
  }

  Widget _buildTechnicianCard(
    DocumentSnapshot tech,
    Map<String, dynamic> data,
  ) {
    final rating = (data['rating'] ?? 0.0).toDouble();
    final totalReviews = data['totalReviews'] ?? 0;
    final isAvailable = data['isAvailable'] ?? false;
    final techData = tech.data() as Map<String, dynamic>;
    final userId = techData['userId'] as String;

    return FutureBuilder<bool>(
      future: _hasActiveBooking(userId),
      builder: (context, snapshot) {
        final hasActiveBooking = snapshot.data ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.shadowMd,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppTheme.warningColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.warningColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($totalReviews reviews)',
                                style: const TextStyle(
                                  color: AppTheme.textSecondaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 14,
                                  color: isAvailable
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isAvailable
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasActiveBooking) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active booking exists',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  data['description'] ?? 'Experienced technician',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.work_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Experience: ${data['experience'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final technician = TechnicianModel.fromFirestore(
                            tech,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TechnicianProfileScreen(
                                technician: technician,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                        icon: const Icon(Icons.person_rounded, size: 18),
                        label: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: hasActiveBooking
                          ? Container(
                              decoration: BoxDecoration(
                                color: AppTheme.dividerColor,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  disabledBackgroundColor: Colors.transparent,
                                ),
                                icon: const Icon(Icons.block_rounded, size: 18),
                                label: const Text('Booked'),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _createBooking(context, ref, userId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                icon: const Icon(Icons.send_rounded, size: 18),
                                label: const Text('Request'),
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
