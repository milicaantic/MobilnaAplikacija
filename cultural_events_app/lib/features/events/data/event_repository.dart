import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/domain/user_role.dart';
import '../domain/event_model.dart';
import '../domain/event_status.dart';
import '../domain/comment.dart';
import '../domain/registration.dart';
import '../domain/rating.dart';

part 'event_repository.g.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _assertUserCanInteractWithEvent(
    String eventId,
    String userId,
  ) async {
    final snapshots = await Future.wait([
      _firestore.collection('events').doc(eventId).get(),
      _firestore.collection('users').doc(userId).get(),
    ]);

    final eventSnapshot = snapshots[0];
    final userSnapshot = snapshots[1];

    if (!eventSnapshot.exists) {
      throw Exception('Event not found.');
    }

    final eventData = eventSnapshot.data()!;
    final userData = userSnapshot.data();
    final eventStatus = eventData['status'] as String?;
    final role = userData?['role'] as String?;

    if (eventStatus != EventStatus.approved.name) {
      throw Exception('Interaction is allowed only on approved events.');
    }
    if (role != UserRole.user.name && role != UserRole.admin.name) {
      throw Exception('Only authenticated users can perform this action.');
    }
  }

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
    final eventRef = _firestore.collection('events').doc();
    final categoryRef = _firestore.collection('categories').doc(event.categoryId);

    await _firestore.runTransaction((tx) async {
      final categorySnapshot = await tx.get(categoryRef);
      if (!categorySnapshot.exists) {
        throw Exception('Selected category does not exist.');
      }

      tx.set(eventRef, event.toJson());
      tx.update(categoryRef, {'eventCount': FieldValue.increment(1)});
    });
  }

  Future<void> updateEvent(EventModel event) async {
    final eventRef = _firestore.collection('events').doc(event.eventId);

    await _firestore.runTransaction((tx) async {
      final existingEventSnapshot = await tx.get(eventRef);
      if (!existingEventSnapshot.exists) {
        throw Exception('Event not found.');
      }

      final existingEvent = existingEventSnapshot.data()!;
      final previousCategoryId = existingEvent['categoryId'] as String?;
      final newCategoryId = event.categoryId;

      if (previousCategoryId != null && previousCategoryId != newCategoryId) {
        final previousCategoryRef = _firestore
            .collection('categories')
            .doc(previousCategoryId);
        final newCategoryRef = _firestore.collection('categories').doc(newCategoryId);

        final previousCategorySnapshot = await tx.get(previousCategoryRef);
        final newCategorySnapshot = await tx.get(newCategoryRef);

        if (!previousCategorySnapshot.exists || !newCategorySnapshot.exists) {
          throw Exception('Category not found.');
        }

        tx.update(previousCategoryRef, {'eventCount': FieldValue.increment(-1)});
        tx.update(newCategoryRef, {'eventCount': FieldValue.increment(1)});
      }

      tx.update(eventRef, event.toJson());
    });
  }

  Future<void> deleteEvent(String eventId) async {
    final eventRef = _firestore.collection('events').doc(eventId);

    await _firestore.runTransaction((tx) async {
      final eventSnapshot = await tx.get(eventRef);
      if (!eventSnapshot.exists) {
        throw Exception('Event not found.');
      }

      final categoryId = eventSnapshot.data()?['categoryId'] as String?;
      if (categoryId != null && categoryId.isNotEmpty) {
        final categoryRef = _firestore.collection('categories').doc(categoryId);
        final categorySnapshot = await tx.get(categoryRef);
        if (categorySnapshot.exists) {
          tx.update(categoryRef, {'eventCount': FieldValue.increment(-1)});
        }
      }

      tx.delete(eventRef);
    });
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


  Future<void> registerForEvent(
    String eventId,
    String userId,
    String userName, {
    String? userPhotoUrl,
    String? eventTitle,
    DateTime? eventTime,
    String? locationName,
  }) async {
    await _assertUserCanInteractWithEvent(eventId, userId);

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


  Future<void> addComment(String eventId, Comment comment) async {
    await _assertUserCanInteractWithEvent(eventId, comment.userId);

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
    await _assertUserCanInteractWithEvent(eventId, comment.userId);

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


  Future<void> rateEvent(String eventId, Rating rating) async {
    await _assertUserCanInteractWithEvent(eventId, rating.userId);

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
