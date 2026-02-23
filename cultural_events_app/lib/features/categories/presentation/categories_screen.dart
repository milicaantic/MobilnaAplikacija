import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/category.dart';
import '../data/category_repository.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validation/app_validators.dart';
import '../../auth/domain/user_role.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Categories')),
      body: categoriesAsync.when(
        data: (categories) => categories.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 58,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    const Text('No categories found'),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(category.description),
                      ),
                      trailing: isAdmin
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _showCategoryDialog(
                                    context,
                                    ref,
                                    category: category,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  tooltip: category.eventCount > 0
                                      ? 'Cannot delete category with assigned events'
                                      : 'Delete category',
                                  onPressed: () => _confirmDelete(
                                    context,
                                    ref,
                                    category.eventCount,
                                    category.categoryId,
                                  ),
                                ),
                              ],
                            )
                          : category.isActive
                          ? null
                          : Icon(
                              Icons.block,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showCategoryDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    Category? category,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                maxLength: AppValidators.categoryNameMax,
                validator: AppValidators.validateCategoryName,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextFormField(
                controller: descController,
                minLines: 2,
                maxLines: 3,
                maxLength: AppValidators.descriptionMax,
                validator: AppValidators.validateDescription,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              if (category == null) {
                ref
                    .read(categoryRepositoryProvider)
                    .addCategory(
                      nameController.text.trim(),
                      descController.text.trim(),
                    );
              } else {
                ref
                    .read(categoryRepositoryProvider)
                    .updateCategory(
                      Category(
                        categoryId: category.categoryId,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        isActive: category.isActive,
                        eventCount: category.eventCount,
                      ),
                    );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int eventCount,
    String categoryId,
  ) {
    if (eventCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This category cannot be deleted because there are events assigned to it.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger.withValues(alpha: 0.14),
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: () async {
              try {
                await ref.read(categoryRepositoryProvider).deleteCategory(categoryId);
                if (context.mounted) Navigator.pop(context);
              } catch (_) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This category cannot be deleted because there are events assigned to it.',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
