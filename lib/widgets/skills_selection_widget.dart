import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../constants/electrical_subcategories.dart';
import 'skill_chip.dart';
import 'electrical_sub_skills_section.dart';

class SkillsSelectionWidget extends StatefulWidget {
  final List<String>? initialSelectedSkills;
  final Function(List<String> skills) onSkillsChanged;

  const SkillsSelectionWidget({
    super.key,
    this.initialSelectedSkills,
    required this.onSkillsChanged,
  });

  @override
  State<SkillsSelectionWidget> createState() => _SkillsSelectionWidgetState();
}

class _SkillsSelectionWidgetState extends State<SkillsSelectionWidget> {
  late List<String> selectedSkills;
  late List<String> selectedSubSkills;

  @override
  void initState() {
    super.initState();
    // Initialize state with initial selected skills (handle null safely)
    final initialSkills = widget.initialSelectedSkills ?? [];
    selectedSkills = List.from(initialSkills);

    // Extract sub-skills from initial selection
    selectedSubSkills = initialSkills
        .where((skill) => _isElectricalSubSkill(skill))
        .toList();

    // Remove sub-skills from main skills list
    selectedSkills.removeWhere((skill) => _isElectricalSubSkill(skill));
  }

  bool _isElectricalSubSkill(String skillId) {
    // Handle empty subcategories gracefully
    if (electricalSubCategories.isEmpty) {
      return false;
    }
    return electricalSubCategories.any((sub) => sub.id == skillId);
  }

  void _toggleSkill(String skillId) {
    setState(() {
      if (selectedSkills.contains(skillId)) {
        selectedSkills.remove(skillId);

        // If electrical is deselected, clear all electrical sub-skills
        if (skillId == 'electrical') {
          selectedSubSkills.clear();
        }
      } else {
        selectedSkills.add(skillId);
      }

      // Notify parent of changes
      _notifySkillsChanged();
    });
  }

  void _notifySkillsChanged() {
    // Combine main skills and sub-skills
    final combinedSkills = [...selectedSkills, ...selectedSubSkills];
    widget.onSkillsChanged(combinedSkills);
  }

  void _toggleSubSkill(String subSkillId) {
    setState(() {
      if (selectedSubSkills.contains(subSkillId)) {
        selectedSubSkills.remove(subSkillId);
      } else {
        selectedSubSkills.add(subSkillId);
      }

      // Notify parent of changes
      _notifySkillsChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isElectricalSelected = selectedSkills.contains('electrical');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main skills grid
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AppConstants.serviceCategories.map((category) {
            final isSelected = selectedSkills.contains(category.id);
            return SkillChip(
              skillId: category.id,
              skillName: category.name,
              skillIcon: category.icon,
              isSelected: isSelected,
              onTap: () => _toggleSkill(category.id),
            );
          }).toList(),
        ),

        // Electrical sub-skills section (conditionally shown)
        if (isElectricalSelected) ...[
          const SizedBox(height: 24),
          ElectricalSubSkillsSection(
            selectedSubSkills: selectedSubSkills,
            onSubSkillToggle: _toggleSubSkill,
          ),
        ],
      ],
    );
  }
}
