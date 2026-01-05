import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            _buildSection(
              '1. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
                  '• Name, email address, and phone number\n'
                  '• Profile information and photos\n'
                  '• Service preferences and booking history\n'
                  '• Location data when you use our services\n'
                  '• Payment information (processed securely)\n'
                  '• Communications between users',
            ),

            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Connect customers with technicians\n'
                  '• Process bookings and transactions\n'
                  '• Send notifications about your bookings\n'
                  '• Respond to your comments and questions\n'
                  '• Detect and prevent fraud or abuse',
            ),

            _buildSection(
              '3. Information Sharing',
              'We share your information only in the following circumstances:\n\n'
                  '• With technicians when you book a service\n'
                  '• With customers when you accept a booking\n'
                  '• With service providers who assist our operations\n'
                  '• When required by law or to protect our rights\n'
                  '• With your consent',
            ),

            _buildSection(
              '4. Location Information',
              'We collect and use location data to:\n\n'
                  '• Show nearby technicians to customers\n'
                  '• Help technicians find service locations\n'
                  '• Improve our service recommendations\n\n'
                  'You can control location permissions through your device settings.',
            ),

            _buildSection(
              '5. Data Security',
              'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),

            _buildSection(
              '6. Data Retention',
              'We retain your information for as long as your account is active or as needed to provide services. You may request deletion of your account and data at any time.',
            ),

            _buildSection(
              '7. Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate information\n'
                  '• Request deletion of your data\n'
                  '• Opt-out of marketing communications\n'
                  '• Export your data',
            ),

            _buildSection(
              '8. Children\'s Privacy',
              'Our service is not intended for users under the age of 18. We do not knowingly collect information from children under 18.',
            ),

            _buildSection(
              '9. Push Notifications',
              'We send push notifications about:\n\n'
                  '• New booking requests\n'
                  '• Booking status updates\n'
                  '• Messages from other users\n'
                  '• Important service announcements\n\n'
                  'You can disable notifications in your device settings.',
            ),

            _buildSection(
              '10. Cookies and Tracking',
              'We use cookies and similar technologies to improve your experience, analyze usage patterns, and personalize content.',
            ),

            _buildSection(
              '11. Changes to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last updated" date.',
            ),

            _buildSection(
              '12. Contact Us',
              'If you have questions about this Privacy Policy, please contact us through the app support section.',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Your privacy is important to us. We are committed to protecting your personal information and being transparent about our data practices.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
