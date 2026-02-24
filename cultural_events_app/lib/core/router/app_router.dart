import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_details_screen.dart';
import '../../features/events/presentation/create_event_screen.dart';
import '../../features/events/domain/event_model.dart';
import '../../features/events/presentation/my_events_screen.dart';
import '../../features/events/presentation/my_registrations_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/events/presentation/event_participants_screen.dart';
import '../../features/events/presentation/admin_dashboard_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/domain/user_role.dart';
import '../providers/current_user_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUserRole = ref.watch(
    currentUserProvider.select((value) => value.asData?.value?.role),
  );  

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authState.when(
      data: (user) => _ListenableStream(
        ref.read(authRepositoryProvider).authStateChanges(),
      ),
      error: (_, _) => _ListenableStream(Stream.value(null)),
      loading: () => _ListenableStream(Stream.value(null)),
    ),
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _buildPage(state, const HomeScreen(), fromBottom: false),
      ),
      GoRoute(
        path: '/events',
        pageBuilder: (context, state) =>
            _buildPage(state, const EventsScreen(), fromBottom: false),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final event = state.extra as EventModel?;
          return _buildPage(
            state,
            CreateEventScreen(
              editingEventId: eventId,
              initialEvent: event,
            ),
            fromBottom: true,
          );
        },
      ),
      GoRoute(
        path: '/events/:eventId',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final event = state.extra as EventModel?;
          return _buildPage(
            state,
            EventDetailsScreen(eventId: eventId, initialEvent: event),
          );
        },
      ),
      GoRoute(
        path: '/events/:eventId/participants',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return _buildPage(state, EventParticipantsScreen(eventId: eventId));
        },
      ),
      GoRoute(
        path: '/create-event',
        pageBuilder: (context, state) {
          final editId = state.uri.queryParameters['editId'];
          final event = state.extra as EventModel?;
          return _buildPage(
            state,
            CreateEventScreen(
              editingEventId: editId,
              initialEvent: event,
            ),
            fromBottom: true,
          );
        },
      ),
      GoRoute(
        path: '/my-events',
        pageBuilder: (context, state) =>
            _buildPage(state, const MyEventsScreen()),
      ),
      GoRoute(
        path: '/my-registrations',
        pageBuilder: (context, state) =>
            _buildPage(state, const MyRegistrationsScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildPage(state, const ProfileScreen(), fromBottom: true),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            _buildPage(state, const AdminDashboardScreen()),
      ),

      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildPage(state, const LoginScreen(), fromBottom: true),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildPage(state, const RegisterScreen(), fromBottom: true),
      ),
    ],
    redirect: (context, state) {
      final user = authState.asData?.value;
      final isSignedIn = user != null;
      final isAdmin = currentUserRole == UserRole.admin;

      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/register';
      final isAdminRoute = state.uri.path == '/admin';

      if (!isSignedIn &&
          !isAuthRoute &&
          state.uri.path != '/' &&
          !state.uri.path.startsWith('/events')) {
        return '/login';
      }

      if (isSignedIn && isAdminRoute && !isAdmin) {
        return '/';
      }

      if (isSignedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
  );
});

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child, {
  bool fromBottom = false,
}) {
  final begin = fromBottom ? const Offset(0, 0.06) : const Offset(0.04, 0);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, widget) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 0.8, end: 1).animate(curved),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(curved),
          child: widget,
        ),
      );
    },
  );
}

class _ListenableStream extends ChangeNotifier {
  _ListenableStream(Stream stream) {
    notifyListeners();
    stream.listen((_) => notifyListeners());
  }
}
