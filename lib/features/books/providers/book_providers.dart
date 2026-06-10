import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/services/book_search_service.dart';

part 'book_providers.g.dart';

// ============================================================
// Singleton service instance
// ============================================================

final _bookSearchService = BookSearchService();

// ============================================================
// All books
// ============================================================

/// Provides the full list of books from the database, ordered by
/// date added (newest first).
@Riverpod(keepAlive: true)
Future<List<Book>> allBooks(AllBooksRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getAllBooks();
}

// ============================================================
// Books filtered by reading status
// ============================================================

/// Provides books filtered by [ReadingStatus].
@Riverpod(keepAlive: true)
Future<List<Book>> booksByStatus(BooksByStatusRef ref, ReadingStatus status) async {
  final db = ref.watch(databaseProvider);
  return db.getBooksByStatus(status);
}

// ============================================================
// Single book by ID
// ============================================================

/// Provides a single [Book] by its ID.
/// Returns `null` if no book with that ID exists.
@Riverpod(keepAlive: true)
Future<Book?> currentBook(CurrentBookRef ref, String id) async {
  final db = ref.watch(databaseProvider);
  return db.getBook(id);
}

// ============================================================
// Add a book (search Google Books, then save to DB)
// ============================================================

/// Searches Google Books by [query], creates a [Book], saves it to
/// the database, and returns the new [Book].
///
/// Throws [BookProviderException] if no results are found for the query.
@Riverpod(keepAlive: true)
class AddBook extends _$AddBook {
  @override
  Future<Book> build(Map<String, dynamic> params) {
    throw UnimplementedError('Use ref.read(addBookProvider.notifier).addBook(query) instead');
  }

  /// Searches for [query] on Google Books, picks the first result,
  /// creates a database entry, and returns the saved [Book].
  Future<Book> addBook(String query) async {
    final result = await _bookSearchService.searchBooks(query);
    if (result.isEmpty) {
      throw BookProviderException('No books found for "$query"');
    }

    final bookData = result.books.first;
    final db = ref.read(databaseProvider);

    // Convert categories list to List<String>
    final categories = (bookData['categories'] as List<dynamic>?)
            ?.cast<String>()
            .toList() ??
        <String>[];

    final book = Book(
      id: '',
      title: bookData['title'] as String? ?? 'Unknown Title',
      author: bookData['author'] as String? ?? 'Unknown Author',
      isbn: bookData['isbn'] as String?,
      coverUrl: bookData['coverUrl'] as String?,
      description: bookData['description'] as String?,
      pageCount: bookData['pageCount'] as int?,
      categories: categories,
      publisher: bookData['publisher'] as String?,
      publishedDate: bookData['publishedDate'] as String?,
      language: bookData['language'] as String?,
      status: ReadingStatus.wantToRead,
    );

    final saved = await db.addBook(book);

    // Invalidate dependent providers
    ref.invalidate(allBooksProvider);
    ref.invalidate(booksByStatusProvider);

    return saved;
  }
}

// ============================================================
// Update book status
// ============================================================

/// Updates the reading status of a book and its associated dates.
///
/// Parameters:
///   - `bookId`: the book's UUID
///   - `status`: the new [ReadingStatus]
@Riverpod(keepAlive: true)
class UpdateBookStatus extends _$UpdateBookStatus {
  @override
  Future<void> build(String bookId, ReadingStatus status) {
    throw UnimplementedError('Use ref.read(updateBookStatusProvider(bookId, status).notifier).applyUpdate()');
  }

  /// Applies the status update. Automatically sets `dateStarted` when
  /// transitioning to `reading`, and `dateFinished` when transitioning to `finished`.
  Future<void> applyUpdate() async {
    final db = ref.read(databaseProvider);
    final bookId = this.bookId;
    final status = this.status;
    final book = db.getBook(bookId);
    if (book == null) return;

    final now = DateTime.now();
    final updates = <String, dynamic>{
      'status': status.name,
      if (status == ReadingStatus.reading)
        'date_started': (book.dateStarted ?? now).toIso8601String(),
      if (status == ReadingStatus.finished)
        'date_finished': now.toIso8601String(),
    };

    db.updateBook(bookId, updates);

    // Invalidate dependent providers
    ref.invalidate(allBooksProvider);
    ref.invalidate(booksByStatusProvider);
    ref.invalidate(currentBookProvider(bookId));
  }
}

// ============================================================
// Search Google Books
// ============================================================

/// Searches the Google Books API for books matching [query].
///
/// Returns a list of book maps with a consistent schema (see [GoogleBooksService]).
/// Returns an empty list on error or empty query.
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> bookSearch(BookSearchRef ref, String query) async {
  if (query.trim().isEmpty) return [];
  final result = await _bookSearchService.searchBooks(query);
  return result.books;
}

// ============================================================
// Total pages read for a book
// ============================================================

/// Provides the total number of pages read across all sessions for a [bookId].
@Riverpod(keepAlive: true)
Future<int> bookPagesRead(BookPagesReadRef ref, String bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getTotalPagesReadForBook(bookId);
}

/// Provides the number of pages remaining for a book (pageCount - pagesRead).
/// Returns null if no page count is set.
@Riverpod(keepAlive: true)
Future<int?> bookRemainingPages(BookRemainingPagesRef ref, String bookId) async {
  final db = ref.watch(databaseProvider);
  final book = db.getBook(bookId);
  if (book == null || book.pageCount == null) return null;
  final pagesRead = db.getTotalPagesReadForBook(bookId);
  final remaining = book.pageCount! - pagesRead;
  return remaining > 0 ? remaining : 0;
}

/// Provides the active (unfinished) reading session for a book, if any.
@Riverpod(keepAlive: true)
Future<ReadingSession?> activeBookSession(ActiveBookSessionRef ref, String bookId) async {
  final db = ref.watch(databaseProvider);
  return db.getActiveSessionForBook(bookId);
}

// ============================================================
// Exception
// ============================================================

/// Exception thrown by book providers on domain errors.
class BookProviderException implements Exception {
  final String message;
  const BookProviderException(this.message);

  @override
  String toString() => 'BookProviderException: $message';
}
