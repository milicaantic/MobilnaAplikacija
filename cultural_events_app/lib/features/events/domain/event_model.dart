import 'package:cloud_firestore/cloud_firestore.dart';
import 'event_status.dart';

/// Represents a cultural event.
///
/// Maps to the `events` top-level Firestore collection.
/// Contains denormalized creator data to avoid extra reads on the feed.
class EventModel {
  final String eventId;
  final String title;
  final String description;
  final String categoryId;
  final DateTime time;
  final Map<String, dynamic>
  location; // e.g. { 'name': '...', 'lat': ..., 'lng': ... }
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final EventStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedReason;
  final int ratingCount;
  final double averageRating;
  final String? imageUrl;
  final DateTime createdAt;

  const EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.time,
    required this.location,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoUrl,
    required this.status,
    this.approvedBy,
    this.approvedAt,
    this.rejectedReason,
    this.ratingCount = 0,
    this.averageRating = 0.0,
    this.imageUrl,
    required this.createdAt,
  });

  /// Creates an [EventModel] from a Firestore document snapshot.
  factory EventModel.fromJson(Map<String, dynamic> json, String eventId) {
    return EventModel(
      eventId: eventId,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      time: (json['time'] as Timestamp).toDate(),
      location: Map<String, dynamic>.from(json['location'] as Map),
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      creatorPhotoUrl: json['creatorPhotoUrl'] as String?,
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.pending,
      ),
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null
          ? (json['approvedAt'] as Timestamp).toDate()
          : null,
      rejectedReason: json['rejectedReason'] as String?,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Converts this [EventModel] to a Firestore-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'time': Timestamp.fromDate(time),
      'location': location,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorPhotoUrl': creatorPhotoUrl,
      'status': status.name,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectedReason': rejectedReason,
      'ratingCount': ratingCount,
      'averageRating': averageRating,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [EventModel] with the given fields replaced.
  EventModel copyWith({
    String? title,
    String? description,
    String? categoryId,
    DateTime? time,
    Map<String, dynamic>? location,
    String? creatorName,
    String? creatorPhotoUrl,
    EventStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectedReason,
    int? ratingCount,
    double? averageRating,
    String? imageUrl,
  }) {
    return EventModel(
      eventId: eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      time: time ?? this.time,
      location: location ?? this.location,
      creatorId: creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      ratingCount: ratingCount ?? this.ratingCount,
      averageRating: averageRating ?? this.averageRating,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
