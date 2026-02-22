import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's rating of an event.
///
/// Maps to the `events/{eventId}/ratings` subcollection.
/// The document ID is the user's [userId], ensuring one rating per user.
class Rating {
  final String userId;
  final int rating; // 1–5
  final DateTime timestamp;

  const Rating({
    required this.userId,
    required this.rating,
    required this.timestamp,
  });

  /// Creates a [Rating] from a Firestore document snapshot.
  factory Rating.fromJson(Map<String, dynamic> json, String userId) {
    return Rating(
      userId: userId,
      rating: (json['rating'] as num).toInt(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Converts this [Rating] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
