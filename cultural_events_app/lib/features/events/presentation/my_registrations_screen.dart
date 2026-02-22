import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/current_user_provider.dart';
import '../data/event_repository.dart';

class MyRegistrationsScreen extends ConsumerWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your registrations')),
      );
    }

    final registrationsAsync = ref.watch(
      currentUserRegistrationsStreamProvider(user.uid),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('My Registrations')),
      body: registrationsAsync.when(
        data: (registrations) {
          if (registrations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No registrations yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Explore events and sign up to see them here!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: registrations.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final reg = registrations[index];
              return Card(
                child: ListTile(
                  title: Text(reg.eventTitle ?? 'Unknown Event'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reg.eventTime?.toString().split('.')[0] ?? ''),
                      Text(reg.locationName ?? ''),
                    ],
                  ),
                  onTap: () => context.push('/events/${reg.eventId}'),
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
