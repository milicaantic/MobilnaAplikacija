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
import '../../../core/validation/app_validators.dart';
import '../../../core/theme/app_colors.dart';

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
    final isOwner = user?.uid == event.creatorId;
    final canEditEvent = isOwner || isAdmin;
    final canDeleteEvent = isOwner || isAdmin;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 320,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
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
                  if (context.canPop())
                    Positioned(
                      left: 8,
                      top: MediaQuery.of(context).padding.top + 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Colors.white,
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    start: 68,
                    end: 18,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.46),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
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
                      if (canDeleteEvent ||
                          canEditEvent ||
                          (isAdmin && event.status == EventStatus.pending))
                        Row(
                          children: [
                            if (canEditEvent)
                              IconButton.filledTonal(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit event',
                                onPressed: () => context.push(
                                  '/create-event?editId=${event.eventId}',
                                  extra: event,
                                ),
                              ),
                            if (canEditEvent &&
                                (canDeleteEvent ||
                                    (isAdmin && event.status == EventStatus.pending)))
                              const SizedBox(width: 8),
                            if (canDeleteEvent)
                              IconButton.outlined(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete event',
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                ),
                                onPressed: () => _confirmDeleteEvent(
                                  context,
                                  ref,
                                  event,
                                  user,
                                ),
                              ),
                            if (canDeleteEvent &&
                                isAdmin &&
                                event.status == EventStatus.pending)
                              const SizedBox(width: 8),
                            if (isAdmin && event.status == EventStatus.pending)
                              IconButton.outlined(
                                icon: const Icon(Icons.check),
                                onPressed: () => _moderate(
                                  ref,
                                  context,
                                  event.eventId,
                                  EventStatus.approved,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.success.withValues(alpha: 0.14),
                                  foregroundColor: AppColors.success,
                                  side: const BorderSide(color: AppColors.success),
                                ),
                                tooltip: 'Approve event',
                              ),
                            if (isAdmin && event.status == EventStatus.pending)
                              const SizedBox(width: 8),
                            if (isAdmin && event.status == EventStatus.pending)
                              IconButton.outlined(
                                icon: const Icon(Icons.close),
                                onPressed: () => _showRejectDialog(
                                  context,
                                  ref,
                                  event.eventId,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.danger.withValues(alpha: 0.14),
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                ),
                                tooltip: 'Reject event',
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _EventOverviewSection(event: event),
                  const SizedBox(height: 20),
                  _WeatherInfo(location: event.location),
                  const SizedBox(height: 28),
                  _buildInteractionButtons(context, ref, event, user),
                  const SizedBox(height: 32),
                  _CommentSection(eventId: eventId, event: event),
                  const SizedBox(height: 54),
                ],
              ),
            ),
          ],
        ),
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
      return Card(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(
          alpha: 0.45,
        ),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in to add ratings, register and comment on this event.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => context.push('/login'),
                icon: const Icon(Icons.login_outlined),
                label: const Text('Login / Register'),
              ),
            ],
          ),
        ),
      );
    }

    final isCreator = user.uid == event.creatorId;
    final canInteract = event.status == EventStatus.approved;
    final isRegisteredAsync = ref.watch(
      isRegisteredStreamProvider(event.eventId, user.uid),
    );
    final userRatingAsync = ref.watch(
      userEventRatingStreamProvider(event.eventId, user.uid),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        ref
                            .watch(eventRatingStatsStreamProvider(event.eventId))
                            .when(
                              data: (stats) => Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppColors.warning,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stats.average.toStringAsFixed(1),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
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
                    onPressed: canInteract
                        ? () => _showRatingDialog(context, ref, event, user)
                        : null,
                    icon: Icon(
                      userRatingAsync.value != null
                          ? Icons.star
                          : Icons.star_outline,
                    ),
                    label: Text(userRatingAsync.value != null ? 'Update' : 'Rate'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isCreator ? 'Participants' : 'Registration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isCreator)
                    isRegisteredAsync.when(
                      data: (isRegistered) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canInteract
                              ? () => _toggleRegistration(
                                    context,
                                    ref,
                                    event,
                                    user,
                                    isRegistered,
                                  )
                              : null,
                          icon: Icon(
                            isRegistered
                                ? Icons.event_busy_outlined
                                : Icons.event_available_outlined,
                          ),
                          style: isRegistered
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                )
                              : null,
                          label: Text(
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
                  if (isCreator)
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
              ),
            ),
          ),
      ],
    );
  }

  void _toggleRegistration(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    AppUser user,
    bool isRegistered,
  ) async {
    final repo = ref.read(eventRepositoryProvider);
    try {
      if (isRegistered) {
        await repo.unregisterFromEvent(event.eventId, user.uid);
      } else {
        await repo.registerForEvent(
          event.eventId,
          user.uid,
          user.name,
          userPhotoUrl: user.photoUrl,
          eventTitle: event.title,
          eventTime: event.time,
          locationName: event.location['name'],
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
      }
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
        onRatingSubmitted: (ratingValue) async {
          try {
            await ref
                .read(eventRepositoryProvider)
                .rateEvent(
                  event.eventId,
                  Rating(
                    userId: user.uid,
                    rating: ratingValue,
                    timestamp: DateTime.now(),
                  ),
                );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Rating failed: $e')));
            }
          }
        },
      ),
    );
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return AppColors.warning;
      case EventStatus.approved:
        return AppColors.success;
      case EventStatus.rejected:
        return AppColors.danger;
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
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Event'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            minLines: 2,
            maxLines: 4,
            maxLength: AppValidators.descriptionMax,
            validator: AppValidators.validateDescription,
            decoration: const InputDecoration(hintText: 'Reason for rejection'),
          ),
        ),
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
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              _moderate(
                ref,
                context,
                id,
                EventStatus.rejected,
                reason: reasonController.text.trim(),
              );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
   void _confirmDeleteEvent(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    AppUser? user,
  ) {
    if (user == null) return;
    final canDelete = user.role == UserRole.admin || user.uid == event.creatorId;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can delete only your own events.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
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
              await ref.read(eventRepositoryProvider).deleteEvent(event.eventId);
              if (context.mounted) {
                Navigator.pop(context); 
                if (context.canPop()) context.pop(); 
              }
            } catch (_) {
              if (context.mounted) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are not allowed to delete this event.'),
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

class _EventOverviewSection extends StatelessWidget {
  final EventModel event;
  const _EventOverviewSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 30),
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _CommentSection extends ConsumerStatefulWidget {
  final String eventId;
  final EventModel event;
  const _CommentSection({required this.eventId, required this.event});

  @override
  ConsumerState<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<_CommentSection> {
  final _commentController = TextEditingController();
  final _commentFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(eventCommentsStreamProvider(widget.eventId));
    final user = ref.watch(currentUserProvider).value;
    final canComment =
        user != null && widget.event.status == EventStatus.approved;

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
        if (canComment) ...[
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
                child: Form(
                  key: _commentFormKey,
                  child: TextFormField(
                    controller: _commentController,
                    enabled: canComment,
                    maxLength: AppValidators.commentMax,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: AppValidators.validateComment,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
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
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: canComment
                    ? () async {
                        if (!_commentFormKey.currentState!.validate()) return;

                        try {
                          await ref
                              .read(eventRepositoryProvider)
                              .addComment(
                                widget.eventId,
                                Comment(
                                  commentId: '', // Firebase will generate
                                  userId: user.uid,
                                  userName: user.name,
                                  userPhotoUrl: user.photoUrl,
                                  text: _commentController.text.trim(),
                                  createdAt: DateTime.now(),
                                ),
                              );
                          _commentController.clear();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Comment failed: $e')),
                            );
                          }
                        }
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('No comments yet.')),
              );
            }

            final user = ref.watch(currentUserProvider).value;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isOwner = user?.uid == comment.userId;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: comment.userPhotoUrl != null
                          ? NetworkImage(comment.userPhotoUrl!)
                          : null,
                      child: comment.userPhotoUrl == null
                          ? const Icon(Icons.person_outline)
                          : null,
                    ),
                    title: Text(comment.userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.text),
                        Text(
                          comment.createdAt.toString().split('.')[0],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOwner && widget.event.status == EventStatus.approved)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditCommentDialog(
                              context,
                              ref,
                              widget.eventId,
                              comment,
                            ),
                          ),
                        if (user?.role == UserRole.admin || isOwner)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                              size: 20,
                            ),
                            onPressed: () => ref
                                .read(eventRepositoryProvider)
                                .deleteComment(widget.eventId, comment.commentId),
                          ),
                      ],
                    ),
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
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: comment.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Comment'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Edit your comment...'),
            minLines: 2,
            maxLines: 3,
            maxLength: AppValidators.commentMax,
            validator: AppValidators.validateComment,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref
                    .read(eventRepositoryProvider)
                    .updateComment(
                      eventId,
                      comment.copyWith(text: controller.text.trim()),
                    );
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Comment update failed: $e')));
                }
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
            ).colorScheme.primaryContainer.withValues(alpha: 0.45),
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
