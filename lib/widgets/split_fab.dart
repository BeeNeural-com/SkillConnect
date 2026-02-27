import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A custom floating action button split into two halves
/// Left half: AI Assistant functionality
/// Right half: Reels functionality
class SplitFAB extends StatelessWidget {
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  const SplitFAB({
    super.key,
    required this.onLeftTap,
    required this.onRightTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 140, // Limit total width to make it more compact
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left half - AI Assistant
            Flexible(
              flex: 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onLeftTap,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Divider
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),

            // Right half - Reels
            Flexible(
              flex: 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRightTap,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(28),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    constraints: const BoxConstraints(
                      minWidth: 56,
                      minHeight: 56,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.video_library_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
