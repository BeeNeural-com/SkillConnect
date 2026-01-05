import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/notification_model.dart';
import '../../../models/booking_model.dart';
import '../../customer/screens/booking_detail_screen.dart';
import '../../vendor/screens/booking_detail_vendor_screen.dart';
import '../../vendor/screens/booking_requests_screen.dart';
import '../../../providers/auth_provider.dart';
import 'chat_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Notifications'),
                  content: const Text(
                    'Are you sure you want to clear all notifications?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(clearAllNotificationsProvider)();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications cleared')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(
                context,
                ref,
                notification,
                currentUser?.role ?? '',
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading notifications: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when you have updates',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
    String userRole,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(deleteNotificationProvider)(notification.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: notification.isRead ? Colors.white : Colors.blue[50],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: Colors.white,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          onTap: () {
            // Mark as read
            if (!notification.isRead) {
              ref.read(markNotificationAsReadProvider)(notification.id);
            }

            // Navigate based on notification type
            _handleNotificationTap(context, notification, userRole);
          },
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationType.bookingRequest:
      case NotificationType.bookingAccepted:
      case NotificationType.bookingRejected:
      case NotificationType.bookingStarted:
      case NotificationType.bookingCompleted:
      case NotificationType.bookingCancelled:
        return Icons.work;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.newReview:
        return Icons.star;
      case NotificationType.paymentReceived:
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationType.bookingRequest:
        return Colors.blue;
      case NotificationType.bookingAccepted:
        return Colors.green;
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
        return Colors.red;
      case NotificationType.bookingStarted:
        return Colors.orange;
      case NotificationType.bookingCompleted:
        return Colors.teal;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.newReview:
        return Colors.amber;
      case NotificationType.paymentReceived:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    String userRole,
  ) async {
    final data = notification.data;
    if (data == null) return;

    switch (notification.type) {
      case NotificationType.bookingRequest:
        // For booking requests, vendors should go to booking requests screen
        if (userRole == 'vendor') {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookingRequestsScreen(),
              ),
            );
          }
        } else {
          // Customers see their booking detail
          final bookingId = data['bookingId'] as String?;
          if (bookingId != null) {
            try {
              final bookingDoc = await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .get();

              if (bookingDoc.exists && context.mounted) {
                final booking = BookingModel.fromFirestore(bookingDoc);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(booking: booking),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading booking: $e')),
                );
              }
            }
          }
        }
        break;

      case NotificationType.bookingAccepted:
      case NotificationType.bookingRejected:
      case NotificationType.bookingStarted:
      case NotificationType.bookingCompleted:
      case NotificationType.bookingCancelled:
        final bookingId = data['bookingId'] as String?;
        if (bookingId != null) {
          // Fetch booking data from Firestore
          try {
            final bookingDoc = await FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .get();

            if (bookingDoc.exists && context.mounted) {
              final booking = BookingModel.fromFirestore(bookingDoc);

              if (userRole == 'customer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingDetailScreen(booking: booking),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingDetailVendorScreen(booking: booking),
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error loading booking: $e')),
              );
            }
          }
        }
        break;

      case NotificationType.newMessage:
        final bookingId = data['bookingId'] as String?;
        final otherUserId = data['otherUserId'] as String?;
        final otherUserName = data['otherUserName'] as String?;

        if (bookingId != null && otherUserId != null && otherUserName != null) {
          // Fetch booking data for chat
          try {
            final bookingDoc = await FirebaseFirestore.instance
                .collection('bookings')
                .doc(bookingId)
                .get();

            if (bookingDoc.exists && context.mounted) {
              final booking = BookingModel.fromFirestore(bookingDoc);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    booking: booking,
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                  ),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error loading chat: $e')));
            }
          }
        }
        break;

      default:
        break;
    }
  }
}
