import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class ChatbotSettingsScreen extends StatelessWidget {
  const ChatbotSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Chatbot Setup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowMd,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI-Powered Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Powered by Google Gemini',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Setup Instructions
            const Text('Setup Instructions', style: AppTheme.h4),
            const SizedBox(height: 16),

            _buildStepCard(
              step: '1',
              title: 'Get Free API Key',
              description: 'Visit Google AI Studio to create your free API key',
              action: 'Open AI Studio',
              onTap: () {
                _showUrlDialog(
                  context,
                  'https://makersuite.google.com/app/apikey',
                );
              },
            ),

            const SizedBox(height: 12),

            _buildStepCard(
              step: '2',
              title: 'Copy Your API Key',
              description: 'Sign in with Google and click "Create API Key"',
              icon: Icons.key_rounded,
            ),

            const SizedBox(height: 12),

            _buildStepCard(
              step: '3',
              title: 'Add to .env File',
              description:
                  'Open .env file in project root and replace YOUR_GEMINI_API_KEY_HERE with your key',
              icon: Icons.edit_rounded,
            ),

            const SizedBox(height: 24),

            // Features
            const Text('Features', style: AppTheme.h4),
            const SizedBox(height: 16),

            _buildFeatureCard(
              icon: Icons.psychology_rounded,
              title: 'Natural Conversations',
              description:
                  'AI understands context and provides intelligent responses',
              color: AppTheme.primaryColor,
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.history_rounded,
              title: 'Conversation Memory',
              description: 'Remembers chat history for better context',
              color: AppTheme.secondaryColor,
            ),

            const SizedBox(height: 12),

            _buildFeatureCard(
              icon: Icons.speed_rounded,
              title: 'Smart Fallback',
              description: 'Works even without API key using pattern matching',
              color: AppTheme.accentColor,
            ),

            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'The chatbot works without an API key but responses will be less conversational. Add your key to .env file for the best experience!',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimaryColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    // In a real implementation, you'd check if API key is configured
    final isConfigured = false; // This would be dynamic

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  (isConfigured ? AppTheme.successColor : AppTheme.warningColor)
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isConfigured ? Icons.check_circle_rounded : Icons.warning_rounded,
              color: isConfigured
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? 'AI Enabled' : 'API Key Not Configured',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConfigured
                      ? 'Chatbot is using AI responses'
                      : 'Using fallback mode',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required String description,
    String? action,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: icon != null
                        ? Icon(icon, color: Colors.white, size: 20)
                        : Text(
                            step,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                          height: 1.3,
                        ),
                      ),
                      if (action != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          action,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUrlDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open in Browser'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Copy this URL and open it in your browser:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('URL copied to clipboard!')),
              );
            },
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
