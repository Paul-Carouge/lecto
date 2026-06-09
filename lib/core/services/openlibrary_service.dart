import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service that calls the OpenLibrary API (free, no API key needed).
///
/// Endpoints used:
///   - Search: https://openlibrary.org/search.json?q=...&language=fre&limit=40
///   - Works:  https://openlibrary.org/works/OL...W.json
///   - Covers: https://covers.openlibrary.org/b/id/{id}-L.jpg
///             https://covers.openlibrary.org/b/ISBN/{isbn}-L.jpg
///   - ISBN:   https://openlibrary.org/isbn/{isbn}.json
///
/// All public methods return maps with a consistent schema:
///   id, title, author, isbn, coverUrl, description,
///   pageCount, categories, publisher, publishedDate, language
class OpenLibraryService {
  static const String _searchUrl = 'https://openlibrary.org/search.json';
  static const String _baseUrl = 'https://openlibrary.org';

  /// Searches for books by [query] string.
  ///
  /// Returns a list of up to 40 book maps matching the query.
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_searchUrl).replace(queryParameters: {
      'q': query.trim(),
      'language': 'fre',
      'limit': '40',
      'fields': 'key,title,author_name,first_publish_year,isbn,cover_i,'
          'publisher,subject,language,number_of_pages_median',
    });

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw OpenLibraryException(
          'OpenLibrary returned status ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>?;

      if (docs == null || docs.isEmpty) return [];

      return docs
          .map((doc) => _parseDoc(doc as Map<String, dynamic>))
          .where((book) =>
              book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } on http.ClientException catch (e) {
      throw OpenLibraryException('Network error: ${e.message}', null);
    } on FormatException catch (e) {
      throw OpenLibraryException('Invalid response: ${e.message}', null);
    }
  }

  /// Fetches a single book by its ISBN (10 or 13 digits).
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final sanitized = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (sanitized.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/isbn/$sanitized.json');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return {
        'id': data['key'] as String? ?? '',
        'title': data['title'] as String?,
        'author': (data['authors'] as List<dynamic>?)
                ?.map((a) => a['name'] ?? '')
                .cast<String>()
                .join(', ') ??
            'Unknown Author',
        'isbn': sanitized,
        'coverUrl': 'https://covers.openlibrary.org/b/ISBN/$sanitized-L.jpg',
        'description': _extractDescription(data),
        'pageCount': data['number_of_pages'] as int?,
        'categories': (data['subjects'] as List<dynamic>?)
                ?.cast<String>()
                .take(5)
                .toList() ??
            <String>[],
        'publisher': (data['publishers'] as List<dynamic>?)
                ?.cast<String>()
                .firstOrNull ??
            null,
        'publishedDate': data['publish_date'] as String?,
        'language': 'fr',
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetches books in a given category/subject.
  Future<List<Map<String, dynamic>>> getSimilarBooks(
      String subject) async {
    if (subject.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_searchUrl).replace(queryParameters: {
        'q': 'subject:${subject.trim()}',
        'language': 'fre',
        'limit': '20',
        'fields': 'key,title,author_name,first_publish_year,isbn,cover_i,'
            'publisher,subject,language,number_of_pages_median',
      });

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>?;

      if (docs == null || docs.isEmpty) return [];

      return docs
          .map((doc) => _parseDoc(doc as Map<String, dynamic>))
          .where((book) =>
              book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // Internal helpers
  // ============================================================

  /// Parses a search result doc from the OpenLibrary API
  Map<String, dynamic> _parseDoc(Map<String, dynamic> doc) {
    final authors = doc['author_name'] as List<dynamic>?;
    final author = (authors != null && authors.isNotEmpty)
        ? authors.cast<String>().join(', ')
        : 'Unknown Author';

    final isbns = doc['isbn'] as List<dynamic>?;
    final isbn = (isbns != null && isbns.isNotEmpty)
        ? isbns.cast<String>().first
        : null;

    final coverId = doc['cover_i'] as int?;
    String? coverUrl;
    if (coverId != null) {
      coverUrl = 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
    } else if (isbn != null) {
      coverUrl = 'https://covers.openlibrary.org/b/ISBN/$isbn-L.jpg';
    }

    final subjects = doc['subject'] as List<dynamic>?;
    final languages = doc['language'] as List<dynamic>?;

    return {
      'id': doc['key'] as String? ?? '',
      'title': (doc['title'] as String?)?.trim(),
      'author': author,
      'isbn': isbn,
      'coverUrl': coverUrl,
      'description': null, // OpenLibrary search doesn't return descriptions
      'pageCount': doc['number_of_pages_median'] as int?,
      'categories': subjects?.cast<String>().take(5).toList() ?? <String>[],
      'publisher': (doc['publisher'] as List<dynamic>?)
              ?.cast<String>()
              .firstOrNull ??
          null,
      'publishedDate': doc['first_publish_year']?.toString(),
      'language': languages?.cast<String>().firstOrNull ?? 'fr',
    };
  }

  /// Extracts description from a work/edition detail response
  String? _extractDescription(Map<String, dynamic> data) {
    final desc = data['description'];
    if (desc is String) return desc;
    if (desc is Map<String, dynamic>) return desc['value'] as String?;
    return null;
  }
}

/// Exception thrown by [OpenLibraryService] on API errors.
class OpenLibraryException implements Exception {
  final String message;
  final int? statusCode;

  const OpenLibraryException(this.message, this.statusCode);

  @override
  String toString() => 'OpenLibraryException: $message (status: $statusCode)';
}
