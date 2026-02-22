// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventRepository)
final eventRepositoryProvider = EventRepositoryProvider._();

final class EventRepositoryProvider
    extends
        $FunctionalProvider<EventRepository, EventRepository, EventRepository>
    with $Provider<EventRepository> {
  EventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventRepositoryHash();

  @$internal
  @override
  $ProviderElement<EventRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventRepository create(Ref ref) {
    return eventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventRepository>(value),
    );
  }
}

String _$eventRepositoryHash() => r'1c4157e8b227fc788f47990d96d63d507586dcbc';

@ProviderFor(eventsStream)
final eventsStreamProvider = EventsStreamFamily._();

final class EventsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EventModel>>,
          List<EventModel>,
          Stream<List<EventModel>>
        >
    with $FutureModifier<List<EventModel>>, $StreamProvider<List<EventModel>> {
  EventsStreamProvider._({
    required EventsStreamFamily super.from,
    required ({
      EventStatus? status,
      String? creatorId,
      String? categoryId,
      String? searchQuery,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'eventsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventsStreamHash();

  @override
  String toString() {
    return r'eventsStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<EventModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<EventModel>> create(Ref ref) {
    final argument =
        this.argument
            as ({
              EventStatus? status,
              String? creatorId,
              String? categoryId,
              String? searchQuery,
            });
    return eventsStream(
      ref,
      status: argument.status,
      creatorId: argument.creatorId,
      categoryId: argument.categoryId,
      searchQuery: argument.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsStreamHash() => r'6d5f3d96dd049aeb384e6fa42959a003e5eb785d';

final class EventsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<EventModel>>,
          ({
            EventStatus? status,
            String? creatorId,
            String? categoryId,
            String? searchQuery,
          })
        > {
  EventsStreamFamily._()
    : super(
        retry: null,
        name: r'eventsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventsStreamProvider call({
    EventStatus? status,
    String? creatorId,
    String? categoryId,
    String? searchQuery,
  }) => EventsStreamProvider._(
    argument: (
      status: status,
      creatorId: creatorId,
      categoryId: categoryId,
      searchQuery: searchQuery,
    ),
    from: this,
  );

  @override
  String toString() => r'eventsStreamProvider';
}

@ProviderFor(eventStream)
final eventStreamProvider = EventStreamFamily._();

final class EventStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<EventModel?>,
          EventModel?,
          Stream<EventModel?>
        >
    with $FutureModifier<EventModel?>, $StreamProvider<EventModel?> {
  EventStreamProvider._({
    required EventStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventStreamHash();

  @override
  String toString() {
    return r'eventStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<EventModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<EventModel?> create(Ref ref) {
    final argument = this.argument as String;
    return eventStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventStreamHash() => r'0e34db07afc4662cdb5543eb09a37bf9c2e2065c';

final class EventStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<EventModel?>, String> {
  EventStreamFamily._()
    : super(
        retry: null,
        name: r'eventStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventStreamProvider call(String eventId) =>
      EventStreamProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventStreamProvider';
}

@ProviderFor(isRegisteredStream)
final isRegisteredStreamProvider = IsRegisteredStreamFamily._();

final class IsRegisteredStreamProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  IsRegisteredStreamProvider._({
    required IsRegisteredStreamFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'isRegisteredStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isRegisteredStreamHash();

  @override
  String toString() {
    return r'isRegisteredStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    final argument = this.argument as (String, String);
    return isRegisteredStream(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is IsRegisteredStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isRegisteredStreamHash() =>
    r'd567415f1d80cf2670fa81bb377b5d2d87a5f45c';

final class IsRegisteredStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<bool>, (String, String)> {
  IsRegisteredStreamFamily._()
    : super(
        retry: null,
        name: r'isRegisteredStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsRegisteredStreamProvider call(String eventId, String userId) =>
      IsRegisteredStreamProvider._(argument: (eventId, userId), from: this);

  @override
  String toString() => r'isRegisteredStreamProvider';
}

@ProviderFor(eventRegistrationsStream)
final eventRegistrationsStreamProvider = EventRegistrationsStreamFamily._();

final class EventRegistrationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Registration>>,
          List<Registration>,
          Stream<List<Registration>>
        >
    with
        $FutureModifier<List<Registration>>,
        $StreamProvider<List<Registration>> {
  EventRegistrationsStreamProvider._({
    required EventRegistrationsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventRegistrationsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventRegistrationsStreamHash();

  @override
  String toString() {
    return r'eventRegistrationsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Registration>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Registration>> create(Ref ref) {
    final argument = this.argument as String;
    return eventRegistrationsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventRegistrationsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventRegistrationsStreamHash() =>
    r'6945768ba9c1b9849daf9ed179fc4fd1de4dd076';

final class EventRegistrationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Registration>>, String> {
  EventRegistrationsStreamFamily._()
    : super(
        retry: null,
        name: r'eventRegistrationsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventRegistrationsStreamProvider call(String eventId) =>
      EventRegistrationsStreamProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventRegistrationsStreamProvider';
}

@ProviderFor(eventCommentsStream)
final eventCommentsStreamProvider = EventCommentsStreamFamily._();

final class EventCommentsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Comment>>,
          List<Comment>,
          Stream<List<Comment>>
        >
    with $FutureModifier<List<Comment>>, $StreamProvider<List<Comment>> {
  EventCommentsStreamProvider._({
    required EventCommentsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventCommentsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventCommentsStreamHash();

  @override
  String toString() {
    return r'eventCommentsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Comment>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Comment>> create(Ref ref) {
    final argument = this.argument as String;
    return eventCommentsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventCommentsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventCommentsStreamHash() =>
    r'b6f0220ad1fa028dc98a711a6344d3a8f914307d';

final class EventCommentsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Comment>>, String> {
  EventCommentsStreamFamily._()
    : super(
        retry: null,
        name: r'eventCommentsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventCommentsStreamProvider call(String eventId) =>
      EventCommentsStreamProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventCommentsStreamProvider';
}

@ProviderFor(userEventRatingStream)
final userEventRatingStreamProvider = UserEventRatingStreamFamily._();

final class UserEventRatingStreamProvider
    extends $FunctionalProvider<AsyncValue<Rating?>, Rating?, Stream<Rating?>>
    with $FutureModifier<Rating?>, $StreamProvider<Rating?> {
  UserEventRatingStreamProvider._({
    required UserEventRatingStreamFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'userEventRatingStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userEventRatingStreamHash();

  @override
  String toString() {
    return r'userEventRatingStreamProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<Rating?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Rating?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return userEventRatingStream(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is UserEventRatingStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userEventRatingStreamHash() =>
    r'334d178d4e12c43297aacc2b430b318da572f88a';

final class UserEventRatingStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Rating?>, (String, String)> {
  UserEventRatingStreamFamily._()
    : super(
        retry: null,
        name: r'userEventRatingStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserEventRatingStreamProvider call(String eventId, String userId) =>
      UserEventRatingStreamProvider._(argument: (eventId, userId), from: this);

  @override
  String toString() => r'userEventRatingStreamProvider';
}

@ProviderFor(eventRatingStatsStream)
final eventRatingStatsStreamProvider = EventRatingStatsStreamFamily._();

final class EventRatingStatsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<({double average, int count})>,
          ({double average, int count}),
          Stream<({double average, int count})>
        >
    with
        $FutureModifier<({double average, int count})>,
        $StreamProvider<({double average, int count})> {
  EventRatingStatsStreamProvider._({
    required EventRatingStatsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventRatingStatsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventRatingStatsStreamHash();

  @override
  String toString() {
    return r'eventRatingStatsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<({double average, int count})> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<({double average, int count})> create(Ref ref) {
    final argument = this.argument as String;
    return eventRatingStatsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventRatingStatsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventRatingStatsStreamHash() =>
    r'f2d27dc5ee09d5e7ae402dea56224296b38b0059';

final class EventRatingStatsStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<({double average, int count})>,
          String
        > {
  EventRatingStatsStreamFamily._()
    : super(
        retry: null,
        name: r'eventRatingStatsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventRatingStatsStreamProvider call(String eventId) =>
      EventRatingStatsStreamProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventRatingStatsStreamProvider';
}

@ProviderFor(currentUserRegistrationsStream)
final currentUserRegistrationsStreamProvider =
    CurrentUserRegistrationsStreamFamily._();

final class CurrentUserRegistrationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Registration>>,
          List<Registration>,
          Stream<List<Registration>>
        >
    with
        $FutureModifier<List<Registration>>,
        $StreamProvider<List<Registration>> {
  CurrentUserRegistrationsStreamProvider._({
    required CurrentUserRegistrationsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentUserRegistrationsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentUserRegistrationsStreamHash();

  @override
  String toString() {
    return r'currentUserRegistrationsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Registration>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Registration>> create(Ref ref) {
    final argument = this.argument as String;
    return currentUserRegistrationsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentUserRegistrationsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentUserRegistrationsStreamHash() =>
    r'7780a5ec8ae502dbdf9914b29997e48ccab268d0';

final class CurrentUserRegistrationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Registration>>, String> {
  CurrentUserRegistrationsStreamFamily._()
    : super(
        retry: null,
        name: r'currentUserRegistrationsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentUserRegistrationsStreamProvider call(String userId) =>
      CurrentUserRegistrationsStreamProvider._(argument: userId, from: this);

  @override
  String toString() => r'currentUserRegistrationsStreamProvider';
}
