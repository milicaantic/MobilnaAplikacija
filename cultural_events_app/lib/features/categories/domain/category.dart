/// Represents an event category.
///
/// Maps to the `categories` top-level Firestore collection.
/// Only administrators can create, update, or delete categories.
class Category {
  final String categoryId;
  final String name;
  final String description;
  final bool isActive;

  const Category({
    required this.categoryId,
    required this.name,
    required this.description,
    this.isActive = true,
  });

  /// Creates a [Category] from a Firestore document snapshot.
  factory Category.fromJson(Map<String, dynamic> json, String categoryId) {
    return Category(
      categoryId: categoryId,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converts this [Category] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {'name': name, 'description': description, 'isActive': isActive};
  }
}
