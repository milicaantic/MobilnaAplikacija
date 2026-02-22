import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/current_user_provider.dart';
import '../../auth/domain/user_role.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);
    final user = userAsyncValue.value;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cultural Events',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Discover upcoming cultural moments in your city.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 34),
                    ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Register'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.push('/login'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.push('/events'),
                      child: const Text('Continue as a Guest'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final roleColor = user.role == UserRole.admin
        ? colorScheme.tertiary
        : colorScheme.secondary;
    final roleLabel = user.role == UserRole.admin ? 'Admin Access' : 'User Access';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Cultural Events'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: userAsyncValue.when(
                          data: (currentUser) => Text(
                            'Welcome back, ${currentUser?.name ?? ''}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          error: (_, __) => Text(
                            'Welcome back',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          loading: () => const LinearProgressIndicator(minHeight: 2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.15),
                          border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Discover cultural happenings, track your registrations, and manage events with clarity.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  if (user.role == UserRole.admin)
                    _HomeActionCard(
                      title: 'Explore',
                      description: 'Browse approved events visible to all users.',
                      icon: Icons.explore_outlined,
                      onTap: () => context.push('/events'),
                    ),
                  if (user.role == UserRole.admin) const SizedBox(height: 12),
                  if (user.role == UserRole.admin)
                    _HomeActionCard(
                      title: 'Dashboard',
                      description: 'Open approvals, category tools, and user control.',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () => context.push('/admin'),
                    ),
                  if (user.role == UserRole.admin) const SizedBox(height: 12),
                  if (user.role == UserRole.admin)
                    _HomeActionCard(
                      title: 'My Events',
                      description: 'Manage events you created and their status.',
                      icon: Icons.event_note_outlined,
                      onTap: () => context.push('/my-events'),
                    ),
                  if (user.role == UserRole.admin) const SizedBox(height: 12),
                  if (user.role == UserRole.admin)
                    _HomeActionCard(
                      title: 'My Registrations',
                      description: 'Track events you have registered for.',
                      icon: Icons.event_available_outlined,
                      onTap: () => context.push('/my-registrations'),
                    ),
                  if (user.role != UserRole.admin)
                    _HomeActionCard(
                      title: 'Explore',
                      description: 'Browse approved events and open details quickly.',
                      icon: Icons.explore_outlined,
                      onTap: () => context.push('/events'),
                    ),
                  if (user.role != UserRole.admin) const SizedBox(height: 12),
                  if (user.role != UserRole.admin)
                    _HomeActionCard(
                      title: 'My Registrations',
                      description: 'Track upcoming events you have joined.',
                      icon: Icons.event_available_outlined,
                      onTap: () => context.push('/my-registrations'),
                    ),
                  if (user.role != UserRole.admin) const SizedBox(height: 12),
                  if (user.role != UserRole.admin)
                    _HomeActionCard(
                      title: 'My Events',
                      description: 'View events you created and their status.',
                      icon: Icons.event_note_outlined,
                      onTap: () => context.push('/my-events'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
