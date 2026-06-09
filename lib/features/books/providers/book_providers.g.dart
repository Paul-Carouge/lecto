// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allBooksHash() => r'4cf0110b0a42a97fa58eae0c63c15bd0a2604796';

/// Provides the full list of books from the database, ordered by
/// date added (newest first).
///
/// Copied from [allBooks].
@ProviderFor(allBooks)
final allBooksProvider = FutureProvider<List<Book>>.internal(
  allBooks,
  name: r'allBooksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allBooksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllBooksRef = FutureProviderRef<List<Book>>;
String _$booksByStatusHash() => r'2cdbfed36c0f9e2a56303bd82ab94be515aa1f74';

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

/// Provides books filtered by [ReadingStatus].
///
/// Copied from [booksByStatus].
@ProviderFor(booksByStatus)
const booksByStatusProvider = BooksByStatusFamily();

/// Provides books filtered by [ReadingStatus].
///
/// Copied from [booksByStatus].
class BooksByStatusFamily extends Family<AsyncValue<List<Book>>> {
  /// Provides books filtered by [ReadingStatus].
  ///
  /// Copied from [booksByStatus].
  const BooksByStatusFamily();

  /// Provides books filtered by [ReadingStatus].
  ///
  /// Copied from [booksByStatus].
  BooksByStatusProvider call(ReadingStatus status) {
    return BooksByStatusProvider(status);
  }

  @override
  BooksByStatusProvider getProviderOverride(
    covariant BooksByStatusProvider provider,
  ) {
    return call(provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'booksByStatusProvider';
}

/// Provides books filtered by [ReadingStatus].
///
/// Copied from [booksByStatus].
class BooksByStatusProvider extends FutureProvider<List<Book>> {
  /// Provides books filtered by [ReadingStatus].
  ///
  /// Copied from [booksByStatus].
  BooksByStatusProvider(ReadingStatus status)
    : this._internal(
        (ref) => booksByStatus(ref as BooksByStatusRef, status),
        from: booksByStatusProvider,
        name: r'booksByStatusProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$booksByStatusHash,
        dependencies: BooksByStatusFamily._dependencies,
        allTransitiveDependencies:
            BooksByStatusFamily._allTransitiveDependencies,
        status: status,
      );

  BooksByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final ReadingStatus status;

  @override
  Override overrideWith(
    FutureOr<List<Book>> Function(BooksByStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BooksByStatusProvider._internal(
        (ref) => create(ref as BooksByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  FutureProviderElement<List<Book>> createElement() {
    return _BooksByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BooksByStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BooksByStatusRef on FutureProviderRef<List<Book>> {
  /// The parameter `status` of this provider.
  ReadingStatus get status;
}

class _BooksByStatusProviderElement extends FutureProviderElement<List<Book>>
    with BooksByStatusRef {
  _BooksByStatusProviderElement(super.provider);

  @override
  ReadingStatus get status => (origin as BooksByStatusProvider).status;
}

String _$currentBookHash() => r'835e7bd32a255873b13a1c3b37af737643b2769b';

/// Provides a single [Book] by its ID.
/// Returns `null` if no book with that ID exists.
///
/// Copied from [currentBook].
@ProviderFor(currentBook)
const currentBookProvider = CurrentBookFamily();

/// Provides a single [Book] by its ID.
/// Returns `null` if no book with that ID exists.
///
/// Copied from [currentBook].
class CurrentBookFamily extends Family<AsyncValue<Book?>> {
  /// Provides a single [Book] by its ID.
  /// Returns `null` if no book with that ID exists.
  ///
  /// Copied from [currentBook].
  const CurrentBookFamily();

  /// Provides a single [Book] by its ID.
  /// Returns `null` if no book with that ID exists.
  ///
  /// Copied from [currentBook].
  CurrentBookProvider call(String id) {
    return CurrentBookProvider(id);
  }

  @override
  CurrentBookProvider getProviderOverride(
    covariant CurrentBookProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentBookProvider';
}

/// Provides a single [Book] by its ID.
/// Returns `null` if no book with that ID exists.
///
/// Copied from [currentBook].
class CurrentBookProvider extends FutureProvider<Book?> {
  /// Provides a single [Book] by its ID.
  /// Returns `null` if no book with that ID exists.
  ///
  /// Copied from [currentBook].
  CurrentBookProvider(String id)
    : this._internal(
        (ref) => currentBook(ref as CurrentBookRef, id),
        from: currentBookProvider,
        name: r'currentBookProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentBookHash,
        dependencies: CurrentBookFamily._dependencies,
        allTransitiveDependencies: CurrentBookFamily._allTransitiveDependencies,
        id: id,
      );

  CurrentBookProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Book?> Function(CurrentBookRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentBookProvider._internal(
        (ref) => create(ref as CurrentBookRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  FutureProviderElement<Book?> createElement() {
    return _CurrentBookProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentBookProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentBookRef on FutureProviderRef<Book?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _CurrentBookProviderElement extends FutureProviderElement<Book?>
    with CurrentBookRef {
  _CurrentBookProviderElement(super.provider);

  @override
  String get id => (origin as CurrentBookProvider).id;
}

String _$bookSearchHash() => r'e3c99c0ff2409df2e704ec6525e801af261ead9d';

/// Searches the Google Books API for books matching [query].
///
/// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
/// Returns an empty list on error or empty query.
///
/// Copied from [bookSearch].
@ProviderFor(bookSearch)
const bookSearchProvider = BookSearchFamily();

/// Searches the Google Books API for books matching [query].
///
/// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
/// Returns an empty list on error or empty query.
///
/// Copied from [bookSearch].
class BookSearchFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Searches the Google Books API for books matching [query].
  ///
  /// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
  /// Returns an empty list on error or empty query.
  ///
  /// Copied from [bookSearch].
  const BookSearchFamily();

  /// Searches the Google Books API for books matching [query].
  ///
  /// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
  /// Returns an empty list on error or empty query.
  ///
  /// Copied from [bookSearch].
  BookSearchProvider call(String query) {
    return BookSearchProvider(query);
  }

  @override
  BookSearchProvider getProviderOverride(
    covariant BookSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'bookSearchProvider';
}

/// Searches the Google Books API for books matching [query].
///
/// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
/// Returns an empty list on error or empty query.
///
/// Copied from [bookSearch].
class BookSearchProvider extends FutureProvider<List<Map<String, dynamic>>> {
  /// Searches the Google Books API for books matching [query].
  ///
  /// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
  /// Returns an empty list on error or empty query.
  ///
  /// Copied from [bookSearch].
  BookSearchProvider(String query)
    : this._internal(
        (ref) => bookSearch(ref as BookSearchRef, query),
        from: bookSearchProvider,
        name: r'bookSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$bookSearchHash,
        dependencies: BookSearchFamily._dependencies,
        allTransitiveDependencies: BookSearchFamily._allTransitiveDependencies,
        query: query,
      );

  BookSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(BookSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BookSearchProvider._internal(
        (ref) => create(ref as BookSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _BookSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BookSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BookSearchRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _BookSearchProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with BookSearchRef {
  _BookSearchProviderElement(super.provider);

  @override
  String get query => (origin as BookSearchProvider).query;
}

String _$addBookHash() => r'3e0d7291d9c6afb36942a1b4b97b85ffd8142312';

abstract class _$AddBook extends BuildlessAsyncNotifier<Book> {
  late final Map<String, dynamic> params;

  FutureOr<Book> build(Map<String, dynamic> params);
}

/// Searches Google Books by [query], creates a [Book], saves it to
/// the database, and returns the new [Book].
///
/// Throws [BookProviderException] if no results are found for the query.
///
/// Copied from [AddBook].
@ProviderFor(AddBook)
const addBookProvider = AddBookFamily();

/// Searches Google Books by [query], creates a [Book], saves it to
/// the database, and returns the new [Book].
///
/// Throws [BookProviderException] if no results are found for the query.
///
/// Copied from [AddBook].
class AddBookFamily extends Family<AsyncValue<Book>> {
  /// Searches Google Books by [query], creates a [Book], saves it to
  /// the database, and returns the new [Book].
  ///
  /// Throws [BookProviderException] if no results are found for the query.
  ///
  /// Copied from [AddBook].
  const AddBookFamily();

  /// Searches Google Books by [query], creates a [Book], saves it to
  /// the database, and returns the new [Book].
  ///
  /// Throws [BookProviderException] if no results are found for the query.
  ///
  /// Copied from [AddBook].
  AddBookProvider call(Map<String, dynamic> params) {
    return AddBookProvider(params);
  }

  @override
  AddBookProvider getProviderOverride(covariant AddBookProvider provider) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'addBookProvider';
}

/// Searches Google Books by [query], creates a [Book], saves it to
/// the database, and returns the new [Book].
///
/// Throws [BookProviderException] if no results are found for the query.
///
/// Copied from [AddBook].
class AddBookProvider extends AsyncNotifierProviderImpl<AddBook, Book> {
  /// Searches Google Books by [query], creates a [Book], saves it to
  /// the database, and returns the new [Book].
  ///
  /// Throws [BookProviderException] if no results are found for the query.
  ///
  /// Copied from [AddBook].
  AddBookProvider(Map<String, dynamic> params)
    : this._internal(
        () => AddBook()..params = params,
        from: addBookProvider,
        name: r'addBookProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$addBookHash,
        dependencies: AddBookFamily._dependencies,
        allTransitiveDependencies: AddBookFamily._allTransitiveDependencies,
        params: params,
      );

  AddBookProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final Map<String, dynamic> params;

  @override
  FutureOr<Book> runNotifierBuild(covariant AddBook notifier) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(AddBook Function() create) {
    return ProviderOverride(
      origin: this,
      override: AddBookProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<AddBook, Book> createElement() {
    return _AddBookProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AddBookProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AddBookRef on AsyncNotifierProviderRef<Book> {
  /// The parameter `params` of this provider.
  Map<String, dynamic> get params;
}

class _AddBookProviderElement
    extends AsyncNotifierProviderElement<AddBook, Book>
    with AddBookRef {
  _AddBookProviderElement(super.provider);

  @override
  Map<String, dynamic> get params => (origin as AddBookProvider).params;
}

String _$updateBookStatusHash() => r'43d0305a4416f68ecf2ecf0ec0aea4de7eb79f2d';

abstract class _$UpdateBookStatus extends BuildlessAsyncNotifier<void> {
  late final String bookId;
  late final ReadingStatus status;

  FutureOr<void> build(String bookId, ReadingStatus status);
}

/// Updates the reading status of a book and its associated dates.
///
/// Parameters:
///   - `bookId`: the book's UUID
///   - `status`: the new [ReadingStatus]
///
/// Copied from [UpdateBookStatus].
@ProviderFor(UpdateBookStatus)
const updateBookStatusProvider = UpdateBookStatusFamily();

/// Updates the reading status of a book and its associated dates.
///
/// Parameters:
///   - `bookId`: the book's UUID
///   - `status`: the new [ReadingStatus]
///
/// Copied from [UpdateBookStatus].
class UpdateBookStatusFamily extends Family<AsyncValue<void>> {
  /// Updates the reading status of a book and its associated dates.
  ///
  /// Parameters:
  ///   - `bookId`: the book's UUID
  ///   - `status`: the new [ReadingStatus]
  ///
  /// Copied from [UpdateBookStatus].
  const UpdateBookStatusFamily();

  /// Updates the reading status of a book and its associated dates.
  ///
  /// Parameters:
  ///   - `bookId`: the book's UUID
  ///   - `status`: the new [ReadingStatus]
  ///
  /// Copied from [UpdateBookStatus].
  UpdateBookStatusProvider call(String bookId, ReadingStatus status) {
    return UpdateBookStatusProvider(bookId, status);
  }

  @override
  UpdateBookStatusProvider getProviderOverride(
    covariant UpdateBookStatusProvider provider,
  ) {
    return call(provider.bookId, provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'updateBookStatusProvider';
}

/// Updates the reading status of a book and its associated dates.
///
/// Parameters:
///   - `bookId`: the book's UUID
///   - `status`: the new [ReadingStatus]
///
/// Copied from [UpdateBookStatus].
class UpdateBookStatusProvider
    extends AsyncNotifierProviderImpl<UpdateBookStatus, void> {
  /// Updates the reading status of a book and its associated dates.
  ///
  /// Parameters:
  ///   - `bookId`: the book's UUID
  ///   - `status`: the new [ReadingStatus]
  ///
  /// Copied from [UpdateBookStatus].
  UpdateBookStatusProvider(String bookId, ReadingStatus status)
    : this._internal(
        () => UpdateBookStatus()
          ..bookId = bookId
          ..status = status,
        from: updateBookStatusProvider,
        name: r'updateBookStatusProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$updateBookStatusHash,
        dependencies: UpdateBookStatusFamily._dependencies,
        allTransitiveDependencies:
            UpdateBookStatusFamily._allTransitiveDependencies,
        bookId: bookId,
        status: status,
      );

  UpdateBookStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.bookId,
    required this.status,
  }) : super.internal();

  final String bookId;
  final ReadingStatus status;

  @override
  FutureOr<void> runNotifierBuild(covariant UpdateBookStatus notifier) {
    return notifier.build(bookId, status);
  }

  @override
  Override overrideWith(UpdateBookStatus Function() create) {
    return ProviderOverride(
      origin: this,
      override: UpdateBookStatusProvider._internal(
        () => create()
          ..bookId = bookId
          ..status = status,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        bookId: bookId,
        status: status,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<UpdateBookStatus, void> createElement() {
    return _UpdateBookStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateBookStatusProvider &&
        other.bookId == bookId &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, bookId.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateBookStatusRef on AsyncNotifierProviderRef<void> {
  /// The parameter `bookId` of this provider.
  String get bookId;

  /// The parameter `status` of this provider.
  ReadingStatus get status;
}

class _UpdateBookStatusProviderElement
    extends AsyncNotifierProviderElement<UpdateBookStatus, void>
    with UpdateBookStatusRef {
  _UpdateBookStatusProviderElement(super.provider);

  @override
  String get bookId => (origin as UpdateBookStatusProvider).bookId;
  @override
  ReadingStatus get status => (origin as UpdateBookStatusProvider).status;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
