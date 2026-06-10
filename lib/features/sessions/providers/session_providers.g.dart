// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookSessionsHash() => r'c4639850955b13b6cc6e1eae4ad3c829878365d5';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provides the list of reading sessions for a given [bookId],
/// ordered by start time (newest first).
///
/// Copied from [bookSessions].
@ProviderFor(bookSessions)
const bookSessionsProvider = BookSessionsFamily();

/// Provides the list of reading sessions for a given [bookId],
/// ordered by start time (newest first).
///
/// Copied from [bookSessions].
class BookSessionsFamily extends Family<AsyncValue<List<ReadingSession>>> {
  /// Provides the list of reading sessions for a given [bookId],
  /// ordered by start time (newest first).
  ///
  /// Copied from [bookSessions].
  const BookSessionsFamily();

  /// Provides the list of reading sessions for a given [bookId],
  /// ordered by start time (newest first).
  ///
  /// Copied from [bookSessions].
  BookSessionsProvider call(String bookId) {
    return BookSessionsProvider(bookId);
  }

  @override
  BookSessionsProvider getProviderOverride(
    covariant BookSessionsProvider provider,
  ) {
    return call(provider.bookId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookSessionsProvider';
}

/// Provides the list of reading sessions for a given [bookId],
/// ordered by start time (newest first).
///
/// Copied from [bookSessions].
class BookSessionsProvider extends FutureProvider<List<ReadingSession>> {
  /// Provides the list of reading sessions for a given [bookId],
  /// ordered by start time (newest first).
  ///
  /// Copied from [bookSessions].
  BookSessionsProvider(String bookId)
    : this._internal(
        (ref) => bookSessions(ref as BookSessionsRef, bookId),
        from: bookSessionsProvider,
        name: r'bookSessionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookSessionsHash,
        dependencies: BookSessionsFamily._dependencies,
        allTransitiveDependencies:
            BookSessionsFamily._allTransitiveDependencies,
        bookId: bookId,
      );

  BookSessionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
  }) : super.internal();

  final String bookId;

  @override
  Override overrideWith(
    FutureOr<List<ReadingSession>> Function(BookSessionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookSessionsProvider._internal(
        (ref) => create(ref as BookSessionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
      ),
    );
  }

  @override
  FutureProviderElement<List<ReadingSession>> createElement() {
    return _BookSessionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSessionsProvider && other.bookId == bookId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookSessionsRef on FutureProviderRef<List<ReadingSession>> {
  /// The parameter `bookId` of this provider.
  String get bookId;
}

class _BookSessionsProviderElement
    extends FutureProviderElement<List<ReadingSession>>
    with BookSessionsRef {
  _BookSessionsProviderElement(super.provider);

  @override
  String get bookId => (origin as BookSessionsProvider).bookId;
}

String _$recentSessionsHash() => r'5c70adc84eba4953bbc247caf344abf9801b4a9b';

/// Provides all reading sessions across all books, ordered by
/// start time (newest first).
///
/// Copied from [recentSessions].
@ProviderFor(recentSessions)
final recentSessionsProvider = FutureProvider<List<ReadingSession>>.internal(
  recentSessions,
  name: r'recentSessionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recentSessionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecentSessionsRef = FutureProviderRef<List<ReadingSession>>;
String _$activeSessionHash() => r'445ec81a58618f4897561ad60aabaf5edbe39a40';

/// Provider for the active reading session.
///
/// Copied from [ActiveSession].
@ProviderFor(ActiveSession)
final activeSessionProvider =
    NotifierProvider<ActiveSession, ActiveSessionState>.internal(
      ActiveSession.new,
      name: r'activeSessionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveSession = Notifier<ActiveSessionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
