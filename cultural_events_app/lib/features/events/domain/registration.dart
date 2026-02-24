import 'package:cloud_firestore/cloud_firestore.dart';

class Registration {
  final String eventId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime registeredAt;
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

  factory Registration.fromJson(Map<String, dynamic> json, String userId) {
    final registeredAtRaw = json['registeredAt'];
    final registeredAt = registeredAtRaw is Timestamp
        ? registeredAtRaw.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    final eventTimeRaw = json['eventTime'];
    return Registration(
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String? ?? userId,
      userName: json['userName'] as String? ?? 'Unknown User',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      registeredAt: registeredAt,
      eventTitle: json['eventTitle'] as String?,
      eventTime: eventTimeRaw is Timestamp ? eventTimeRaw.toDate() : null,
      locationName: json['locationName'] as String?,
    );
  }

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
