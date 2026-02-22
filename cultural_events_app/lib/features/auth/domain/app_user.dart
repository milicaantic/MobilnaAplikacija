import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

/// Represents a user in the application.
///
/// Maps to the `users` top-level Firestore collection.
/// The document ID is the user's Firebase Auth [uid].
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  /// Creates an [AppUser] from a Firestore document snapshot.
  factory AppUser.fromJson(Map<String, dynamic> json, String uid) {
    return AppUser(
      uid: uid,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [AppUser] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [AppUser] with the given fields replaced.
  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
