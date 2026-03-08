import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../constants/electrical_subcategories.dart';
import 'skill_chip.dart';

/// Reusable bottom sheet for selecting electrical sub-categories
/// Used on customer dashboard when user taps the Electrical service card
class ElectricalSubCategoriesBottomSheet extends StatefulWidget {
  const ElectricalSubCategoriesBottomSheet({super.key});

  @override
  State<ElectricalSubCategoriesBottomSheet> createState() =>
      _ElectricalSubCategoriesBottomSheetState();
}

class _ElectricalSubCategoriesBottomSheetState
    extends State<ElectricalSubCategoriesBottomSheet> {
  // Track selected sub-skill IDs
  final List<String> _selectedSubSkills = [];

  void _toggleSubSkill(String subSkillId) {
    setState(() {
      if (_selectedSubSkills.contains(subSkillId)) {
        _selectedSubSkills.remove(subSkillId);
      } else {
        _selectedSubSkills.add(subSkillId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXl),
          topRight: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.secondaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.electric_bolt_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Electrical Service',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose your specialization',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Sub-categories chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: electricalSubCategories.map((subCategory) {
                final isSelected = _selectedSubSkills.contains(subCategory.id);
                return SkillChip(
                  skillId: subCategory.id,
                  skillName: subCategory.name,
                  skillIcon: subCategory.icon,
                  isSelected: isSelected,
                  onTap: () => _toggleSubSkill(subCategory.id),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Continue button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSubSkills.isEmpty
                    ? null
                    : () {
                        // Return selected sub-skills to caller
                        Navigator.pop(context, _selectedSubSkills);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  disabledBackgroundColor: AppTheme.textSecondaryColor
                      .withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: _selectedSubSkills.isEmpty ? 0 : 4,
                  shadowColor: _selectedSubSkills.isEmpty
                      ? Colors.transparent
                      : AppTheme.secondaryColor.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedSubSkills.isEmpty
                          ? 'Select at least one service'
                          : 'View Professionals (${_selectedSubSkills.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedSubSkills.isEmpty
                            ? AppTheme.textSecondaryColor
                            : Colors.white,
                      ),
                    ),
                    if (_selectedSubSkills.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
