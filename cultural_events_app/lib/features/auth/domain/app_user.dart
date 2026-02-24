import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime? photoUpdatedAt;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.photoUpdatedAt,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String uid) {
    return AppUser(
      uid: uid,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      photoUpdatedAt: json['photoUpdatedAt'] is Timestamp
          ? (json['photoUpdatedAt'] as Timestamp).toDate()
          : null,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.user,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'photoUpdatedAt': photoUpdatedAt != null
          ? Timestamp.fromDate(photoUpdatedAt!)
          : null,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    DateTime? photoUpdatedAt,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
