import 'package:cloud_firestore/cloud_firestore.dart';


class Comment {
  final String commentId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime? userPhotoUpdatedAt;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.commentId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.userPhotoUpdatedAt,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json, String commentId) {
    return Comment(
      commentId: commentId,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      userPhotoUpdatedAt: json['userPhotoUpdatedAt'] is Timestamp
          ? (json['userPhotoUpdatedAt'] as Timestamp).toDate()
          : null,
      text: json['text'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      if (userPhotoUpdatedAt != null)
        'userPhotoUpdatedAt': Timestamp.fromDate(userPhotoUpdatedAt!),
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Comment copyWith({
    String? commentId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    DateTime? userPhotoUpdatedAt,
    String? text,
    DateTime? createdAt,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      userPhotoUpdatedAt: userPhotoUpdatedAt ?? this.userPhotoUpdatedAt,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
