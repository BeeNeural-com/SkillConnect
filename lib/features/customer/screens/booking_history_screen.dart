import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../models/booking_model.dart';
import '../../shared/widgets/loading_widget.dart';
import 'booking_detail_screen.dart';

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          final bookingsAsync = ref.watch(userBookingsProvider(user.id));

          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              bookingsAsync.when(
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final booking = bookings[index];
                          return _BookingCard(booking: booking);
                        },
                        childCount: bookings.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: LoadingWidget(message: 'Loading bookings...'),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            color: AppTheme.primargityColor,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Booking History',
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Bookings Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your booking history will appear here',
              style: TextStyle(
                fontSize: 16,
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

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(booking: booking),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(),
                            _getStatusColor().withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getStatusIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceCategory,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  booking.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.location_on_rounded,
                        booking.address,
                        AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today_rounded,
                        DateFormat('MMM dd, yyyy').format(booking.scheduledDate),
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (booking.finalPrice != null)
                      _buildPriceChip(booking.finalPrice!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChip(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.attach_money_rounded,
            color: Colors.white,
            size: 16,
          ),
          Text(
            price.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case AppConstants.statusPending:
        return AppTheme.warningColor;
      case AppConstants.statusAccepted:
      case AppConstants.statusInProgress:
        return AppTheme.primaryColor;
      case AppConstants.statusCompleted:
        return AppTheme.successColor;
      case AppConstants.statusCancelled:
      case AppConstants.statusRejected:
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon() {
    switch (booking.status) {
      case AppConstants.statusPending:
        return Icons.schedule_rounded;
      case AppConstants.statusAccepted:
        return Icons.check_circle_rounded;
      case AppConstants.statusInProgress:
        return Icons.build_rounded;
      case AppConstants.statusCompleted:
        return Icons.done_all_rounded;
      case AppConstants.statusCancelled:
      case AppConstants.statusRejected:
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
