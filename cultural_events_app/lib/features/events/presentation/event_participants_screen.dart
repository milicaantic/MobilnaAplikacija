import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../../../core/widgets/network_image_utils.dart';

class EventParticipantsScreen extends ConsumerWidget {
  final String eventId;

  const EventParticipantsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationsAsync = ref.watch(
      eventRegistrationsStreamProvider(eventId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: registrationsAsync.when(
        data: (registrations) {
          if (registrations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_off_outlined,
                      size: 60,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 10),
                    const Text('No one has registered for this event yet.'),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: registrations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final registration = registrations[index];
              return Card(
                child: ListTile(
                  leading: Builder(
                    builder: (context) {
                      final photoUrl = (registration.userPhotoUrl ?? '').trim();
                      final ImageProvider<Object>? imageProvider =
                          photoUrl.isNotEmpty
                          ? buildOptimizedNetworkImageProvider(
                              photoUrl,
                              cacheWidth: 112,
                              cacheHeight: 112,
                            )
                          : null;
                      return CircleAvatar(
                        backgroundImage: imageProvider,
                        onBackgroundImageError: imageProvider == null
                            ? null
                            : (_, __) {},
                        child: imageProvider == null
                            ? const Icon(Icons.person_outline)
                            : null,
                      );
                    },
                  ),
                  title: Text(
                    registration.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Registered on: ${registration.registeredAt.toLocal().toString().split('.')[0]}',
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
