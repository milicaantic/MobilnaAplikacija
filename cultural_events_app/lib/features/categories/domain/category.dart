
class Category {
  final String categoryId;
  final String name;
  final String description;
  final bool isActive;
  final int eventCount;

  const Category({
    required this.categoryId,
    required this.name,
    required this.description,
    this.isActive = true,
    this.eventCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json, String categoryId) {
    return Category(
      categoryId: categoryId,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'eventCount': eventCount,
    };
  }
}
