class AppConstants {
  // App Info
  static const String appName = 'SkillConnect';
  static const String appVersion = '1.0.0';

  // Collections
  static const String usersCollection = 'users';
  static const String techniciansCollection = 'technicians';
  static const String bookingsCollection = 'bookings';
  static const String messagesCollection = 'messages';

  // Booking Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusInProgress = 'in_progress';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusRejected = 'rejected';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleVendor = 'vendor';

  // Service Categories
  static const List<ServiceCategory> serviceCategories = [
    ServiceCategory(
      id: 'plumbing',
      name: 'Plumbing',
      icon: '🔧',
      description: 'Pipe repairs, installations, and maintenance',
    ),
    ServiceCategory(
      id: 'electrical',
      name: 'Electrical',
      icon: '⚡',
      description: 'Wiring, repairs, and electrical installations',
    ),
    ServiceCategory(
      id: 'carpentry',
      name: 'Carpentry',
      icon: '🔨',
      description: 'Furniture repair and woodwork',
    ),
    ServiceCategory(
      id: 'painting',
      name: 'Painting',
      icon: '🎨',
      description: 'Interior and exterior painting services',
    ),
    ServiceCategory(
      id: 'cleaning',
      name: 'Cleaning',
      icon: '🧹',
      description: 'Home and office cleaning services',
    ),
    ServiceCategory(
      id: 'appliance',
      name: 'Appliance Repair',
      icon: '🔌',
      description: 'Repair of home appliances',
    ),
  ];

  // Helper method to get display name from category ID
  static String getCategoryDisplayName(String categoryId) {
    final category = serviceCategories.firstWhere(
      (cat) => cat.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => ServiceCategory(
        id: categoryId,
        name: categoryId.substring(0, 1).toUpperCase() + categoryId.substring(1),
        icon: '🔧',
        description: '',
      ),
    );
    return category.name;
  }

  // Limits
  static const int maxImagesPerRequest = 5;
  static const int maxDescriptionLength = 500;
  static const double maxSearchRadius = 50.0; // km
}

class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final String description;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}
