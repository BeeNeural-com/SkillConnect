import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../constants/electrical_subcategories.dart';
import 'skill_chip.dart';

class ElectricalSubSkillsSection extends StatelessWidget {
  final List<String> selectedSubSkills;
  final Function(String subSkillId) onSubSkillToggle;

  const ElectricalSubSkillsSection({
    super.key,
    required this.selectedSubSkills,
    required this.onSubSkillToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty subcategories gracefully
    if (electricalSubCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.electric_bolt_rounded,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: const Text(
                'Electrical Specializations',
                style: AppTheme.h3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: electricalSubCategories.map((subCategory) {
            final isSelected = selectedSubSkills.contains(subCategory.id);
            return SkillChip(
              skillId: subCategory.id,
              skillName: subCategory.name,
              skillIcon: subCategory.icon,
              isSelected: isSelected,
              onTap: () => onSubSkillToggle(subCategory.id),
            );
          }).toList(),
        ),
      ],
    );
  }
}
