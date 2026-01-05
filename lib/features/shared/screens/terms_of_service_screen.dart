import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Skill Connect, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, please do not use our service.',
            ),

            _buildSection(
              '2. Description of Service',
              'Skill Connect is a platform that connects customers with skilled technicians for various home services including plumbing, electrical work, carpentry, painting, AC repair, and cleaning services.',
            ),

            _buildSection(
              '3. User Accounts',
              'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            ),

            _buildSection(
              '4. User Conduct',
              'You agree not to:\n\n'
                  '• Use the service for any illegal purpose\n'
                  '• Harass, abuse, or harm another person\n'
                  '• Provide false or misleading information\n'
                  '• Impersonate any person or entity\n'
                  '• Interfere with or disrupt the service',
            ),

            _buildSection(
              '5. Service Bookings',
              'Customers can book services through the platform. Technicians have the right to accept or reject booking requests. All service agreements are between the customer and the technician.',
            ),

            _buildSection(
              '6. Payments',
              'Payment terms are agreed upon between customers and technicians. Skill Connect is not responsible for payment disputes between users. All transactions should be conducted in accordance with local laws.',
            ),

            _buildSection(
              '7. Reviews and Ratings',
              'Users may leave reviews and ratings for services received. Reviews must be honest and based on actual experiences. We reserve the right to remove reviews that violate our guidelines.',
            ),

            _buildSection(
              '8. Technician Verification',
              'While we strive to verify technician credentials, we do not guarantee the quality of services provided. Customers should exercise their own judgment when selecting technicians.',
            ),

            _buildSection(
              '9. Limitation of Liability',
              'Skill Connect is not liable for any damages arising from the use of our service or from any services provided by technicians. We act solely as a platform connecting users.',
            ),

            _buildSection(
              '10. Termination',
              'We reserve the right to terminate or suspend your account at any time for violations of these terms or for any other reason at our sole discretion.',
            ),

            _buildSection(
              '11. Changes to Terms',
              'We reserve the right to modify these terms at any time. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),

            _buildSection(
              '12. Contact Information',
              'For questions about these Terms of Service, please contact us through the app support section.',
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'By using Skill Connect, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
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
