import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../data/event_repository.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/location_service.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../domain/comment.dart';
import '../domain/rating.dart';
import 'widgets/rating_dialog.dart';

class EventDetailsScreen extends ConsumerWidget {
  final String eventId;
  final EventModel? initialEvent;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the event stream for real-time updates (avg rating, etc.)
    final eventAsync = ref.watch(eventStreamProvider(eventId));
    final event = eventAsync.value ?? initialEvent;

    if (event == null) {
      if (eventAsync.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return const Scaffold(body: Center(child: Text('Event not found')));
    }

    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                ),
              ),
              background: Hero(
                tag: 'image-${event.eventId}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (event.imageUrl != null)
                      Image.network(event.imageUrl!, fit: BoxFit.cover)
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.event,
                          size: 80,
                          color: Colors.white24,
                        ),
                      ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(event.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(event.status),
                          ),
                        ),
                        child: Text(
                          event.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(event.status),
                          ),
                        ),
                      ),
                      if (isAdmin && event.status == EventStatus.pending)
                        Row(
                          children: [
                            IconButton.filled(
                              icon: const Icon(Icons.check),
                              onPressed: () => _moderate(
                                ref,
                                context,
                                event.eventId,
                                EventStatus.approved,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                            IconButton.filled(
                              icon: const Icon(Icons.close),
                              onPressed: () => _showRejectDialog(
                                context,
                                ref,
                                event.eventId,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _EventInfoSection(event: event),
                  const SizedBox(height: 32),
                  _buildInteractionButtons(context, ref, event, user),
                  const SizedBox(height: 32),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _WeatherInfo(location: event.location),
                  const SizedBox(height: 32),
                  _CommentSection(eventId: eventId),
                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    AppUser? user,
  ) {
    if (user == null) {
      return Center(
        child: Column(
          children: [
            const Text(
              'Sign in to add ratings, register and comment on this event.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Login / Register'),
            ),
          ],
        ),
      );
    }

    final isCreator = user.uid == event.creatorId;
    final isRegisteredAsync = ref.watch(
      isRegisteredStreamProvider(event.eventId, user.uid),
    );
    final userRatingAsync = ref.watch(
      userEventRatingStreamProvider(event.eventId, user.uid),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ref
                        .watch(eventRatingStatsStreamProvider(event.eventId))
                        .when(
                          data: (stats) => Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stats.average.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${stats.count} reviews',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text('No ratings'),
                        ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showRatingDialog(context, ref, event, user),
                icon: Icon(
                  userRatingAsync.value != null
                      ? Icons.star
                      : Icons.star_outline,
                ),
                label: Text(userRatingAsync.value != null ? 'Update' : 'Rate'),
              ),
            ],
          ),
          if (!isCreator) ...[
            const SizedBox(height: 20),
            isRegisteredAsync.when(
              data: (isRegistered) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      _toggleRegistration(ref, event, user, isRegistered),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: isRegistered
                        ? Colors.grey[200]
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: isRegistered
                        ? Colors.black87
                        : Theme.of(context).colorScheme.onPrimary,
                    elevation: isRegistered ? 0 : 4,
                  ),
                  child: Text(
                    isRegistered ? 'Unregister' : 'Register for Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error'),
            ),
          ],
          if (isCreator) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/events/${event.eventId}/participants'),
                icon: const Icon(Icons.people_outline),
                label: const Text('Manage Participants'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleRegistration(
    WidgetRef ref,
    EventModel event,
    AppUser user,
    bool isRegistered,
  ) {
    final repo = ref.read(eventRepositoryProvider);
    if (isRegistered) {
      repo.unregisterFromEvent(event.eventId, user.uid);
    } else {
      repo.registerForEvent(
        event.eventId,
        user.uid,
        user.name,
        userPhotoUrl: user.photoUrl,
        eventTitle: event.title,
        eventTime: event.time,
        locationName: event.location['name'],
      );
    }
  }

  void _showRatingDialog(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    AppUser user,
  ) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        onRatingSubmitted: (ratingValue) {
          ref
              .read(eventRepositoryProvider)
              .rateEvent(
                event.eventId,
                Rating(
                  userId: user.uid,
                  rating: ratingValue,
                  timestamp: DateTime.now(),
                ),
              );
        },
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.approved:
        return Colors.green;
      case EventStatus.rejected:
        return Colors.red;
    }
  }

  void _moderate(
    WidgetRef ref,
    BuildContext context,
    String id,
    EventStatus status, {
    String? reason,
  }) {
    final user = ref.read(currentUserProvider).value;
    ref
        .read(eventRepositoryProvider)
        .updateEventStatus(
          id,
          status,
          approvedBy: user?.uid,
          rejectedReason: reason,
        );
    context.pop();
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Event'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _moderate(
                ref,
                context,
                id,
                EventStatus.rejected,
                reason: reasonController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

class _EventInfoSection extends StatelessWidget {
  final EventModel event;
  const _EventInfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DetailRow(
              icon: Icons.calendar_month_outlined,
              label: 'Date & Time',
              value: _formatDate(event.time),
            ),
            const Divider(height: 32),
            DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: event.location['name'] ?? 'Online / TBD',
            ),
            const Divider(height: 32),
            DetailRow(
              icon: Icons.person_outline,
              label: 'Organizer',
              value: event.creatorName,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentSection extends ConsumerWidget {
  final String eventId;
  const _CommentSection({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(eventCommentsStreamProvider(eventId));
    final controller = TextEditingController();
    final user = ref.watch(currentUserProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Comments',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            commentsAsync.when(
              data: (comments) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  comments.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (user != null) ...[
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    ref
                        .read(eventRepositoryProvider)
                        .addComment(
                          eventId,
                          Comment(
                            commentId: '', // Firebase will generate
                            userId: user.uid,
                            userName: user.name,
                            userPhotoUrl: user.photoUrl,
                            text: controller.text,
                            createdAt: DateTime.now(),
                          ),
                        );
                    controller.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return const Center(child: Text('No comments yet.'));
            }

            final user = ref.watch(currentUserProvider).value;
            final isAdmin = user?.role == UserRole.admin;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isOwner = user?.uid == comment.userId;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: comment.userPhotoUrl != null
                        ? NetworkImage(comment.userPhotoUrl!)
                        : null,
                    child: comment.userPhotoUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(comment.userName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment.text),
                      Text(
                        comment.createdAt.toString().split('.')[0],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditCommentDialog(
                            context,
                            ref,
                            eventId,
                            comment,
                          ),
                        ),
                      if (isAdmin || isOwner)
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => ref
                              .read(eventRepositoryProvider)
                              .deleteComment(eventId, comment.commentId),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading comments: $e'),
        ),
      ],
    );
  }

  void _showEditCommentDialog(
    BuildContext context,
    WidgetRef ref,
    String eventId,
    Comment comment,
  ) {
    final controller = TextEditingController(text: comment.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Edit your comment...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(eventRepositoryProvider)
                    .updateComment(
                      eventId,
                      comment.copyWith(text: controller.text),
                    );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _WeatherInfo extends ConsumerWidget {
  final Map<String, dynamic> location;
  const _WeatherInfo({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lat = (location['lat'] as num?)?.toDouble();
    final lon = (location['lng'] as num?)?.toDouble();

    if (lat != null && lon != null) {
      return _WeatherDisplay(lat: lat, lon: lon);
    }

    final address = location['name'] as String?;
    if (address == null || address.isEmpty) return const SizedBox.shrink();

    // Use geocodeProvider (from location_service.dart) to fetch missing coordinates
    final coordsAsync = ref.watch(geocodeProvider(address));

    return coordsAsync.when(
      data: (coords) =>
          _WeatherDisplay(lat: coords['lat']!, lon: coords['lng']!),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Geocoding error: $err',
          style: const TextStyle(color: Colors.red, fontSize: 10),
        ),
      ),
    );
  }
}

class _WeatherDisplay extends ConsumerWidget {
  final double lat;
  final double lon;
  const _WeatherDisplay({required this.lat, required this.lon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider(lat: lat, lon: lon));

    return weatherAsync.when(
      data: (weather) {
        final temp = weather['main']['temp'];
        final description = weather['weather'][0]['description'];
        final icon = weather['weather'][0]['icon'];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Image.network(
                'https://openweathermap.org/img/wn/$icon@2x.png',
                width: 50,
                height: 50,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temp.toStringAsFixed(1)}°C',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description.toString().toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              const Text('Current Weather'),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Weather API error: $err',
          style: const TextStyle(color: Colors.red, fontSize: 10),
        ),
      ),
    );
  }
}
