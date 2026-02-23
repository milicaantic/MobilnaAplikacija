import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/category.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Category>> watchCategories() {
    return _firestore
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addCategory(String name, String description) async {
    await _firestore.collection('categories').add({
      'name': name,
      'description': description,
      'isActive': true,
      'eventCount': 0,
    });
  }

  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection('categories')
        .doc(category.categoryId)
        .update(category.toJson());
  }

  Future<void> deleteCategory(String categoryId) async {
    final hasEvents = await _firestore
        .collection('events')
        .where('categoryId', isEqualTo: categoryId)
        .limit(1)
        .get()
        .then((snapshot) => snapshot.docs.isNotEmpty);

    if (hasEvents) {
      throw Exception(
        'This category cannot be deleted because there are events assigned to it.',
      );
    }

    await _firestore.collection('categories').doc(categoryId).delete();
  }
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  return CategoryRepository();
}

@riverpod
Stream<List<Category>> categoriesStream(Ref ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
}
