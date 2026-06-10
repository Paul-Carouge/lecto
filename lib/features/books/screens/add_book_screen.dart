import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/router/app_router.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/core/services/book_search_service.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/stats/providers/stats_providers.dart';

// ============================================================
// AddBookScreen — Recherche et ajout de livres
// ============================================================

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _bookSearch = BookSearchService();
  Timer? _debounce;

  int _searchRequestId = 0;

  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  String? _suggestedQuery;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _searchBooks(query),
    );
  }

  Future<void> _searchBooks(String query) async {
    final requestId = ++_searchRequestId;
    setState(() {
      _isSearching = true;
      _error = null;
      _suggestedQuery = null;
      _hasSearched = true;
    });
    try {
      final result = await _bookSearch.searchBooks(query);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = result.books;
        _suggestedQuery = result.suggestedQuery;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
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

      final book = await db.addBook(Book(
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
      ref.invalidate(bookshelfStatsProvider);

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      final palette = ref.read(themePaletteProvider);
      final isDark = ref.read(isDarkModeProvider);

      final startReading = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
        builder: (sheetContext) {
          final sheetPalette = ThemePalette.fromOption(AppThemeOption.terracotta);
          return Padding(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 12,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 36,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: (isDark ? sheetPalette.textOnDark.withValues(alpha: 0.2) : sheetPalette.textSecondary.withValues(alpha: 0.2)),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sheetPalette.primary.withValues(alpha: 0.1),
                  ),
                  child: Icon(Icons.check_circle_rounded, size: 32, color: sheetPalette.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ajouté à la bibliothèque',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? sheetPalette.textOnDark : sheetPalette.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 15, color: sheetPalette.textSecondary),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sheetPalette.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Commencer la lecture', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: sheetPalette.primary,
                      side: BorderSide(color: sheetPalette.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Plus tard', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) return;

      _searchController.clear();
      _searchFocusNode.unfocus();
      setState(() {
        _results = [];
        _hasSearched = false;
      });

      if (startReading == true) {
        final now = DateTime.now();
        db.updateBook(book.id, {
          'status': ReadingStatus.reading.name,
          'date_started': now.toIso8601String(),
        });
        ref.invalidate(allBooksProvider);
        ref.invalidate(booksByStatusProvider);
        ref.invalidate(currentBookProvider(book.id));
        ref.invalidate(bookshelfStatsProvider);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.session(book.id),
          (route) => route.isFirst,
        );
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

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);

    final bg = isDark ? palette.surfaceDark : palette.surfaceLight;
    final onSurface = isDark ? palette.textOnDark : palette.textPrimary;
    final muted = isDark
        ? palette.textOnDark.withValues(alpha: 0.5)
        : palette.textSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search section ──
            _buildSearchSection(palette, isDark, onSurface, muted),

            // ── Content ──
            Expanded(
              child: _buildContent(palette, isDark, onSurface, muted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search Bar ──
  Widget _buildSearchSection(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    final hasFocus = _searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Rechercher un livre',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
          ),

          // Search bar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark
                  ? palette.surfaceCardDark
                  : palette.surfaceCardLight,
              border: Border.all(
                color: hasFocus
                    ? palette.primary.withValues(alpha: 0.5)
                    : isDark
                        ? palette.textOnDark.withValues(alpha: 0.08)
                        : palette.textSecondary.withValues(alpha: 0.12),
                width: hasFocus ? 2 : 1,
              ),
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: hasFocus ? palette.primary : muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Titre, auteur…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 16,
                        color: muted.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (hasText)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        setState(() {
                          _results = [];
                          _error = null;
                          _suggestedQuery = null;
                          _hasSearched = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Example chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _exampleQueries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final q = _exampleQueries[index];
                final isSelected = _searchController.text == q;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _searchController.text = q;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: q.length),
                    );
                    _searchBooks(q);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? palette.primary
                          : palette.primary.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: Text(
                        q,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isSelected ? Colors.white : palette.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _exampleQueries = [
    'Le Petit Prince',
    'Harry Potter',
    '1984',
    'Les Misérables',
  ];

  // ── Content area ──
  Widget _buildContent(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    // Loading
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: 6,
        itemBuilder: (_, _) => _ShimmerCard(palette: palette, isDark: isDark),
      );
    }

    // Error
    if (_error != null && _results.isEmpty) {
      return _buildErrorState(palette, muted);
    }

    // Results
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _results.length + (_suggestedQuery != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0 && _suggestedQuery != null) {
            return _SuggestionBanner(
              suggestion: _suggestedQuery!,
              palette: palette,
              onSearch: () {
                _searchController.text = _suggestedQuery!;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _suggestedQuery!.length),
                );
                _searchBooks(_suggestedQuery!);
              },
            );
          }
          final adjustedIndex = _suggestedQuery != null ? index - 1 : index;
          final book = _results[adjustedIndex];
          return _SearchResultCard(
            bookData: book,
            palette: palette,
            isDark: isDark,
            onTap: () => _addBookFromSearch(book),
          );
        },
      );
    }

    // Empty initial state
    if (!_hasSearched) {
      return _buildEmptyState(palette, isDark, onSurface, muted);
    }

    // No results
    return _buildNoResults(palette, muted);
  }

  // ── Empty State ──
  Widget _buildEmptyState(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const SizedBox(height: 16),
        // Illustration
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  palette.primary.withValues(alpha: 0.12),
                  palette.primaryLight.withValues(alpha: 0.06),
                ],
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: palette.primary.withValues(alpha: 0.3),
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
              color: onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Cherchez un livre par son titre ou son auteur.\nTapez quelques mots pour commencer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: muted,
            ),
          ),
        ),
        const SizedBox(height: 36),

        // Tips
        _TipTile(
          icon: Icons.search_rounded,
          title: 'Recherche intelligente',
          subtitle: 'Titre, auteur ou mots-clés',
          palette: palette,
        ),
        const SizedBox(height: 10),
        _TipTile(
          icon: Icons.qr_code_rounded,
          title: 'Recherche par ISBN',
          subtitle: 'Scannez ou saisissez un code ISBN',
          palette: palette,
        ),
        const SizedBox(height: 10),
        _TipTile(
          icon: Icons.edit_note_rounded,
          title: 'Saisie manuelle',
          subtitle: 'Ajoutez un livre sans passer par la recherche',
          palette: palette,
        ),

        const SizedBox(height: 32),

        // Alternative methods
        _buildAltMethods(palette, isDark, onSurface, muted),
      ],
    );
  }

  Widget _buildAltMethods(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    return Column(
      children: [
        // Divider with label
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark
                    ? palette.textOnDark.withValues(alpha: 0.08)
                    : palette.textSecondary.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Autres méthodes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark
                    ? palette.textOnDark.withValues(alpha: 0.08)
                    : palette.textSecondary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ISBN tile
        _MethodTile(
          icon: Icons.qr_code_rounded,
          title: 'Recherche par ISBN',
          subtitle: 'Trouvez un livre instantanément avec son code ISBN',
          palette: palette,
          isDark: isDark,
          onTap: () => _showIsbnSheet(palette, isDark, onSurface, muted),
        ),
        const SizedBox(height: 10),

        // Manual entry tile
        _MethodTile(
          icon: Icons.edit_note_rounded,
          title: 'Saisie manuelle',
          subtitle: 'Ajoutez un livre qui n\'est pas dans les bases de données',
          palette: palette,
          isDark: isDark,
          onTap: () => _showManualSheet(palette, isDark, onSurface, muted),
        ),
      ],
    );
  }

  Widget _buildNoResults(ThemePalette palette, Color muted) {
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
                color: palette.primary.withValues(alpha: 0.06),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 36,
                color: palette.primary.withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun résultat',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés\nou vérifiez l\'orthographe.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemePalette palette, Color muted) {
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Impossible de contacter le serveur',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez votre connexion Internet\net réessayez.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: muted,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ISBN Bottom Sheet ──
  void _showIsbnSheet(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    HapticFeedback.lightImpact();
    final isbnController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: muted.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: palette.primary.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.qr_code_rounded, size: 24, color: palette.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherche par ISBN',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saisissez le code ISBN-10 ou ISBN-13\ndu livre que vous cherchez.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: isbnController,
              keyboardType: TextInputType.text,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 16, color: onSurface),
              decoration: InputDecoration(
                hintText: 'ISBN…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 16,
                  color: muted.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.qr_code_rounded, size: 22, color: muted),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  final isbn = isbnController.text.trim();
                  if (isbn.isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isSearching = true);
                  try {
                    final book = await _bookSearch.getBookByIsbn(isbn);
                    if (!mounted) return;
                    if (book != null) {
                      await _addBookFromSearch(book);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Aucun livre trouvé pour cet ISBN'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSearching = false);
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Rechercher',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Manual Entry Bottom Sheet ──
  void _showManualSheet(
    ThemePalette palette,
    bool isDark,
    Color onSurface,
    Color muted,
  ) {
    HapticFeedback.lightImpact();
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: muted.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: palette.primary.withValues(alpha: 0.08),
              ),
              child: Icon(Icons.edit_note_rounded, size: 24, color: palette.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Ajout manuel',
              style: GoogleFonts.outfit(
                fontSize: 20, fontWeight: FontWeight.w600, color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez un livre qui n\'est pas référencé\ndans les bases de données.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.4, color: muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.inter(fontSize: 15, color: onSurface),
              decoration: const InputDecoration(
                hintText: 'Titre *',
                prefixIcon: Icon(Icons.title_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: authorCtrl,
              style: GoogleFonts.inter(fontSize: 15, color: onSurface),
              decoration: const InputDecoration(
                hintText: 'Auteur *',
                prefixIcon: Icon(Icons.person_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pagesCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 15, color: onSurface),
              decoration: const InputDecoration(
                hintText: 'Nombre de pages',
                prefixIcon: Icon(Icons.numbers_rounded, size: 22),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final author = authorCtrl.text.trim();
                  if (title.isEmpty || author.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Le titre et l'auteur sont requis"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final db = ref.read(databaseProvider);
                    final book = await db.addBook(Book(
                      id: '',
                      title: title,
                      author: author,
                      pageCount: int.tryParse(pagesCtrl.text),
                      status: ReadingStatus.wantToRead,
                    ));
                    ref.invalidate(allBooksProvider);
                    ref.invalidate(booksByStatusProvider);
                    ref.invalidate(bookshelfStatsProvider);
                    if (!mounted) return;

                    HapticFeedback.mediumImpact();
                    final startReading = await showDialog<bool>(
                      context: context,
                      builder: (dCtx) => _AddBookSuccessDialog(book: book),
                    );
                    if (!mounted || startReading != true) return;

                    final now = DateTime.now();
                    db.updateBook(book.id, {
                      'status': ReadingStatus.reading.name,
                      'date_started': now.toIso8601String(),
                    });
                    ref.invalidate(allBooksProvider);
                    ref.invalidate(booksByStatusProvider);
                    ref.invalidate(currentBookProvider(book.id));
                    ref.invalidate(bookshelfStatsProvider);
                    if (!mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.session(book.id),
                      (route) => route.isFirst,
                    );
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Échec : $e'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Ajouter le livre',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _SuggestionBanner extends StatelessWidget {
  final String suggestion;
  final ThemePalette palette;
  final VoidCallback onSearch;

  const _SuggestionBanner({
    required this.suggestion,
    required this.palette,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: palette.primary.withValues(alpha: 0.06),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.tips_and_updates_rounded,
              size: 20,
              color: palette.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous cherchiez plutôt',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    suggestion,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 34,
              child: FilledButton(
                onPressed: onSearch,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Chercher',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Search Result Card
// ============================================================
class _SearchResultCard extends ConsumerWidget {
  final Map<String, dynamic> bookData;
  final ThemePalette palette;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.bookData,
    required this.palette,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverUrl = bookData['coverUrl'] as String?;
    final title = (bookData['title'] as String? ?? '');
    final author = (bookData['author'] as String? ?? 'Auteur inconnu');
    final pageCount = bookData['pageCount'] as int?;
    final source = bookData['source'] as String? ?? 'openlibrary';

    final surface = isDark ? palette.surfaceCardDark : palette.surfaceCardLight;
    final onSurface = isDark ? palette.textOnDark : palette.textPrimary;
    final muted = isDark
        ? palette.textOnDark.withValues(alpha: 0.5)
        : palette.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: surface,
            border: Border.all(
              color: isDark
                  ? palette.textOnDark.withValues(alpha: 0.06)
                  : palette.textSecondary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              // ── Cover ──
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => _CoverPlaceholder(
                            palette: palette,
                          ),
                          errorWidget: (_, _, _) => _CoverPlaceholder(
                            palette: palette,
                          ),
                        )
                      : _CoverPlaceholder(palette: palette),
                ),
              ),
              const SizedBox(width: 16),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (pageCount != null) ...[
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 14,
                            color: palette.primary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$pageCount p.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: palette.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        _SourceBadge(source: source),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Add button ──
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: palette.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final ThemePalette palette;
  const _CoverPlaceholder({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.book_rounded,
        size: 26,
        color: palette.primary.withValues(alpha: 0.2),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String source;
  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      'bnf' => ('BnF', const Color(0xFF2563EB)),
      'google_books' => ('Google Books', const Color(0xFF4285F4)),
      _ => ('OpenLibrary', const Color(0xFFD97706)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// Shimmer Loading
// ============================================================
class _ShimmerCard extends StatefulWidget {
  final ThemePalette palette;
  final bool isDark;
  const _ShimmerCard({required this.palette, required this.isDark});

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
    final shimmerColor = widget.isDark
        ? widget.palette.textOnDark
        : widget.palette.textPrimary;

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        final opacity = _shimmerAnim.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 108,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: widget.isDark
                  ? widget.palette.surfaceCardDark
                  : widget.palette.surfaceCardLight,
              border: Border.all(
                color: shimmerColor.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                // Cover
                Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: shimmerColor.withValues(alpha: 0.06 * opacity),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: shimmerColor.withValues(
                            alpha: 0.06 * opacity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: shimmerColor.withValues(
                            alpha: 0.04 * opacity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 10,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: shimmerColor.withValues(
                            alpha: 0.03 * opacity,
                          ),
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

// ============================================================
// Tip Tile
// ============================================================
class _TipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemePalette palette;

  const _TipTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.primary.withValues(alpha: 0.04),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.primary.withValues(alpha: 0.08),
            ),
            child: Icon(
              icon,
              size: 18,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Alternative Entry Methods
// ============================================================

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemePalette palette;
  final bool isDark;
  final VoidCallback onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? palette.surfaceCardDark : palette.surfaceCardLight,
          border: Border.all(
            color: isDark
                ? palette.textOnDark.withValues(alpha: 0.06)
                : palette.textSecondary.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: palette.primary.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 22, color: palette.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? palette.textOnDark.withValues(alpha: 0.5)
                          : palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? palette.textOnDark.withValues(alpha: 0.3)
                  : palette.textSecondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Add Book Success Dialog
// ============================================================
class _AddBookSuccessDialog extends StatelessWidget {
  final Book book;
  const _AddBookSuccessDialog({required this.book});

  @override
  Widget build(BuildContext context) {
    final palette = ThemePalette.fromOption(AppThemeOption.terracotta);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: palette.primary,
            size: 28,
          ),
          const SizedBox(width: 10),
          Text(
            'Ajouté !',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: Text(
        '« ${book.title} » a été ajouté à votre bibliothèque.\n\nVoulez-vous commencer la lecture ?',
        style: GoogleFonts.inter(fontSize: 15, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Non',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Oui',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
