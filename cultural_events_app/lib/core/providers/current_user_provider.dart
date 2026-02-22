import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/app_user.dart';
import '../../features/auth/data/auth_repository.dart';

part 'current_user_provider.g.dart';

@riverpod
Stream<AppUser?> currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists) return null;
            return AppUser.fromJson(snapshot.data()!, snapshot.id);
          });
    },
    error: (_, _) => Stream.value(null),
    loading: () => Stream.value(null),
  );
}
