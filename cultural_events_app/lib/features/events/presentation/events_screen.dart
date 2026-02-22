import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/event_repository.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../../categories/data/category_repository.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../auth/domain/user_role.dart';

part 'events_screen.g.dart';

@riverpod
class EventSearchQuery extends _$EventSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

@riverpod
class SelectedCategoryId extends _$SelectedCategoryId {
  @override
  String? build() => null;

  void setSelectedId(String? id) => state = id;
}

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.value?.role == UserRole.admin;

    final searchQuery = ref.watch(eventSearchQueryProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    final eventsAsync = ref.watch(
      eventsStreamProvider(
        status:
            EventStatus.approved, // Always show only approved events publicly
        categoryId: selectedCategoryId,
        searchQuery: searchQuery,
      ),
    );

    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultural Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) =>
                      ref.read(eventSearchQueryProvider.notifier).setQuery(val),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: categoriesAsync.when(
                  data: (categories) => ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedCategoryId == null,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(selectedCategoryIdProvider.notifier)
                                  .setSelectedId(null);
                            }
                          },
                        ),
                      ),
                      ...categories
                          .map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(c.name),
                                selected: selectedCategoryId == c.categoryId,
                                onSelected: (selected) {
                                  ref
                                      .read(selectedCategoryIdProvider.notifier)
                                      .setSelectedId(
                                        selected ? c.categoryId : null,
                                      );
                                },
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () => context.push('/categories'),
            ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => events.isEmpty
            ? const Center(
                child: Text('No events found matching your criteria.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _EventCard(event: events[index]);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: userAsync.when(
        data: (user) => user != null
            ? FloatingActionButton(
                onPressed: () => context.push('/create-event'),
                child: const Icon(Icons.add),
              )
            : null,
        error: (_, __) => null,
        loading: () => null,
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categoryName = categoriesAsync.when(
      data: (cats) =>
          cats.firstWhere((c) => c.categoryId == event.categoryId).name,
      loading: () => '...',
      error: (_, __) => '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/events/${event.eventId}', extra: event),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.imageUrl != null) ...[
                  Hero(
                    tag: 'image-${event.eventId}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        event.imageUrl!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(event.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Hero(
                  tag: 'title-${event.eventId}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location['name'] ?? 'No location',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(0.1),
                      child: Text(
                        event.creatorName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'by ${event.creatorName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format: Feb 22, 19:00
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
