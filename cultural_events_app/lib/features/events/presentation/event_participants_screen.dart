import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';

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
            return const Center(
              child: Text('No one has registered for this event yet.'),
            );
          }

          return ListView.builder(
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final registration = registrations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: registration.userPhotoUrl != null
                      ? NetworkImage(registration.userPhotoUrl!)
                      : null,
                  child: registration.userPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(registration.userName),
                subtitle: Text(
                  'Registered on: ${registration.registeredAt.toLocal().toString().split('.')[0]}',
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
