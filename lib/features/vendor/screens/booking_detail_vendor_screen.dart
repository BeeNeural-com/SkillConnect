import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/booking_model.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../shared/screens/chat_screen.dart';

class BookingDetailVendorScreen extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingDetailVendorScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailVendorScreen> createState() =>
      _BookingDetailVendorScreenState();
}

class _BookingDetailVendorScreenState
    extends ConsumerState<BookingDetailVendorScreen> {
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.booking.estimatedPrice != null) {
      _priceController.text = widget.booking.estimatedPrice!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .doc(widget.booking.id)
          .update({'status': newStatus, 'updatedAt': Timestamp.now()});

      // Send notification to customer
      try {
        await ref
            .read(notificationServiceProvider)
            .sendNotificationToUser(
              userId: widget.booking.customerId,
              title: 'Booking Status Updated',
              body:
                  'Your ${widget.booking.serviceCategory} booking is now ${newStatus.toUpperCase()}',
              type: NotificationType.bookingStarted,
              data: {'bookingId': widget.booking.id},
            );
      } catch (e) {
        debugPrint('Error sending notification: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Status updated to ${newStatus.toUpperCase()}'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _updatePrice() async {
    final price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .doc(widget.booking.id)
          .update({'estimatedPrice': price, 'updatedAt': Timestamp.now()});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Price updated successfully'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markComplete() async {
    final price = double.tryParse(_priceController.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set the final price')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .doc(widget.booking.id)
          .update({
            'status': AppConstants.statusCompleted,
            'finalPrice': price,
            'updatedAt': Timestamp.now(),
          });

      // Send notification to customer
      try {
        await ref
            .read(notificationServiceProvider)
            .sendNotificationToUser(
              userId: widget.booking.customerId,
              title: 'Booking Completed',
              body:
                  'Your ${widget.booking.serviceCategory} service has been completed. Final price: \$${price.toStringAsFixed(2)}',
              type: NotificationType.bookingCompleted,
              data: {'bookingId': widget.booking.id},
            );
      } catch (e) {
        debugPrint('Error sending notification: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Booking marked as completed!'),
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
            child: Column(
              children: [
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildServiceInfo(),
                const SizedBox(height: 16),
                _buildDetailsCard(),
                if (widget.booking.imageUrls.isNotEmpty)
                  const SizedBox(height: 16),
                if (widget.booking.imageUrls.isNotEmpty) _buildPhotosSection(),
                const SizedBox(height: 16),
                _buildPricingSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
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
            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Booking Details',
        style: TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        if (widget.booking.status == AppConstants.statusAccepted ||
            widget.booking.status == AppConstants.statusInProgress)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    booking: widget.booking,
                    otherUserId: widget.booking.customerId,
                    otherUserName: 'Customer',
                  ),
                ),
              );
            },
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getStatusColor(), _getStatusColor().withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(), color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.home_repair_service_rounded,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('Service Information', style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppTheme.secondaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.build_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.serviceCategory,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.booking.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('Booking Details', style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.location_on_rounded,
                  'Address',
                  widget.booking.address,
                  AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  'Scheduled Date',
                  DateFormat(
                    'MMM dd, yyyy - hh:mm a',
                  ).format(widget.booking.scheduledDate),
                  AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('Photos', style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.booking.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                    image: DecorationImage(
                      image: NetworkImage(widget.booking.imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payments_rounded,
                color: AppTheme.secondaryColor,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('Pricing', style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.dividerColor),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Price (\$)',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.attach_money_rounded,
                          color: AppTheme.successColor,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _updatePrice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Update Price',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (widget.booking.status == AppConstants.statusAccepted)
            Container(
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
                onPressed: () => _updateStatus(AppConstants.statusInProgress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text(
                  'Start Work',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          if (widget.booking.status == AppConstants.statusInProgress)
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _markComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                icon: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'Mark as Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.booking.status) {
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
    switch (widget.booking.status) {
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

  String _getStatusMessage() {
    switch (widget.booking.status) {
      case AppConstants.statusPending:
        return 'Waiting for your response';
      case AppConstants.statusAccepted:
        return 'Ready to start work';
      case AppConstants.statusInProgress:
        return 'Work is in progress';
      case AppConstants.statusCompleted:
        return 'Service completed successfully';
      case AppConstants.statusCancelled:
        return 'Booking was cancelled';
      case AppConstants.statusRejected:
        return 'You rejected this request';
      default:
        return '';
    }
  }
}
