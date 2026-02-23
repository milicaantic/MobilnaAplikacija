import 'package:cloud_firestore/cloud_firestore.dart';


class Rating {
  final String userId;
  final int rating; 
  final DateTime timestamp;

  const Rating({
    required this.userId,
    required this.rating,
    required this.timestamp,
  });

  factory Rating.fromJson(Map<String, dynamic> json, String userId) {
    return Rating(
      userId: userId,
      rating: (json['rating'] as num).toInt(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
