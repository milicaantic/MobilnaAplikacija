import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/event_repository.dart';
import '../domain/event_status.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/data/user_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validation/app_validators.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          title: const Text('Admin Dashboard'),
          bottom: TabBar(
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Approvals'),
              Tab(icon: Icon(Icons.category_rounded), text: 'Categories'),
              Tab(icon: Icon(Icons.group_rounded), text: 'Users'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ApprovalQueue(),
            _CategoryQuickAccess(),
            _UserManagementView(),
          ],
        ),
      ),
    );
  }
}

class _UserManagementView extends ConsumerWidget {
  const _UserManagementView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);

    return usersAsync.when(
      data: (users) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final user = users[index];
          return Card(
            color: Theme.of(context).colorScheme.secondaryContainer.withValues(
              alpha: 0.22,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 23,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                onBackgroundImageError: (_, __) {},
                child: user.photoUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRoleColor(user.role).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      user.role.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<UserRole>(
                    initialValue: user.role,
                    onSelected: (role) async {
                      await ref
                          .read(userRepositoryProvider)
                          .updateUserRole(user.uid, role);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${user.name} to ${role.name}'),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => UserRole.values
                        .where((r) => r == UserRole.user || r == UserRole.admin)
                        .map(
                          (r) => PopupMenuItem(
                            value: r,
                            child: Text(r.name.toUpperCase()),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}

class _ApprovalQueue extends ConsumerWidget {
  const _ApprovalQueue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingEventsAsync = ref.watch(
      eventsStreamProvider(status: EventStatus.pending),
    );

    return pendingEventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.done_all_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'No events pending approval.',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              color: AppColors.warning.withValues(alpha: 0.12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('by ${event.creatorName}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.time),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => context.push('/events/${event.eventId}', extra: event),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

Color _getRoleColor(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppColors.warning;
    case UserRole.user:
      return AppColors.secondary;
    case UserRole.guest:
      return const Color(0xFF637381);
  }
}

class _CategoryQuickAccess extends ConsumerStatefulWidget {
  const _CategoryQuickAccess();

  @override
  ConsumerState<_CategoryQuickAccess> createState() =>
      _CategoryQuickAccessState();
}

class _CategoryQuickAccessState extends ConsumerState<_CategoryQuickAccess> {
  final _createCategoryFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addCategory() {
    if (!_createCategoryFormKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    ref.read(categoryRepositoryProvider).addCategory(name, description);
    _nameController.clear();
    _descriptionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category created.')),
    );
  }

  void _showCategoryDialog({
    required BuildContext context,
    required Category category,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.name);
    final descController = TextEditingController(text: category.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
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
              const SizedBox(height: 10),
              TextFormField(
                controller: descController,
                maxLength: AppValidators.descriptionMax,
                minLines: 2,
                maxLines: 3,
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
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int eventCount, String categoryId) {
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _createCategoryFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    maxLength: AppValidators.categoryNameMax,
                    validator: AppValidators.validateCategoryName,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    maxLength: AppValidators.descriptionMax,
                    minLines: 2,
                    maxLines: 3,
                    validator: AppValidators.validateDescription,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Existing Categories',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'No categories yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final category in categories)
                  Card(
                    child: ListTile(
                      title: Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(category.description),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showCategoryDialog(
                              context: context,
                              category: category,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: category.eventCount > 0
                                ? 'Cannot delete category with assigned events'
                                : 'Delete category',
                            onPressed: () =>
                                _confirmDelete(
                                  context,
                                  category.eventCount,
                                  category.categoryId,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(10),
            child: Text('Error: $err'),
          ),
        ),
      ],
    );
  }
}
