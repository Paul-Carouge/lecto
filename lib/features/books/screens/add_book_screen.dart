import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/core/services/book_search_service.dart';

/// Search and add books screen — redesigned for beauty and delight.
class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _searchController = TextEditingController();
  final _isbnSearchController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _showManualEntry = false;
  bool _showIsbnEntry = false;
  String? _error;
  String? _suggestedQuery;

  final _bookSearch = BookSearchService();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _isbnSearchController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _searchFocusNode.dispose();
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
        _suggestedQuery = null;
      });
      return;
    }
    _debounce = Timer(
        const Duration(milliseconds: 350), () => _searchBooks(query));
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _isSearching = true;
      _error = null;
      _suggestedQuery = null;
    });
    try {
      final result = await _bookSearch.searchBooks(query);
      if (!mounted) return;
      setState(() {
        _results = result.books;
        _suggestedQuery = result.suggestedQuery;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
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
        title: bookData['title'] as String? ?? 'Titre inconnu',
        author: bookData['author'] as String? ?? 'Auteur inconnu',
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
            content: Text('« ${bookData['title']} » ajouté à votre bibliothèque !'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Échec de l'ajout : $e"),
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
        const SnackBar(
            content: Text("Le titre et l'auteur sont requis")),
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
            content: Text('« $title » ajouté à votre bibliothèque !'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec : $e')),
        );
      }
    }
  }

  Future<void> _searchIsbn() async {
    final isbn = _isbnSearchController.text.trim();
    if (isbn.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final book = await _bookSearch.getBookByIsbn(isbn);
      if (!mounted) return;
      if (book != null) {
        await _addBookFromSearch(book);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucun livre trouvé pour cet ISBN')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  /// Example search chips
  static const List<String> _exampleQueries = [
    'Le Petit Prince',
    'Harry Potter',
    '1984',
    'Les Misérables',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajouter un livre',
          style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: cs.onSurface.withValues(alpha: 0.6)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Top search section (fixed) ----
          _buildSearchSection(cs, isDark, theme),

          // ---- Scrollable results + bottom sections ----
          Expanded(
            child: _buildBody(cs, isDark),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Search bar + chips
  // ================================================================
  Widget _buildSearchSection(
      ColorScheme cs, bool isDark, ThemeData theme) {
    final borderColor =
        _searchFocusNode.hasFocus ? cs.primary : cs.onSurface.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 2),
              color: cs.surface,
              boxShadow: _searchFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'Rechercher un livre ou un auteur…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search_rounded,
                      color: _searchFocusNode.hasFocus
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.35),
                      size: 24),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color: cs.onSurface.withValues(alpha: 0.4),
                            size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          setState(() {
                            _results = [];
                            _error = null;
                            _suggestedQuery = null;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),

          // Example chips
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _exampleQueries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = _exampleQueries[index];
                return ActionChip(
                  label: Text(
                    q,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.primary,
                    ),
                  ),
                  backgroundColor: cs.primary.withValues(alpha: 0.08),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () {
                    _searchController.text = q;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: q.length),
                    );
                    _searchBooks(q);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ================================================================
  // Body: results, empty, loading, error
  // ================================================================
  Widget _buildBody(ColorScheme cs, bool isDark) {
    // Loading
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: 5,
        itemBuilder: (_, _) => _ShimmerCard(cs: cs),
      );
    }

    // Error
    if (_error != null && _results.isEmpty) {
      return _buildErrorState(cs);
    }

    // Empty (no query entered)
    if (_searchController.text.trim().isEmpty && _results.isEmpty) {
      return _buildEmptyState(cs, isDark);
    }

    // Results
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        itemCount: _results.length + (_suggestedQuery != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Suggestion banner at top
          if (index == 0 && _suggestedQuery != null) {
            return _buildSuggestionBanner(cs, _suggestedQuery!);
          }
          final adjustedIndex =
              _suggestedQuery != null ? index - 1 : index;
          final book = _results[adjustedIndex];
          return _SearchResultCard(
            bookData: book,
            cs: cs,
            onTap: () => _addBookFromSearch(book),
          );
        },
      );
    }

    // Empty results with suggestion
    if (_suggestedQuery != null && _results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          _buildSuggestionBanner(cs, _suggestedQuery!),
          _buildNoResults(cs),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ================================================================
  // Empty state
  // ================================================================
  Widget _buildEmptyState(ColorScheme cs, bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const SizedBox(height: 28),
        // Illustration area
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.06),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 52,
              color: cs.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Que souhaitez-vous lire ?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Cherchez un livre par titre ou auteur.\nUtilisez les exemples ci-dessus pour démarrer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Search tips
        _TipRow(
          icon: Icons.search_rounded,
          text: 'Tapez le titre ou le nom de l\'auteur',
          cs: cs,
        ),
        const SizedBox(height: 10),
        _TipRow(
          icon: Icons.qr_code_rounded,
          text: 'Recherchez par ISBN-10 ou ISBN-13',
          cs: cs,
        ),
        const SizedBox(height: 10),
        _TipRow(
          icon: Icons.edit_note_rounded,
          text: 'Saisissez les détails manuellement',
          cs: cs,
        ),

        const SizedBox(height: 32),

        // Alternative sections at bottom
        _buildCollapsibleSections(cs, isDark),
      ],
    );
  }

  Widget _buildNoResults(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off_rounded,
                size: 48,
                color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Aucun résultat trouvé',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // Error state
  // ================================================================
  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.error.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: cs.error.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Impossible de contacter le serveur',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion Internet\net réessayez.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final q = _searchController.text.trim();
                if (q.isNotEmpty) _searchBooks(q);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // Suggestion banner
  // ================================================================
  Widget _buildSuggestionBanner(ColorScheme cs, String suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.primary.withValues(alpha: 0.07),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_rounded,
              size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.7)),
                children: [
                  const TextSpan(text: 'Vous cherchiez plutôt « '),
                  TextSpan(
                    text: suggestion,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const TextSpan(text: ' » ?'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            child: TextButton(
              onPressed: () {
                _searchController.text = suggestion;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
                _searchBooks(suggestion);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: cs.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Chercher',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // Collapsible sections (ISBN + Manual entry) at bottom of empty state
  // ================================================================
  Widget _buildCollapsibleSections(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        // ISBN look-up
        _CollapsibleSection(
          title: 'Recherche par ISBN',
          icon: Icons.qr_code_rounded,
          isOpen: _showIsbnEntry,
          cs: cs,
          onToggle: () {
            setState(() {
              _showIsbnEntry = !_showIsbnEntry;
              if (_showIsbnEntry) _showManualEntry = false;
            });
          },
          child: _IsbnForm(
            isbnSearchController: _isbnSearchController,
            isSearching: _isSearching,
            onSearch: _searchIsbn,
            cs: cs,
          ),
        ),
        const SizedBox(height: 10),

        // Manual entry
        _CollapsibleSection(
          title: 'Saisie manuelle',
          icon: Icons.edit_note_rounded,
          isOpen: _showManualEntry,
          cs: cs,
          onToggle: () {
            setState(() {
              _showManualEntry = !_showManualEntry;
              if (_showManualEntry) _showIsbnEntry = false;
            });
          },
          child: _ManualForm(
            titleController: _titleController,
            authorController: _authorController,
            pagesController: _pagesController,
            onSubmit: _addManualBook,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

// ================================================================
// Search result card
// ================================================================
class _SearchResultCard extends ConsumerWidget {
  final Map<String, dynamic> bookData;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.bookData,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = bookData['coverUrl'] as String?;
    final title = (bookData['title'] as String? ?? '');
    final author = (bookData['author'] as String? ?? 'Auteur inconnu');
    final pageCount = bookData['pageCount'] as int?;
    final source = bookData['source'] as String? ?? 'openlibrary';

    // Source label
    String sourceLabel;
    Color sourceColor;
    switch (source) {
      case 'bnf':
        sourceLabel = 'BnF';
        sourceColor = const Color(0xFF2563EB);
        break;
      case 'google_books':
        sourceLabel = 'Google Books';
        sourceColor = const Color(0xFF4285F4);
        break;
      default:
        sourceLabel = 'OpenLibrary';
        sourceColor = const Color(0xFFD97706);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cs.surface,
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 68,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _coverPlaceholder(cs),
                          errorWidget: (_, _, _) =>
                              _coverPlaceholder(cs),
                        )
                      : _coverPlaceholder(cs),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Author
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Page count badge
                        if (pageCount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFFC85A3E)
                                  .withValues(alpha: 0.1),
                            ),
                            child: Text(
                              '$pageCount p.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFC85A3E),
                              ),
                            ),
                          ),
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: sourceColor.withValues(alpha: 0.1),
                          ),
                          child: Text(
                            sourceLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: sourceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Add button
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC85A3E),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.book_rounded,
        size: 22,
        color: cs.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

// ================================================================
// Shimmer placeholder card for loading state
// ================================================================
class _ShimmerCard extends StatefulWidget {
  final ColorScheme cs;
  const _ShimmerCard({required this.cs});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final opacity = _shimmerAnim.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 92,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: widget.cs.surface,
              border: Border.all(
                color: widget.cs.onSurface.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Cover placeholder
                Container(
                  width: 48,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: widget.cs.onSurface.withValues(alpha: 0.08 * opacity),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: widget.cs.onSurface
                              .withValues(alpha: 0.08 * opacity),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: widget.cs.onSurface
                              .withValues(alpha: 0.06 * opacity),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: widget.cs.onSurface
                              .withValues(alpha: 0.05 * opacity),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// Tip row for empty state
// ================================================================
class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme cs;

  const _TipRow({
    required this.icon,
    required this.text,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, size: 16, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// Collapsible section
// ================================================================
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isOpen;
  final ColorScheme cs;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.title,
    required this.icon,
    required this.isOpen,
    required this.cs,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: cs.surface,
        border: Border.all(
          color: cs.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ISBN form
// ================================================================
class _IsbnForm extends StatelessWidget {
  final TextEditingController isbnSearchController;
  final bool isSearching;
  final VoidCallback onSearch;
  final ColorScheme cs;

  const _IsbnForm({
    required this.isbnSearchController,
    required this.isSearching,
    required this.onSearch,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saisissez le numéro ISBN-10 ou ISBN-13 pour trouver un livre instantanément.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: isbnSearchController,
                  keyboardType: TextInputType.text,
                  style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'ISBN…',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    prefixIcon: Icon(Icons.qr_code_rounded,
                        size: 20,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: cs.onSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: cs.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: isSearching ? null : onSearch,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Rechercher',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================================================================
// Manual entry form
// ================================================================
class _ManualForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController pagesController;
  final VoidCallback onSubmit;
  final ColorScheme cs;

  const _ManualForm({
    required this.titleController,
    required this.authorController,
    required this.pagesController,
    required this.onSubmit,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ajoutez un livre qui n\'est pas dans les bases de données.',
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.4,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: titleController,
          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Titre *',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(Icons.title_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: authorController,
          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Auteur *',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(Icons.person_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: pagesController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 14, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: 'Nombre de pages',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            prefixIcon: Icon(Icons.numbers_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.4)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Ajouter le livre',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
