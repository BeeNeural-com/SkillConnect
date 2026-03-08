class SubCategory {
  final String id;
  final String name;
  final String icon;
  final String parentSkillId;

  const SubCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.parentSkillId,
  });

  // Create SubCategory from Firestore JSON
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      parentSkillId: json['parentSkillId'] as String,
    );
  }

  // Convert SubCategory to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'parentSkillId': parentSkillId,
    };
  }
}
