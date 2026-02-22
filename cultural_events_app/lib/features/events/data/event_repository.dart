import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../domain/comment.dart';
import '../domain/registration.dart';
import '../domain/rating.dart';

part 'event_repository.g.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<EventModel>> watchEvents({
    EventStatus? status,
    String? creatorId,
    String? categoryId,
    String? searchQuery,
  }) {
    Query query = _firestore.collection('events');

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    if (creatorId != null) {
      query = query.where('creatorId', isEqualTo: creatorId);
    }

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      final events = snapshot.docs
          .map(
            (doc) =>
                EventModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryStr = searchQuery.toLowerCase();
        return events
            .where(
              (e) =>
                  e.title.toLowerCase().contains(queryStr) ||
                  e.description.toLowerCase().contains(queryStr),
            )
            .toList();
      }

      return events;
    });
  }

  Future<void> createEvent(EventModel event) async {
    await _firestore.collection('events').add(event.toJson());
  }

  Future<void> updateEvent(EventModel event) async {
    await _firestore
        .collection('events')
        .doc(event.eventId)
        .update(event.toJson());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> updateEventStatus(
    String eventId,
    EventStatus status, {
    String? approvedBy,
    String? rejectedReason,
  }) async {
    final data = {
      'status': status.name,
      if (status == EventStatus.approved)
        'approvedAt': FieldValue.serverTimestamp(),
      if (status == EventStatus.approved) 'approvedBy': approvedBy,
      if (status == EventStatus.rejected) 'rejectedReason': rejectedReason,
    };
    await _firestore.collection('events').doc(eventId).update(data);
  }

  // --- Registration ---

  Future<void> registerForEvent(
    String eventId,
    String userId,
    String userName, {
    String? userPhotoUrl,
    String? eventTitle,
    DateTime? eventTime,
    String? locationName,
  }) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .set({
          'eventId': eventId,
          'userId': userId,
          'userName': userName,
          'userPhotoUrl': userPhotoUrl,
          'registeredAt': FieldValue.serverTimestamp(),
          if (eventTitle != null) 'eventTitle': eventTitle,
          if (eventTime != null) 'eventTime': Timestamp.fromDate(eventTime),
          if (locationName != null) 'locationName': locationName,
        });
  }

  Future<void> unregisterFromEvent(String eventId, String userId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .delete();
  }

  Stream<bool> watchIsRegistered(String eventId, String userId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<Registration>> watchRegistrations(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Registration.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Registration>> watchUserRegistrations(String userId) {
    return _firestore
        .collectionGroup('registrations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            // Since it's a collection group query, we can also extract eventId from the path if needed
            // path: events/{eventId}/registrations/{userId}
            final pathSegments = doc.reference.path.split('/');
            final eventIdFromPath = pathSegments.length >= 2
                ? pathSegments[1]
                : '';

            return Registration.fromJson({
              ...data,
              if (data['eventId'] == null) 'eventId': eventIdFromPath,
            }, userId);
          }).toList(),
        );
  }

  // --- Comments ---

  Future<void> addComment(String eventId, Comment comment) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .add(comment.toJson());
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> updateComment(String eventId, Comment comment) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .doc(comment.commentId)
        .update(comment.toJson());
  }

  Stream<List<Comment>> watchComments(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Comment.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- Ratings ---

  Future<void> rateEvent(String eventId, Rating rating) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('ratings')
        .doc(rating.userId)
        .set(rating.toJson());
  }

  Stream<Rating?> watchUserRating(String eventId, String userId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('ratings')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? Rating.fromJson(doc.data()!, doc.id) : null);
  }

  Stream<List<Rating>> watchAllRatings(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('ratings')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Rating.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<EventModel?> watchEvent(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map(
          (doc) => doc.exists ? EventModel.fromJson(doc.data()!, doc.id) : null,
        );
  }
}

@riverpod
EventRepository eventRepository(Ref ref) {
  return EventRepository();
}

@riverpod
Stream<List<EventModel>> eventsStream(
  Ref ref, {
  EventStatus? status,
  String? creatorId,
  String? categoryId,
  String? searchQuery,
}) {
  return ref
      .watch(eventRepositoryProvider)
      .watchEvents(
        status: status,
        creatorId: creatorId,
        categoryId: categoryId,
        searchQuery: searchQuery,
      );
}

@riverpod
Stream<EventModel?> eventStream(Ref ref, String eventId) {
  return ref.watch(eventRepositoryProvider).watchEvent(eventId);
}

@riverpod
Stream<bool> isRegisteredStream(Ref ref, String eventId, String userId) {
  return ref.watch(eventRepositoryProvider).watchIsRegistered(eventId, userId);
}

@riverpod
Stream<List<Registration>> eventRegistrationsStream(Ref ref, String eventId) {
  return ref.watch(eventRepositoryProvider).watchRegistrations(eventId);
}

@riverpod
Stream<List<Comment>> eventCommentsStream(Ref ref, String eventId) {
  return ref.watch(eventRepositoryProvider).watchComments(eventId);
}

@riverpod
Stream<Rating?> userEventRatingStream(Ref ref, String eventId, String userId) {
  return ref.watch(eventRepositoryProvider).watchUserRating(eventId, userId);
}

@riverpod
Stream<({double average, int count})> eventRatingStatsStream(
  Ref ref,
  String eventId,
) {
  return ref.watch(eventRepositoryProvider).watchAllRatings(eventId).map((
    ratings,
  ) {
    if (ratings.isEmpty) return (average: 0.0, count: 0);
    final total = ratings.fold<int>(0, (sum, r) => sum + r.rating);
    return (average: total / ratings.length, count: ratings.length);
  });
}

@riverpod
Stream<List<Registration>> currentUserRegistrationsStream(
  Ref ref,
  String userId,
) {
  return ref.watch(eventRepositoryProvider).watchUserRegistrations(userId);
}
