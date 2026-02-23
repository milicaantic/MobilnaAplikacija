import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/event_repository.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../../categories/data/category_repository.dart';
import '../../../core/providers/current_user_provider.dart';

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

    final searchQuery = ref.watch(eventSearchQueryProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final eventsAsync = ref.watch(
      eventsStreamProvider(
        status:
            EventStatus.approved, 
        categoryId: selectedCategoryId,
        searchQuery: searchQuery,
      ),
    );

    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(118),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => ref
                                .read(eventSearchQueryProvider.notifier)
                                .setQuery(''),
                          )
                        : null,
                  ),
                  onChanged: (val) =>
                      ref.read(eventSearchQueryProvider.notifier).setQuery(val),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: categoriesAsync.when(
                  data: (categories) => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ChoiceChip(
                          label: const Text('All'),
                          selected: selectedCategoryId == null,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(selectedCategoryIdProvider.notifier)
                                  .setSelectedId(null);
                            }
                          },
                        );
                      }
                      final category = categories[index - 1];
                      return ChoiceChip(
                        label: Text(category.name),
                        selected: selectedCategoryId == category.categoryId,
                        onSelected: (selected) {
                          ref
                              .read(selectedCategoryIdProvider.notifier)
                              .setSelectedId(selected ? category.categoryId : null);
                        },
                      );
                    },
                  ),
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: eventsAsync.when(
        data: (events) => events.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No events found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try another keyword or change the selected category.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
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
      data: (cats) {
        for (final category in cats) {
          if (category.categoryId == event.categoryId) {
            return category.name;
          }
        }
        return 'General';
      },
      loading: () => '...',
      error: (_, __) => '',
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 240),
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/events/${event.eventId}', extra: event),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.imageUrl != null) ...[
                  Hero(
                    tag: 'image-${event.eventId}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        event.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        categoryName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(event.time),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Hero(
                  tag: 'title-${event.eventId}',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
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
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location['name'] ?? 'No location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        event.creatorName.isNotEmpty
                            ? event.creatorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'by ${event.creatorName}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
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
