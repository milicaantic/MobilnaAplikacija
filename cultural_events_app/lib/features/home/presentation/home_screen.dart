import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_role.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);
    final user = userAsyncValue.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultural Events'),
        actions: [
          if (user != null) ...[
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
          ],
          if (user == null)
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Login'),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              userAsyncValue.when(
                data: (user) => Text(
                  user != null
                      ? 'Welcome back, ${user.name}!'
                      : 'Welcome to Cultural Events App',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                error: (_, __) => const Text('Welcome to Cultural Events App'),
                loading: () => const CircularProgressIndicator(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discover and manage cultural events in your area.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => context.push('/events'),
                icon: const Icon(Icons.explore),
                label: const Text('Explore Events'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                ),
              ),
              userAsyncValue.when(
                data: (user) => user != null
                    ? Column(
                        children: [
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/my-events'),
                            icon: const Icon(Icons.event),
                            label: const Text('My Created Events'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(250, 50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/my-registrations'),
                            icon: const Icon(Icons.event_available),
                            label: const Text('My Registrations'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(250, 50),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/profile'),
                            icon: const Icon(Icons.person),
                            label: const Text('My Profile'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(250, 50),
                            ),
                          ),
                          if (user.role == UserRole.admin) ...[
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/admin'),
                              icon: const Icon(Icons.admin_panel_settings),
                              label: const Text('Admin Dashboard'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(250, 50),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                              ),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        children: [
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Sign in for more features'),
                          ),
                        ],
                      ),
                error: (_, __) => const SizedBox(),
                loading: () => const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
