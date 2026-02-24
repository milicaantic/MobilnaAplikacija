import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? photoUrl,
  }) async {
    final data = {
      if (name != null) 'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoUrl != null) 'photoUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(data);
    }
  }

  Stream<List<AppUser>> watchAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    if (role == UserRole.guest) {
      throw Exception('Guest is not a storable role.');
    }
    await _firestore.collection('users').doc(uid).update({'role': role.name});
  }
}

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository();
}

@riverpod
Stream<List<AppUser>> allUsersStream(Ref ref) {
  return ref.watch(userRepositoryProvider).watchAllUsers();
}
