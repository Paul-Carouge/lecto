import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Result wrapper that carries search results plus an optional suggestion
/// when the original query didn't match but a close variant did.
class SearchResult {
  final List<Map<String, dynamic>> books;
  final String? suggestedQuery;

  const SearchResult(this.books, this.suggestedQuery);

  bool get isEmpty => books.isEmpty;
  bool get hasSuggestion => suggestedQuery != null;
}

/// Multi-source book search service combining OpenLibrary + BnF + Google Books.
///
/// Strategy (applied in order):
///   1. Exact query search on all sources
///   2. If 0 results, extract meaningful keywords (strip French articles/prepositions)
///   3. Try each keyword combination (longest to shortest)
///   4. Try single-word searches for each keyword
///   5. If results found with a different query, return them with suggestedQuery hint
///   6. Google Books is called first (when configured) — best coverage for commercial books
///
/// Coverage:
///   - OpenLibrary: ~40M books (open data, no key needed)
///   - BnF SRU: ~16M notices (French national library, no key needed)
///   - Google Books: ~40M+ with full metadata (requires API key for production use)
class BookSearchService {
  // ---- French stop-words to strip for keyword extraction ----
  static const Set<String> _frenchStopWords = {
    'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une',
    'l\'', 'd\'', 'l', 'd',
    'et', 'ou', 'en', 'au', 'aux', 'sur', 'pour', 'par', 'avec',
    'ce', 'cet', 'cette', 'ces',
    'mon', 'ton', 'son', 'ma', 'ta', 'sa',
    'mes', 'tes', 'ses', 'nos', 'vos', 'leurs',
    'notre', 'votre', 'leur',
    'que', 'qui', 'dans', 'sans', 'vers', 'chez',
    'est', 'sont', 'a', 'ont',
    'pas', 'plus', 'très', 'peu',
  };

  // ---- Known author name parts (to avoid stripping as stop-words) ----
  static const Set<String> _authorNameTokens = {
    'noir', 'noire', 'rouge', 'vert', 'blanc', 'noirs', 'noires',
    'roy', 'king', 'lee', 'ford', 'rice', 'dick', 'stone',
    'wood', 'hill', 'bell', 'wells', 'green', 'black', 'white',
    'blackman',
    // Common French surname prefixes
    'le', 'la', 'de', 'du', 'des', 'd',
  };

  // ---- OpenLibrary constants ----
  static const String _olSearchUrl = 'https://openlibrary.org/search.json';
  static const String _olBaseUrl = 'https://openlibrary.org';

  // ---- BnF SRU constants ----
  static const String _bnfBaseUrl = 'https://catalogue.bnf.fr/api/SRU';
  static const int _bnfTimeoutSeconds = 10;

  // ---- Google Books constants ----
  static const String _gbBaseUrl = 'https://www.googleapis.com/books/v1';
  String? _googleApiKey;

  /// Optional Google Books API key.
  /// When set, Google Books becomes the primary source (best metadata, covers, ISBN).
  /// Get a key at https://console.cloud.google.com/apis/credentials
  set googleApiKey(String? key) => _googleApiKey = key;

  // ============================================================
  // Public API
  // ============================================================

  /// Searches books with intelligent fallback.
  ///
  /// Returns a [SearchResult] containing matching books and an optional
  /// [suggestedQuery] when results were found with a modified query.
  Future<SearchResult> searchBooks(String query) async {
    if (query.trim().isEmpty) return const SearchResult([], null);

    // Phase 1: Exact query on all sources
    final exactResults = await _searchAllSources(query);
    if (exactResults.isNotEmpty) {
      return SearchResult(exactResults.take(40).toList(), null);
    }

    // Phase 2: Intelligent fallback — extract meaningful keywords
    final keywords = _extractKeywords(query);
    final seenQueries = <String>{};

    // Try progressively shorter keyword combinations
    for (int len = keywords.length; len >= 1; len--) {
      // Try each sliding window of this length
      for (int start = 0; start + len <= keywords.length; start++) {
        final subQuery = keywords.sublist(start, start + len).join(' ');
        if (subQuery.length < 3 || seenQueries.contains(subQuery)) continue;
        seenQueries.add(subQuery);

        final results = await _searchAllSources(subQuery);
        if (results.isNotEmpty) {
          return SearchResult(
            results.take(40).toList(),
            subQuery, // suggest what actually worked
          );
        }
      }
    }

    // Phase 3: Last resort — each keyword individually
    final allSingles = <Map<String, dynamic>>[];
    final seenTitles = <String>{};
    for (final kw in keywords) {
      if (kw.length < 3) continue;
      final results = await _searchAllSources(kw);
      for (final book in results) {
        final title = (book['title'] as String? ?? '').toLowerCase().trim();
        if (title.isNotEmpty && seenTitles.add(title)) {
          allSingles.add(book);
        }
      }
      if (allSingles.length >= 20) break;
    }

    if (allSingles.isNotEmpty) {
      return SearchResult(allSingles.take(20).toList(), keywords.join(' '));
    }

    return const SearchResult([], null);
  }

  /// Fetches a single book by ISBN.
  Future<Map<String, dynamic>?> getBookByIsbn(String isbn) async {
    final sanitized = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (sanitized.isEmpty) return null;

    // Try Google Books first (best ISBN coverage)
    if (_googleApiKey != null) {
      try {
        return await _getBookByIsbnGb(sanitized);
      } catch (_) {
        // Fall through
      }
    }

    // Try OpenLibrary
    try {
      final olBook = await _getBookByIsbnOl(sanitized);
      if (olBook != null) return olBook;
    } catch (_) {
      // Fall through
    }

    // Fall back to BnF
    try {
      return await _getBookByIsbnBnf(sanitized);
    } catch (_) {
      return null;
    }
  }

  /// Fetches books in a given subject/category.
  Future<List<Map<String, dynamic>>> getSimilarBooks(String category) async {
    if (category.trim().isEmpty) return [];

    final futures = <Future<List<Map<String, dynamic>>>>[
      _searchOpenLibrary('subject:${category.trim()}'),
    ];

    if (_googleApiKey != null) {
      futures.add(_searchGoogleBooks('subject:${category.trim()}'));
    }

    final results = await Future.wait(futures);
    final allBooks = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final list in results) {
      for (final book in list) {
        final key = _normalizeKey(book);
        if (seen.add(key)) {
          allBooks.add(book);
        }
      }
    }

    return allBooks.take(20).toList();
  }

  /// Converts a Google Books volume ID to our standard format.
  /// Useful for deep-linking from search suggestions.
  Future<Map<String, dynamic>?> getBookByGoogleId(String volumeId) async {
    if (_googleApiKey == null) return null;
    try {
      final uri = Uri.parse('$_gbBaseUrl/volumes/$volumeId')
          .replace(queryParameters: {'key': _googleApiKey});
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      return _parseGbVolume(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Multi-source search
  // ============================================================

  /// Searches all configured sources for [query], returns deduplicated results.
  Future<List<Map<String, dynamic>>> _searchAllSources(String query) async {
    final futures = <Future<List<Map<String, dynamic>>>>[
      _searchOpenLibrary(query),
      _searchBnf(query),
    ];

    // Add Google Books if API key is configured
    if (_googleApiKey != null) {
      futures.add(_searchGoogleBooks(query));
    }

    final results = await Future.wait(futures);
    final allBooks = <Map<String, dynamic>>[];
    final seen = <String>{};

    // Merge in priority order: Google Books → OpenLibrary → BnF
    for (final list in results) {
      for (final book in list) {
        final key = _normalizeKey(book);
        if (seen.add(key)) {
          allBooks.add(book);
        }
      }
    }

    return allBooks;
  }

  // ============================================================
  // Smart fallback: keyword extraction
  // ============================================================

  /// Extracts meaningful keywords from a query, stripping French stop-words.
  ///
  /// Preserves potential author name tokens and words > 2 chars.
  /// Returns keywords ordered by importance (longest first).
  List<String> _extractKeywords(String query) {
    // Normalize: lowercase, remove accents for matching
    final normalized = _removeAccents(query.toLowerCase().trim());

    // Tokenize on whitespace and common separators
    final tokens = normalized
        .split(RegExp(r"[\s,;:!?'().-]+"))
        .where((t) => t.isNotEmpty)
        .toList();

    // Filter: remove stop-words unless they're potential author tokens
    final keywords = <String>[];
    for (final t in tokens) {
      if (_frenchStopWords.contains(t)) continue;
      if (t.length < 2) continue;
      keywords.add(t);
    }

    // Sort by length descending (most distinctive first)
    keywords.sort((a, b) => b.length.compareTo(a.length));

    // Return up to 10 most meaningful keywords
    return keywords.take(10).toList();
  }

  /// Removes common French diacritics.
  String _removeAccents(String s) {
    const withAccents = 'àâäéèêëïîôöùûüç';
    const withoutAccents = 'aaaeeeeiioouuuc';
    var result = s;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Levenshtein distance for fuzzy title matching.
  int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
        }
      }
    }
    return dp[m][n];
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
            'publisher,subject,language,number_of_pages_median,subtitle',
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
  // Google Books internals
  // ============================================================

  /// Searches Google Books API.
  /// Returns empty list if API key is not configured or quota is exhausted.
  Future<List<Map<String, dynamic>>> _searchGoogleBooks(String query) async {
    if (_googleApiKey == null) return [];

    try {
      final uri = Uri.parse('$_gbBaseUrl/volumes').replace(
        queryParameters: {
          'q': query.trim(),
          'maxResults': '20',
          'printType': 'books',
          'orderBy': 'relevance',
          'langRestrict': 'fr',
          'key': _googleApiKey,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return [];

      return items
          .map((item) => _parseGbVolume(item as Map<String, dynamic>))
          .where((book) =>
              book['title'] != null && (book['title'] as String).isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getBookByIsbnGb(String isbn) async {
    if (_googleApiKey == null) return null;

    try {
      final uri = Uri.parse('$_gbBaseUrl/volumes').replace(
        queryParameters: {
          'q': 'isbn:$isbn',
          'maxResults': '1',
          'printType': 'books',
          'key': _googleApiKey,
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) return null;

      return _parseGbVolume(items.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _parseGbVolume(Map<String, dynamic> volume) {
    final info = volume['volumeInfo'] as Map<String, dynamic>? ?? {};

    // Extract ISBN
    String? isbn;
    final identifiers = info['industryIdentifiers'] as List<dynamic>?;
    if (identifiers != null) {
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

    // Extract categories
    final categories = info['categories'] as List<dynamic>?;

    // Extract cover URL
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    String? coverUrl;
    if (imageLinks != null) {
      coverUrl = (imageLinks['large'] ??
              imageLinks['medium'] ??
              imageLinks['thumbnail'])
          as String?;
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
      'source': 'google_books',
    };
  }

  // ============================================================
  // BnF internals (unchanged)
  // ============================================================

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

  List<Map<String, dynamic>> _parseBnfResponse(String xml) {
    final recordPattern = RegExp(
      r'<srw:record>(.*?)</srw:record>',
      dotAll: true,
    );
    final records = recordPattern.allMatches(xml);

    final results = <Map<String, dynamic>>[];

    for (final match in records) {
      final recordXml = match.group(1) ?? '';

      final title = _extractDcElement(recordXml, 'title');
      final creator = _extractDcElement(recordXml, 'creator');
      final identifier = _extractDcElement(recordXml, 'identifier');
      final publisher = _extractDcElement(recordXml, 'publisher');
      final date = _extractDcElement(recordXml, 'date');
      final description = _extractDcElement(recordXml, 'description');
      final language = _extractDcElement(recordXml, 'language');

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

      final isbn = _extractIsbnFromIdentifiers(identifier, recordXml);

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
        'pageCount': null,
        'categories': subjects,
        'publisher': publisher?.trim(),
        'publishedDate': date?.trim(),
        'language': language?.trim() ?? 'fr',
        'source': 'bnf',
      });
    }

    return results;
  }

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

  String? _extractIsbnFromIdentifiers(
      String? firstIdentifier, String recordXml) {
    final idPattern = RegExp(
      r'<dc:identifier[^>]*>(.*?)</dc:identifier>',
      dotAll: true,
    );
    final ids = idPattern.allMatches(recordXml);

    for (final idMatch in ids) {
      final idValue = idMatch.group(1)?.trim() ?? '';
      final isbnMatch =
          RegExp(r'urn:isbn:([0-9Xx]{10,13})').firstMatch(idValue);
      if (isbnMatch != null) {
        return isbnMatch.group(1);
      }
      final bareIsbn = RegExp(r'\b(?:ISBN[- ]*)?([0-9Xx]{10,13})\b')
          .firstMatch(idValue);
      if (bareIsbn != null) {
        return bareIsbn.group(1);
      }
    }

    if (firstIdentifier != null) {
      final fallback = RegExp(r'([0-9Xx]{10,13})').firstMatch(firstIdentifier);
      if (fallback != null) return fallback.group(1);
    }

    return null;
  }

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
