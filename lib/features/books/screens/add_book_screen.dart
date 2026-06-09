import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/core/services/google_books_service.dart';

/// Search and add books screen.
///
/// Features:
///   - Search Google Books API
///   - Beautiful results list with covers
///   - Manual entry option (title, author, pages)
///   - Scan ISBN option (text field for now)
class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _searchController = TextEditingController();
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _isbnSearchController = TextEditingController();

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _showManualEntry = false;
  bool _showIsbnEntry = false;
  String? _error;

  final _googleBooks = GoogleBooksService();

  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _isbnController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _isbnSearchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _searchBooks(query));
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final results = await _googleBooks.searchBooks(query);
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _addBookFromSearch(Map<String, dynamic> bookData) async {
    try {
      final db = ref.read(databaseProvider);
      final categories = (bookData['categories'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          <String>[];

      await db.addBook(Book(
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
      ));

      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${bookData['title']}" added to your library!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add book: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _addManualBook() async {
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    if (title.isEmpty || author.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and author are required')),
      );
      return;
    }

    try {
      final db = ref.read(databaseProvider);
      await db.addBook(Book(
        id: '',
        title: title,
        author: author,
        pageCount: int.tryParse(_pagesController.text),
        status: ReadingStatus.wantToRead,
      ));

      ref.invalidate(allBooksProvider);
      ref.invalidate(booksByStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" added to your library!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _searchIsbn() async {
    final isbn = _isbnSearchController.text.trim();
    if (isbn.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final book = await _googleBooks.getBookByIsbn(isbn);
      if (book != null) {
        await _addBookFromSearch(book);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No book found for this ISBN')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add a Book',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Google Books
            Text(
              'Search Google Books',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by title or author...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _results = [];
                              _error = null;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search results
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              )
            else if (_results.isNotEmpty)
              ..._results.map((book) => _SearchResultItem(
                    bookData: book,
                    onTap: () => _addBookFromSearch(book),
                  )),

            if (_results.isNotEmpty) const SizedBox(height: 24),

            // Alternative options
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showManualEntry = !_showManualEntry;
                        _showIsbnEntry = false;
                      });
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: Text(
                      _showManualEntry ? 'Hide Manual Entry' : 'Manual Entry',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showIsbnEntry = !_showIsbnEntry;
                        _showManualEntry = false;
                      });
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: Text(
                      _showIsbnEntry ? 'Hide ISBN' : 'Scan ISBN',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
              ],
            ),

            // Manual entry form
            if (_showManualEntry) ...[
              const SizedBox(height: 20),
              _buildManualEntry(isDark),
            ],

            // ISBN entry
            if (_showIsbnEntry) ...[
              const SizedBox(height: 20),
              _buildIsbnEntry(isDark),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.grey.withValues(alpha: 0.04),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Book Details',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Title *',
              prefixIcon: Icon(Icons.title_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authorController,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Author *',
              prefixIcon: Icon(Icons.person_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pagesController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Page Count',
              prefixIcon: Icon(Icons.numbers_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _addManualBook,
              child: const Text('Add Book'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIsbnEntry(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppTheme.surfaceCard : Colors.grey.withValues(alpha: 0.04),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter ISBN',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type in the ISBN-10 or ISBN-13 number to look up a book.',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _isbnSearchController,
                    keyboardType: TextInputType.text,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'ISBN number...',
                      prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchIsbn,
                  child: _isSearching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Look Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Map<String, dynamic> bookData;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.bookData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverUrl = bookData['coverUrl'] as String?;
    final title = (bookData['title'] as String? ?? '');
    final author = (bookData['author'] as String? ?? 'Unknown Author');
    final pageCount = bookData['pageCount'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? AppTheme.surfaceCard : Colors.grey.withValues(alpha: 0.04),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 68,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _placeholder(),
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (pageCount != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$pageCount pages',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Add button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.book_rounded, size: 22, color: AppTheme.primary.withValues(alpha: 0.3)),
    );
  }
}
