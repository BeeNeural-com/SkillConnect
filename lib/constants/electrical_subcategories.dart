import '../models/sub_category.dart';

const List<SubCategory> electricalSubCategories = [
  SubCategory(
    id: 'electrical_wiring',
    name: 'Electrical Wiring',
    icon: '🔌',
    parentSkillId: 'electrical',
  ),
  SubCategory(
    id: 'electrical_appliance_repair',
    name: 'Electrical Appliance Repair',
    icon: '🔧',
    parentSkillId: 'electrical',
  ),
  SubCategory(
    id: 'solar_installation',
    name: 'Solar Installation / Repair',
    icon: '☀️',
    parentSkillId: 'electrical',
  ),
];
