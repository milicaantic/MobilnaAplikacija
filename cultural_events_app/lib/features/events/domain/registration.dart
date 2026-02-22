import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's registration for an event.
///
/// Maps to the `events/{eventId}/registrations` subcollection.
/// The document ID is the user's [userId], ensuring one registration per user.
class Registration {
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime registeredAt;
  // Denormalized event data for "My Registrations" screen
  final String? eventTitle;
  final DateTime? eventTime;
  final String? locationName;

  const Registration({
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.registeredAt,
    this.eventTitle,
    this.eventTime,
    this.locationName,
  });

  /// Creates a [Registration] from a Firestore document snapshot.
  factory Registration.fromJson(Map<String, dynamic> json, String userId) {
    return Registration(
      eventId: json['eventId'] as String? ?? '',
      userId: userId,
      userName: json['userName'] as String? ?? 'Unknown User',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      registeredAt: (json['registeredAt'] as Timestamp).toDate(),
      eventTitle: json['eventTitle'] as String?,
      eventTime: json['eventTime'] != null
          ? (json['eventTime'] as Timestamp).toDate()
          : null,
      locationName: json['locationName'] as String?,
    );
  }

  /// Converts this [Registration] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'registeredAt': Timestamp.fromDate(registeredAt),
      if (eventTitle != null) 'eventTitle': eventTitle,
      if (eventTime != null) 'eventTime': Timestamp.fromDate(eventTime!),
      if (locationName != null) 'locationName': locationName,
    };
  }
}
