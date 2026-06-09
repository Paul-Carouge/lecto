import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service that calls the Google Books API (no API key needed for search).
///
/// All public methods return maps with a consistent schema:
///   id, title, author, isbn, coverUrl, description,
///   pageCount, categories, publisher, publishedDate, language
class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1';

  /// Searches for books by [query] string.
  ///
  /// Returns a list of up to 40 book maps matching the query.
  /// Throws [GoogleBooksException] on network or API errors.
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/volumes').replace(
      queryParameters: {
        'q': query.trim(),
        'maxResults': '40',
        'printType': 'books',
        'orderBy': 'relevance',
        'langRestrict': 'fr',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw GoogleBooksException(
          'Google Books API returned status ${response.statusCode}',
          response.statusCode,
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) return [];

      return items
          .map((item) => _parseVolume(item as Map<String, dynamic>))
          .where((book) => book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } on http.ClientException catch (e) {
      throw GoogleBooksException('Network error: ${e.message}', null);
    } on FormatException catch (e) {
      throw GoogleBooksException('Invalid response format: ${e.message}', null);
    }
  }

  /// Fetches a single book by its ISBN (10 or 13 digits).
  ///
  /// Returns `null` if no book is found for that ISBN.
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final sanitized = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (sanitized.isEmpty) return null;

    final uri = Uri.parse('$_baseUrl/volumes').replace(
      queryParameters: {
        'q': 'isbn:$sanitized',
        'maxResults': '1',
        'printType': 'books',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) return null;

      return _parseVolume(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Fetches popular books in a given [category] (genre).
  ///
  /// Returns a list of up to 20 books. Useful for the recommendations engine
  /// and the "similar books" feature.
  Future<List<Map<String, dynamic>>> getSimilarBooks(String category) async {
    if (category.trim().isEmpty) return [];

    final uri = Uri.parse('$_baseUrl/volumes').replace(
      queryParameters: {
        'q': 'subject:${category.trim()}',
        'maxResults': '20',
        'printType': 'books',
        'orderBy': 'relevance',
        'langRestrict': 'fr',
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) return [];

      return items
          .map((item) => _parseVolume(item as Map<String, dynamic>))
          .where((book) => book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // Internal helpers
  // ============================================================

  /// Parses a single volume item from the Google Books API response
  /// into a flat map with a consistent schema.
  Map<String, dynamic> _parseVolume(Map<String, dynamic> volume) {
    final info = volume['volumeInfo'] as Map<String, dynamic>? ?? {};
    final saleInfo = volume['saleInfo'] as Map<String, dynamic>? ?? {};

    // Extract ISBN from industryIdentifiers
    String? isbn;
    final identifiers = info['industryIdentifiers'] as List<dynamic>?;
    if (identifiers != null) {
      // Prefer ISBN_13, fall back to ISBN_10
      final isbn13 = identifiers.cast<Map<String, dynamic>>().firstWhere(
        (id) => id['type'] == 'ISBN_13',
        orElse: () => <String, dynamic>{},
      );
      final isbn10 = identifiers.cast<Map<String, dynamic>>().firstWhere(
        (id) => id['type'] == 'ISBN_10',
        orElse: () => <String, dynamic>{},
      );
      isbn = (isbn13['identifier'] ?? isbn10['identifier']) as String?;
    }

    // Extract authors
    final authors = info['authors'] as List<dynamic>?;
    final author = (authors != null && authors.isNotEmpty)
        ? authors.cast<String>().join(', ')
        : 'Unknown Author';

    // Extract categories (genres)
    final categories = info['categories'] as List<dynamic>?;

    // Extract cover URL (prefer large thumbnail)
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl;
    if (imageLinks != null) {
      coverUrl = (imageLinks['large'] ??
              imageLinks['medium'] ??
              imageLinks['thumbnail'])
          as String?;
      // Upgrade http:// to https:// for security
      if (coverUrl != null && coverUrl.startsWith('http://')) {
        coverUrl = coverUrl.replaceFirst('http://', 'https://');
      }
    }

    return {
      'id': volume['id'] as String? ?? '',
      'title': (info['title'] as String?)?.trim(),
      'author': author,
      'isbn': isbn,
      'coverUrl': coverUrl,
      'description': info['description'] as String?,
      'pageCount': info['pageCount'] as int?,
      'categories': categories?.cast<String>().toList() ?? <String>[],
      'publisher': info['publisher'] as String?,
      'publishedDate': info['publishedDate'] as String?,
      'language': info['language'] as String?,
    };
  }
}

/// Exception thrown by [GoogleBooksService] on API errors.
class GoogleBooksException implements Exception {
  final String message;
  final int? statusCode;

  const GoogleBooksException(this.message, this.statusCode);

  @override
  String toString() => 'GoogleBooksException: $message (status: $statusCode)';
}
