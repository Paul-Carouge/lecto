import 'dart:convert';

import 'package:http/http.dart' as http;

/// Multi-source book search service that combines OpenLibrary + BnF (French library).
///
/// Strategy:
///   1. Call OpenLibrary first (fast, free, good general coverage)
///   2. In parallel, call BnF API for French results
///   3. Merge results: OpenLibrary first, then BnF (deduplicated by normalized title + author)
///   4. Deduplication: normalize titles (lowercase, trim), match by similarity
///   5. Return merged list (max 40 results)
///
/// All public methods return maps with a consistent schema:
///   id, title, author, isbn, coverUrl, description,
///   pageCount, categories, publisher, publishedDate, language, source
class BookSearchService {
  // ---- OpenLibrary constants ----
  static const String _olSearchUrl = 'https://openlibrary.org/search.json';
  static const String _olBaseUrl = 'https://openlibrary.org';

  // ---- BnF constants ----
  static const String _bnfBaseUrl = 'https://catalogue.bnf.fr/api/SRU';
  static const int _bnfTimeoutSeconds = 10;

  /// Searches for books by [query] string.
  ///
  /// Returns a list of up to 40 book maps matching the query.
  /// Results from OpenLibrary come first, then BnF results (deduplicated).
  Future<List<Map<String, dynamic>>> searchBooks(String query) async {
    if (query.trim().isEmpty) return [];

    // Run OpenLibrary (no language restriction) and BnF searches in parallel
    final results = await Future.wait([
      _searchOpenLibrary(query),
      _searchBnf(query),
    ]);

    final openLibraryBooks = results[0] as List<Map<String, dynamic>>;
    final bnfBooks = results[1] as List<Map<String, dynamic>>;

    // Deduplicate BnF results against OpenLibrary results
    final dedupedBnf = _deduplicate(bnfBooks, openLibraryBooks);

    // Merge: OpenLibrary first, then BnF, max 40 results
    final merged = <Map<String, dynamic>>[
      ...openLibraryBooks,
      ...dedupedBnf,
    ];

    return merged.take(40).toList();
  }

  /// Fetches a single book by its ISBN (10 or 13 digits).
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final sanitized = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (sanitized.isEmpty) return null;

    // Try OpenLibrary first
    try {
      final olBook = await _getBookByIsbnOl(sanitized);
      if (olBook != null) return olBook;
    } catch (_) {
      // Fall through to BnF
    }

    // Fall back to BnF
    try {
      return await _getBookByIsbnBnf(sanitized);
    } catch (_) {
      return null;
    }
  }

  /// Fetches books in a given category/subject.
  Future<List<Map<String, dynamic>>> getSimilarBooks(String category) async {
    if (category.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(_olSearchUrl).replace(queryParameters: {
        'q': 'subject:${category.trim()}',
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
          .map((doc) => _parseOlDoc(doc as Map<String, dynamic>))
          .where((book) =>
              book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // OpenLibrary internals
  // ============================================================

  Future<List<Map<String, dynamic>>> _searchOpenLibrary(String query) async {
    try {
      final uri = Uri.parse(_olSearchUrl).replace(queryParameters: {
        'q': query.trim(),
        'limit': '40',
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
          .map((doc) => _parseOlDoc(doc as Map<String, dynamic>))
          .where((book) =>
              book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getBookByIsbnOl(String isbn) async {
    try {
      final uri = Uri.parse('$_olBaseUrl/isbn/$isbn.json');
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
        'isbn': isbn,
        'coverUrl': 'https://covers.openlibrary.org/b/ISBN/$isbn-L.jpg',
        'description': _extractOlDescription(data),
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
        'source': 'openlibrary',
      };
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseOlDoc(Map<String, dynamic> doc) {
    final authors = doc['author_name'] as List<dynamic>?;
    final author = (authors != null && authors.isNotEmpty)
        ? authors.cast<String>().join(', ')
        : 'Unknown Author';

    final isbns = doc['isbn'] as List<dynamic>?;
    final isbn =
        (isbns != null && isbns.isNotEmpty) ? isbns.cast<String>().first : null;

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
      'description': null,
      'pageCount': doc['number_of_pages_median'] as int?,
      'categories': subjects?.cast<String>().take(5).toList() ?? <String>[],
      'publisher': (doc['publisher'] as List<dynamic>?)
              ?.cast<String>()
              .firstOrNull ??
          null,
      'publishedDate': doc['first_publish_year']?.toString(),
      'language': languages?.cast<String>().firstOrNull ?? 'fr',
      'source': 'openlibrary',
    };
  }

  String? _extractOlDescription(Map<String, dynamic> data) {
    final desc = data['description'];
    if (desc is String) return desc;
    if (desc is Map<String, dynamic>) return desc['value'] as String?;
    return null;
  }

  // ============================================================
  // BnF (Bibliothèque nationale de France) internals
  // ============================================================

  /// Searches the BnF SRU API for books matching [query].
  ///
  /// Returns parsed book maps with `source: 'bnf'`.
  Future<List<Map<String, dynamic>>> _searchBnf(String query) async {
    try {
      final uri = Uri.parse(_bnfBaseUrl).replace(queryParameters: {
        'version': '1.2',
        'operation': 'searchRetrieve',
        'query': 'bib.anywhere all "${query.trim()}"',
        'recordSchema': 'dc',
        'maximumRecords': '20',
      });

      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/xml'},
          )
          .timeout(Duration(seconds: _bnfTimeoutSeconds));

      if (response.statusCode != 200) return [];

      return _parseBnfResponse(response.body);
    } catch (_) {
      return [];
    }
  }

  /// Parses the BnF SRU XML response using simple string operations.
  ///
  /// The XML format uses Dublin Core elements wrapped in SRW records:
  ///   <srw:record><srw:recordData><oai_dc:dc>
  ///     <dc:title>...</dc:title>
  ///     <dc:creator>...</dc:creator>
  ///     ...
  ///   </oai_dc:dc></srw:recordData></srw:record>
  List<Map<String, dynamic>> _parseBnfResponse(String xml) {
    // Split the XML into individual records
    final recordPattern = RegExp(
      r'<srw:record>(.*?)</srw:record>',
      dotAll: true,
    );
    final records = recordPattern.allMatches(xml);

    final results = <Map<String, dynamic>>[];

    for (final match in records) {
      final recordXml = match.group(1) ?? '';

      // Extract Dublin Core fields using simple regex
      final title = _extractDcElement(recordXml, 'title');
      final creator = _extractDcElement(recordXml, 'creator');
      final identifier = _extractDcElement(recordXml, 'identifier');
      final publisher = _extractDcElement(recordXml, 'publisher');
      final date = _extractDcElement(recordXml, 'date');
      final description = _extractDcElement(recordXml, 'description');
      final language = _extractDcElement(recordXml, 'language');

      // Extract multiple subjects
      final subjectPattern = RegExp(
        r'<dc:subject[^>]*>(.*?)</dc:subject>',
        dotAll: true,
      );
      final subjects = subjectPattern
          .allMatches(recordXml)
          .map((m) => m.group(1)?.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      if (title == null || title.isEmpty) continue;

      // Extract ISBN from identifiers (multiple identifiers possible)
      final isbn = _extractIsbnFromIdentifiers(identifier, recordXml);

      // Build cover URL from ISBN if available
      String? coverUrl;
      if (isbn != null) {
        coverUrl = 'https://covers.openlibrary.org/b/ISBN/$isbn-L.jpg';
      }

      results.add({
        'id': 'bnf://${Uri.encodeComponent(title)}',
        'title': title.trim(),
        'author': creator?.trim() ?? 'Unknown Author',
        'isbn': isbn,
        'coverUrl': coverUrl,
        'description': description?.trim(),
        'pageCount': null, // BnF DC schema doesn't include page count
        'categories': subjects,
        'publisher': publisher?.trim(),
        'publishedDate': date?.trim(),
        'language': language?.trim() ?? 'fr',
        'source': 'bnf',
      });
    }

    return results;
  }

  /// Extracts a single Dublin Core element value from XML.
  String? _extractDcElement(String xml, String element) {
    final pattern = RegExp(
      r'<dc:' + element + r'[^>]*>(.*?)</dc:' + element + r'>',
      dotAll: true,
    );
    final match = pattern.firstMatch(xml);
    if (match == null) return null;
    final value = match.group(1)?.trim();
    return (value != null && value.isNotEmpty) ? value : null;
  }

  /// Extracts an ISBN from BnF identifiers.
  ///
  /// BnF returns identifiers like:
  ///   <dc:identifier>urn:isbn:9782070360028</dc:identifier>
  ///   <dc:identifier>http://catalogue.bnf.fr/ark:/12148/cb...</dc:identifier>
  String? _extractIsbnFromIdentifiers(String? firstIdentifier, String recordXml) {
    // First, check all <dc:identifier> elements for ISBN patterns
    final idPattern = RegExp(
      r'<dc:identifier[^>]*>(.*?)</dc:identifier>',
      dotAll: true,
    );
    final ids = idPattern.allMatches(recordXml);

    for (final idMatch in ids) {
      final idValue = idMatch.group(1)?.trim() ?? '';
      // Check for ISBN URN format: urn:isbn:XXXXXXXXXXXX
      final isbnMatch =
          RegExp(r'urn:isbn:([0-9Xx]{10,13})').firstMatch(idValue);
      if (isbnMatch != null) {
        return isbnMatch.group(1);
      }
      // Check for bare ISBN in identifier
      final bareIsbn = RegExp(r'\b(?:ISBN[- ]*)?([0-9Xx]{10,13})\b')
          .firstMatch(idValue);
      if (bareIsbn != null) {
        return bareIsbn.group(1);
      }
    }

    // Fall back to the first identifier if it looks like an ISBN
    if (firstIdentifier != null) {
      final fallback = RegExp(r'([0-9Xx]{10,13})').firstMatch(firstIdentifier);
      if (fallback != null) return fallback.group(1);
    }

    return null;
  }

  /// Fetches a book by ISBN from BnF.
  Future<Map<String, dynamic>?> _getBookByIsbnBnf(String isbn) async {
    try {
      final uri = Uri.parse(_bnfBaseUrl).replace(queryParameters: {
        'version': '1.2',
        'operation': 'searchRetrieve',
        'query': 'bib.anywhere all "$isbn"',
        'recordSchema': 'dc',
        'maximumRecords': '1',
      });

      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/xml'},
          )
          .timeout(Duration(seconds: _bnfTimeoutSeconds));

      if (response.statusCode != 200) return null;

      final results = _parseBnfResponse(response.body);
      return results.isNotEmpty ? results.first : null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Deduplication
  // ============================================================

  /// Deduplicates [candidates] against [existing] books.
  ///
  /// A candidate is considered a duplicate if its normalized title + author
  /// matches any book in [existing].
  List<Map<String, dynamic>> _deduplicate(
    List<Map<String, dynamic>> candidates,
    List<Map<String, dynamic>> existing,
  ) {
    final existingKeys = existing.map((b) => _normalizeKey(b)).toSet();

    return candidates.where((candidate) {
      final key = _normalizeKey(candidate);
      return !existingKeys.contains(key);
    }).toList();
  }

  /// Creates a normalized deduplication key from a book map.
  ///
  /// Uses title + first author, lowercased, trimmed, with special chars removed.
  String _normalizeKey(Map<String, dynamic> book) {
    final title = (book['title'] as String? ?? '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    final author = (book['author'] as String? ?? '')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');

    return '$title|$author';
  }
}
