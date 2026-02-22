import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_details_screen.dart';
import '../../features/events/presentation/create_event_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/events/domain/event_model.dart';
import '../../features/events/presentation/my_events_screen.dart';
import '../../features/events/presentation/my_registrations_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/events/presentation/event_participants_screen.dart';
import '../../features/events/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authState.when(
      data: (user) => _ListenableStream(
        ref.read(authRepositoryProvider).authStateChanges(),
      ),
      error: (_, __) => _ListenableStream(Stream.value(null)),
      loading: () => _ListenableStream(Stream.value(null)),
    ),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final event = state.extra as EventModel?;
          return EventDetailsScreen(eventId: eventId, initialEvent: event);
        },
      ),
      GoRoute(
        path: '/events/:eventId/participants',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventParticipantsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/create-event',
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/my-events',
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: '/my-registrations',
        builder: (context, state) => const MyRegistrationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
    redirect: (context, state) {
      final user = authState.asData?.value;
      final isSignedIn = user != null;

      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/register';

      if (!isSignedIn &&
          !isAuthRoute &&
          state.uri.path != '/' &&
          !state.uri.path.startsWith('/events')) {
        return '/login';
      }

      if (isSignedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
  );
});

class _ListenableStream extends ChangeNotifier {
  _ListenableStream(Stream stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
