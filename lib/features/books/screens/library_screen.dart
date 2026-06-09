import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/features/books/providers/book_providers.dart';

// ============================================================
// Palette terracotta — couleurs chaleureuses pour la bibliothèque
// ============================================================
const _primary = Color(0xFFC85A3E);
const _accent = Color(0xFFE8B84B);
const _offWhite = Color(0xFFF8F5F0);
const _offDark = Color(0xFF1C1A18);

/// Constantes de dimensions pour les couvertures de livres.
/// Ratio d'aspect standard pour les couvertures de livres (~2:3).
const _coverWidth = 70.0;
const _coverHeight = 105.0;

// ============================================================
// Couleurs des statuts de lecture
// ============================================================
const _statusColors = {
  ReadingStatus.wantToRead: Color(0xFFD97A60),
  ReadingStatus.reading: Color(0xFFC85A3E),
  ReadingStatus.finished: Color(0xFF6B8E4E),
  ReadingStatus.abandoned: Color(0xFF9E9E9E),
};

const _statusLabels = {
  ReadingStatus.wantToRead: 'À lire',
  ReadingStatus.reading: 'En cours',
  ReadingStatus.finished: 'Terminé',
  ReadingStatus.abandoned: 'Abandonné',
};

// ============================================================
// Filtres disponibles
// ============================================================
enum _FilterTab { all, reading, finished, wantToRead }

const _filterTabs = [
  (_FilterTab.all, 'Tous'),
  (_FilterTab.reading, 'En cours'),
  (_FilterTab.finished, 'Terminé'),
  (_FilterTab.wantToRead, 'À lire'),
];

// ============================================================
// LibraryScreen
// ============================================================
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  _FilterTab _selectedFilter = _FilterTab.all;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  List<Book> _filterBooks(List<Book> books) {
    var filtered = books;

    // Filtre par statut
    if (_selectedFilter != _FilterTab.all) {
      filtered = filtered.where((b) {
        return switch (_selectedFilter) {
          _FilterTab.reading => b.status == ReadingStatus.reading,
          _FilterTab.finished => b.status == ReadingStatus.finished,
          _FilterTab.wantToRead => b.status == ReadingStatus.wantToRead,
          _ => true,
        };
      }).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) =>
          b.title.toLowerCase().contains(_searchQuery) ||
          b.author.toLowerCase().contains(_searchQuery) ||
          (b.isbn?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }

    return filtered;
  }

  /// Regroupe les livres par statut : À lire / En cours / Terminé
  Map<ReadingStatus, List<Book>> _groupByStatus(List<Book> books) {
    final map = <ReadingStatus, List<Book>>{};
    for (final book in books) {
      if (book.status == ReadingStatus.abandoned) continue;
      map.putIfAbsent(book.status, () => []);
      map[book.status]!.add(book);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _offDark : _offWhite;
    final surfaceColor = isDark ? const Color(0xFF252220) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: _showSearch
              ? SizedBox(
                  height: 44,
                  child: TextField(
                    key: const ValueKey('search'),
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isDark ? Colors.white : _offDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un livre…',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.25),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: _primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 20,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.3),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                    ),
                  ),
                )
              : Text(
                  'Bibliothèque',
                  key: const ValueKey('title'),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : _offDark,
                  ),
                ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: _primary,
              size: 26,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // --- Filtres à onglets ---
          _buildFilterTabs(isDark, surfaceColor),

          // --- Bibliothèque / Bookshelf ---
          Expanded(
            child: _buildBookshelf(isDark, surfaceColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pushNamed(context, '/add-book');
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ----------------------------------------------------------
  // Filtres à onglets
  // ----------------------------------------------------------
  Widget _buildFilterTabs(bool isDark, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filterTabs.map((tab) {
          final (value, label) = tab;
          final isSelected = _selectedFilter == value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: tab == _filterTabs.last ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedFilter = value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? _primary
                        : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                    border: !isSelected
                        ? Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.06),
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------
  // Bookshelf
  // ----------------------------------------------------------
  Widget _buildBookshelf(bool isDark, Color surfaceColor) {
    final asyncBooks = ref.watch(allBooksProvider);

    return asyncBooks.when(
      loading: () => _buildSkeletonLoading(isDark),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Une erreur est survenue',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _offDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (books) {
        final filtered = _filterBooks(books);

        if (filtered.isEmpty) {
          return _buildEmptyState(isDark, _searchQuery.isNotEmpty);
        }

        return RefreshIndicator(
          color: _primary,
          onRefresh: () async {
            ref.invalidate(allBooksProvider);
            ref.invalidate(booksByStatusProvider);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                sliver: _buildShelves(filtered, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // Étagères groupées par statut
  // ----------------------------------------------------------
  Widget _buildShelves(List<Book> books, bool isDark) {
    // Si un filtre spécifique est sélectionné, les livres sont déjà filtrés
    // On crée une seule étagère
    if (_selectedFilter != _FilterTab.all) {
      return SliverList(
        delegate: SliverChildListDelegate([
          _ShelfSection(
            label: _statusLabels[books.first.status] ?? 'Livres',
            books: books,
            isDark: isDark,
          ),
        ]),
      );
    }

    // Sinon, on groupe par statut
    final grouped = _groupByStatus(books);
    final order = [
      ReadingStatus.reading,
      ReadingStatus.wantToRead,
      ReadingStatus.finished,
    ];

    final sections = <Widget>[];
    for (final status in order) {
      final shelfBooks = grouped[status];
      if (shelfBooks == null || shelfBooks.isEmpty) continue;
      sections.add(
        _ShelfSection(
          label: _statusLabels[status] ?? '',
          books: shelfBooks,
          isDark: isDark,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate(sections),
    );
  }

  // ----------------------------------------------------------
  // Skeleton de chargement
  // ----------------------------------------------------------
  Widget _buildSkeletonLoading(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: List.generate(3, (sectionIndex) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel(
              ['En cours', 'À lire', 'Terminé'][sectionIndex],
              isDark,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: _coverHeight + 28,
              child: Row(
                children: List.generate(
                  4 + sectionIndex,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: _coverWidth,
                          height: _coverHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: _coverWidth * 0.7,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildShelfLine(isDark),
            const SizedBox(height: 28),
          ],
        );
      }),
    );
  }

  // ----------------------------------------------------------
  // État vide
  // ----------------------------------------------------------
  Widget _buildEmptyState(bool isDark, bool hasSearch) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration d'étagère vide
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _EmptyShelfPainter(isDark: isDark),
                size: const Size(double.infinity, 180),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              hasSearch ? '🔍' : '📚',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Aucun livre trouvé' : 'Votre bibliothèque est vide',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : _offDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Essayez un autre terme de recherche'
                  : 'Ajoutez votre premier livre pour commencer !',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.4),
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/add-book');
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    'Ajouter un livre',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------
  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : _offDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '0',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfLine(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: isDark ? 0.4 : 0.25),
            _primary.withValues(alpha: isDark ? 0.1 : 0.05),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ============================================================
// _ShelfSection — une étagère avec ses livres
// ============================================================
class _ShelfSection extends StatefulWidget {
  final String label;
  final List<Book> books;
  final bool isDark;

  const _ShelfSection({
    required this.label,
    required this.books,
    required this.isDark,
  });

  @override
  State<_ShelfSection> createState() => _ShelfSectionState();
}

class _ShelfSectionState extends State<_ShelfSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Label de la section
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : _offDark,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.books.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Couvertures des livres arrangées en rangées
        _buildCoverRows(),

        // Ligne d'étagère
        Container(
          margin: const EdgeInsets.only(top: 10),
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primary.withValues(alpha: widget.isDark ? 0.4 : 0.25),
                _primary.withValues(alpha: widget.isDark ? 0.1 : 0.05),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverRows() {
    final books = widget.books;
    if (books.isEmpty) return const SizedBox.shrink();

    // On dispose les livres en rangées de ~4 pour créer l'effet étagère
    final rows = <List<Book>>[];
    for (var i = 0; i < books.length; i += 4) {
      rows.add(books.sublist(i, min(i + 4, books.length)));
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final rowIndex = entry.key;
        final rowBooks = entry.value;
        return Padding(
          padding: EdgeInsets.only(top: rowIndex > 0 ? 8 : 0),
          child: _BookCoverRow(
            books: rowBooks,
            rowIndex: rowIndex,
            isDark: widget.isDark,
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// _BookCoverRow — une rangée de couvertures de livres
// ============================================================
class _BookCoverRow extends StatelessWidget {
  final List<Book> books;
  final int rowIndex;
  final bool isDark;

  const _BookCoverRow({
    required this.books,
    required this.rowIndex,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _coverHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: books.asMap().entries.map((entry) {
          final index = entry.key;
          final book = entry.value;
          return _AnimatedCover(
            book: book,
            globalIndex: rowIndex * 4 + index,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// _AnimatedCover — couverture de livre avec animation d'apparition
// ============================================================
class _AnimatedCover extends StatefulWidget {
  final Book book;
  final int globalIndex;
  final bool isDark;

  const _AnimatedCover({
    required this.book,
    required this.globalIndex,
    required this.isDark,
  });

  @override
  State<_AnimatedCover> createState() => _AnimatedCoverState();
}

class _AnimatedCoverState extends State<_AnimatedCover> {
  double _opacity = 0.0;
  double _translateY = 20.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 80 * widget.globalIndex), () {
        if (mounted) {
          setState(() {
            _opacity = 1.0;
            _translateY = 0.0;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: Duration(milliseconds: 400 + 50 * widget.globalIndex),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: Offset(0, _translateY / 100),
        duration: Duration(milliseconds: 400 + 50 * widget.globalIndex),
        curve: Curves.easeOutCubic,
        child: _BookCover(
          book: widget.book,
          isDark: widget.isDark,
          onTap: () => _showBookQuickView(context, widget.book),
        ),
      ),
    );
  }

  void _showBookQuickView(BuildContext context, Book book) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BookQuickView(
        book: book,
        isDark: widget.isDark,
      ),
    );
  }
}

// ============================================================
// _BookCover — la couverture d'un livre individuel
// ============================================================
class _BookCover extends StatelessWidget {
  final Book book;
  final bool isDark;
  final VoidCallback onTap;

  const _BookCover({
    required this.book,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Couverture
            Container(
              width: _coverWidth,
              height: _coverHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _coverPlaceholder(),
                        errorWidget: (_, _, _) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
            const SizedBox(height: 6),
            // Titre sous la couverture
            SizedBox(
              width: _coverWidth + 6,
              child: Text(
                book.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF1C1A18).withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary,
            _primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          book.title.isNotEmpty
              ? book.title[0].toUpperCase()
              : '?',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// _BookQuickView — aperçu rapide d'un livre (bottom sheet)
// ============================================================
class _BookQuickView extends StatelessWidget {
  final Book book;
  final bool isDark;

  const _BookQuickView({
    required this.book,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[book.status] ?? _primary;
    final statusLabel = _statusLabels[book.status] ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        Navigator.pushNamed(context, '/book/${book.id}');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF252220) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicateur de swipe
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Couverture
                    Container(
                      width: 120,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: book.coverUrl != null &&
                                book.coverUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: book.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => _coverPlaceholder(),
                                errorWidget: (_, _, _) =>
                                    _coverPlaceholder(),
                              )
                            : _coverPlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _offDark,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Auteur
                    Text(
                      book.author,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Badge de statut
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),

                    if (book.pageCount != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${book.pageCount} pages',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Bouton voir détails
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/book/${book.id}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Voir les détails',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Indice de swipe
                    Text(
                      'Balayez pour fermer',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary.withValues(alpha: 0.2),
            _accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          size: 40,
          color: _primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ============================================================
// _EmptyShelfPainter — peint une illustration d'étagère vide
// ============================================================
class _EmptyShelfPainter extends CustomPainter {
  final bool isDark;

  _EmptyShelfPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final shelfPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Étages de l'étagère vide
    final shelfYs = [size.height * 0.3, size.height * 0.6, size.height * 0.85];

    for (final y in shelfYs) {
      // Ombre de l'étagère
      canvas.drawRect(
        Rect.fromLTRB(20, y - 2, size.width - 20, y + 6),
        shadowPaint,
      );
      // Ligne d'étagère
      canvas.drawLine(
        Offset(20, y),
        Offset(size.width - 20, y),
        shelfPaint,
      );
    }

    // Petits supports d'étagère (triangles)
    final supportPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (final y in shelfYs) {
      // Support gauche
      final leftPath = Path()
        ..moveTo(28, y)
        ..lineTo(34, y + 8)
        ..lineTo(28, y + 8)
        ..close();
      canvas.drawPath(leftPath, supportPaint);

      // Support droit
      final rightPath = Path()
        ..moveTo(size.width - 28, y)
        ..lineTo(size.width - 34, y + 8)
        ..lineTo(size.width - 28, y + 8)
        ..close();
      canvas.drawPath(rightPath, supportPaint);
    }

    // Petits livres décoratifs (silhouettes) sur l'étagère du haut
    final decoPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    final decoBooks = [
      Offset(60, 1),
      Offset(78, 3),
      Offset(98, 0),
    ];
    final decoHeights = [24.0, 32.0, 20.0];

    for (var i = 0; i < decoBooks.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            decoBooks[i].dx,
            shelfYs[0] - decoHeights[i] - 4 + decoBooks[i].dy,
            14,
            decoHeights[i],
          ),
          const Radius.circular(2),
        ),
        decoPaint,
      );
    }

    // Plante décorative sur le côté droit de l'étagère du haut
    final plantPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFF6B8E4E).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final plantPath = Path()
      ..moveTo(size.width - 70, shelfYs[0])
      ..quadraticBezierTo(
        size.width - 55,
        shelfYs[0] - 30,
        size.width - 60,
        shelfYs[0] - 45,
      )
      ..quadraticBezierTo(
        size.width - 65,
        shelfYs[0] - 30,
        size.width - 70,
        shelfYs[0],
      )
      ..close();
    canvas.drawPath(plantPath, plantPaint);

    final plantPath2 = Path()
      ..moveTo(size.width - 62, shelfYs[0])
      ..quadraticBezierTo(
        size.width - 48,
        shelfYs[0] - 25,
        size.width - 52,
        shelfYs[0] - 38,
      )
      ..quadraticBezierTo(
        size.width - 56,
        shelfYs[0] - 25,
        size.width - 62,
        shelfYs[0],
      )
      ..close();
    canvas.drawPath(plantPath2, plantPaint);

    // Pot de la plante
    final potPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final potPath = Path()
      ..moveTo(size.width - 68, shelfYs[0])
      ..lineTo(size.width - 56, shelfYs[0])
      ..lineTo(size.width - 58, shelfYs[0] + 12)
      ..lineTo(size.width - 66, shelfYs[0] + 12)
      ..close();
    canvas.drawPath(potPath, potPaint);
  }

  @override
  bool shouldRepaint(covariant _EmptyShelfPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ============================================================
// Utilitaires
// ============================================================
