import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a comment on an event.
///
/// Maps to the `events/{eventId}/comments` subcollection.
/// Contains denormalized user data to avoid extra reads.
class Comment {
  final String commentId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  /// Creates a [Comment] from a Firestore document snapshot.
  factory Comment.fromJson(Map<String, dynamic> json, String commentId) {
    return Comment(
      commentId: commentId,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      text: json['text'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [Comment] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Comment copyWith({
    String? commentId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? text,
    DateTime? createdAt,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
