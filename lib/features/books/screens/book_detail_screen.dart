import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/core/router/app_router.dart';

// ============================================================
// BookDetailScreen — écran détail du livre, complet & moderne
// ============================================================

/// Écran de détail d'un livre — généreux, spacieux, full-width.
///
/// Sections (dans l'ordre) :
///   - AppBar avec titre + menu (statut, supprimer)
///   - Couverture Hero centrée (140×200)
///   - Titre + Auteur + Badge de statut
///   - Grille d'infos 2×2 (Pages, ISBN, Éditeur, Date)
///   - Jauges de progression (X / Y pages, Z restantes)
///   - Description expandable
///   - Catégories en chips
///   - Note par étoiles (visible pour TOUS les livres)
///   - Section session (lancer / reprendre)
///   - Sessions list
///   - Bottom bar "Lire" toujours visible
class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _descriptionExpanded = false;
  double? _pendingRating;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Force refresh providers when screen first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(currentBookProvider(widget.bookId));
      ref.invalidate(bookPagesReadProvider(widget.bookId));
      ref.invalidate(bookRemainingPagesProvider(widget.bookId));
      ref.invalidate(activeBookSessionProvider(widget.bookId));
      ref.invalidate(bookSessionsProvider(widget.bookId));
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final sessionsAsync = ref.watch(bookSessionsProvider(widget.bookId));
    final pagesReadAsync = ref.watch(bookPagesReadProvider(widget.bookId));
    final remainingPagesAsync =
        ref.watch(bookRemainingPagesProvider(widget.bookId));
    final activeSessionAsync =
        ref.watch(activeBookSessionProvider(widget.bookId));

    return bookAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? palette.surfaceDark : palette.surfaceLight,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: isDark ? palette.surfaceDark : palette.surfaceLight,
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erreur : $err',
              style: GoogleFonts.inter(color: AppTheme.error),
            ),
          ),
        ),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            backgroundColor: isDark ? palette.surfaceDark : palette.surfaceLight,
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('😕', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      'Livre introuvable',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? palette.textOnDark : palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final sessionsList = sessionsAsync.valueOrNull ?? [];
        final pagesRead = pagesReadAsync.valueOrNull ?? 0;
        final remainingPages = remainingPagesAsync.valueOrNull;
        final activeSession = activeSessionAsync.valueOrNull;

        return Scaffold(
          backgroundColor: isDark ? palette.surfaceDark : palette.surfaceLight,
          body: CustomScrollView(
            slivers: [
              // ========== AppBar ==========
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                backgroundColor:
                    isDark ? palette.surfaceDark : Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : palette.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : palette.textPrimary,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white70 : palette.textSecondary,
                    ),
                    onPressed: () => _showBookMenuBottomSheet(book),
                  ),
                ],
              ),

              // ========== Contenu principal ==========
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),

                    // ---- 1. Couverture ----
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _BookCover(book: book, palette: palette),
                    ),
                    const SizedBox(height: 24),

                    // ---- 2. Titre + Auteur + Statut ----
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _TitleSection(book: book, palette: palette),
                    ),
                    const SizedBox(height: 24),

                    // ---- 3. Grille d'infos 2×2 ----
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _InfoGrid(book: book, palette: palette),
                    ),
                    const SizedBox(height: 24),

                    // ---- 4. Progression (pages restantes) ----
                    if (book.pageCount != null) ...[
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _ProgressSection(
                          pagesRead: pagesRead,
                          pageCount: book.pageCount!,
                          remainingPages: remainingPages,
                          palette: palette,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 5. Description ----
                    if (book.description != null &&
                        book.description!.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Description',
                        palette: palette,
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _DescriptionCard(
                          description: book.description!,
                          isExpanded: _descriptionExpanded,
                          isDark: isDark,
                          palette: palette,
                          onToggle: () {
                            setState(() {
                              _descriptionExpanded = !_descriptionExpanded;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 6. Catégories ----
                    if (book.categories.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Catégories',
                        palette: palette,
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _CategoryChips(
                          categories: book.categories,
                          palette: palette,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 7. Note par étoiles (TOUS les livres) ----
                    _SectionHeader(
                      title: 'Ma note',
                      palette: palette,
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _StarRating(
                        rating: _pendingRating ?? book.myRating ?? 0,
                        palette: palette,
                        onChanged: (rating) {
                          setState(() => _pendingRating = rating);
                          _updateRating(book.id, rating);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---- 8. Section session ----
                    _SectionHeader(
                      title: 'Session de lecture',
                      palette: palette,
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _SessionActionSection(
                        activeSession: activeSession,
                        bookId: book.id,
                        palette: palette,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---- 9. Sessions associées ----
                    _SectionHeader(
                      title: 'Séances de lecture',
                      palette: palette,
                      trailing: sessionsList.isNotEmpty
                          ? Text(
                              '${sessionsList.length} séance${sessionsList.length > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: palette.textSecondary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _SessionList(
                        sessionsAsync: sessionsAsync,
                        bookTitle: book.title,
                        palette: palette,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),

          // ========== Bouton "Lire" toujours visible en bas ==========
          bottomNavigationBar: _BottomActionBar(
            book: book,
            palette: palette,
            isDark: isDark,
            onRead: () {
              Navigator.pushNamed(context, AppRouter.session(book.id));
            },
          ),
        );
      },
    );
  }

  void _showBookMenuBottomSheet(Book book) {
    final palette = ref.read(themePaletteProvider);
    final isDark = ref.read(isDarkModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? palette.surfaceCardDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final statuses = [
          (ReadingStatus.wantToRead, 'À lire', Icons.bookmark_border_rounded, AppTheme.warning),
          (ReadingStatus.reading, 'En cours', Icons.menu_book_rounded, _statusColor(ReadingStatus.reading)),
          (ReadingStatus.finished, 'Terminé', Icons.check_circle_outline_rounded, _statusColor(ReadingStatus.finished)),
          (ReadingStatus.abandoned, 'Abandonné', Icons.block_rounded, _statusColor(ReadingStatus.abandoned)),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Changer le statut',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Status options
                ...statuses.map((s) {
                  final (status, label, icon, color) = s;
                  final isSelected = status == book.status;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListTile(
                      leading: Icon(
                        icon,
                        size: 22,
                        color: isSelected ? color : palette.textSecondary,
                      ),
                      title: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : (isDark ? Colors.white : palette.textPrimary),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, size: 22, color: color)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateStatus(book, status);
                      },
                    ),
                  );
                }),
                const Divider(height: 24, indent: 20, endIndent: 20),
                // Delete
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ListTile(
                    leading: const Icon(Icons.delete_rounded, size: 22, color: AppTheme.error),
                    title: Text(
                      'Supprimer',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.error,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDelete(book);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _updateStatus(Book book, ReadingStatus status) {
    if (status == book.status) return;
    ref
        .read(updateBookStatusProvider(book.id, status).notifier)
        .applyUpdate();
  }

  void _updateRating(String bookId, double rating) {
    final db = ref.read(databaseProvider);
    db.updateBook(bookId, {'my_rating': rating});
    ref.invalidate(currentBookProvider(bookId));
  }

  void _confirmDelete(Book book) {
    final palette = ref.read(themePaletteProvider);
    final isDark = ref.read(isDarkModeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? palette.surfaceCardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer ce livre ?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: isDark ? palette.textOnDark : palette.textPrimary,
          ),
        ),
        content: Text(
          'Toutes les séances associées seront également supprimées.',
          style: GoogleFonts.inter(
            color: palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final db = ref.read(databaseProvider);
              db.deleteBook(book.id);
              ref.invalidate(allBooksProvider);
              ref.invalidate(booksByStatusProvider);
              ref.invalidate(currentBookProvider(book.id));
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                color: AppTheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Couverture avec Hero
// ============================================================
class _BookCover extends StatelessWidget {
  final Book book;
  final ThemePalette palette;

  const _BookCover({required this.book, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'book_cover_${book.id}',
        child: Container(
          width: 140,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: book.coverUrl != null && book.coverUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: book.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      _CoverPlaceholder(palette: palette),
                )
              : _CoverPlaceholder(palette: palette),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.6),
            palette.accent.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: const Center(
        child:
            Icon(Icons.menu_book_rounded, size: 56, color: Colors.white38),
      ),
    );
  }
}

// ============================================================
// Titre + Auteur + Badge statut
// ============================================================
class _TitleSection extends StatelessWidget {
  final Book book;
  final ThemePalette palette;

  const _TitleSection({required this.book, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          book.author,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: palette.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 16),
        _StatusBadge(status: book.status),
      ],
    );
  }
}

// ============================================================
// Couleurs et libellés de statut
// ============================================================
Color _statusColor(ReadingStatus status) {
  return switch (status) {
    ReadingStatus.reading => const Color(0xFFD97A60), // terracotta light
    ReadingStatus.finished => const Color(0xFF6B8E4E), // muted green
    ReadingStatus.wantToRead => const Color(0xFF8B6F5C), // brown grey
    ReadingStatus.abandoned => const Color(0xFFEF4444), // red
  };
}

String _statusLabel(ReadingStatus status) {
  return switch (status) {
    ReadingStatus.wantToRead => 'À lire',
    ReadingStatus.reading => 'En cours',
    ReadingStatus.finished => 'Terminé',
    ReadingStatus.abandoned => 'Abandonné',
  };
}

IconData _statusIcon(ReadingStatus status) {
  return switch (status) {
    ReadingStatus.wantToRead => Icons.bookmark_border_rounded,
    ReadingStatus.reading => Icons.menu_book_rounded,
    ReadingStatus.finished => Icons.check_circle_outline_rounded,
    ReadingStatus.abandoned => Icons.block_rounded,
  };
}

class _StatusBadge extends StatelessWidget {
  final ReadingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            _statusLabel(status),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Grille d'infos 2×2
// ============================================================
class _InfoGrid extends StatelessWidget {
  final Book book;
  final ThemePalette palette;

  const _InfoGrid({required this.book, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceCardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ligne 1 : Pages | ISBN
          Row(
            children: [
              Flexible(
                flex: 1,
                child: _InfoCell(
                  icon: Icons.auto_stories_rounded,
                  label: 'Pages',
                  value: book.pageCount?.toString() ?? '—',
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: _InfoCell(
                  icon: Icons.qr_code_rounded,
                  label: 'ISBN',
                  value: book.isbn ?? '—',
                  palette: palette,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ligne 2 : Éditeur | Date de publication
          Row(
            children: [
              Flexible(
                flex: 1,
                child: _InfoCell(
                  icon: Icons.business_rounded,
                  label: 'Éditeur',
                  value: book.publisher ?? '—',
                  palette: palette,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: _InfoCell(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date de publication',
                  value: book.publishedDate ?? '—',
                  palette: palette,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemePalette palette;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: palette.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Progression — pages restantes + barre
// ============================================================
class _ProgressSection extends StatelessWidget {
  final int pagesRead;
  final int pageCount;
  final int? remainingPages;
  final ThemePalette palette;
  final bool isDark;

  const _ProgressSection({
    required this.pagesRead,
    required this.pageCount,
    required this.remainingPages,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = pageCount > 0 ? (pagesRead / pageCount).clamp(0.0, 1.0) : 0.0;
    final rest = remainingPages ?? (pageCount - pagesRead).clamp(0, pageCount);
    final couleur = palette.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texte de progression
          Text(
            '$pagesRead / $pageCount pages lues',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$rest restantes',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: palette.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: couleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: palette.textSecondary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(couleur),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Section header
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final ThemePalette palette;

  const _SectionHeader({
    required this.title,
    required this.palette,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

// ============================================================
// Description (expandable / collapsible)
// ============================================================
class _DescriptionCard extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final bool isDark;
  final ThemePalette palette;
  final VoidCallback onToggle;

  const _DescriptionCard({
    required this.description,
    required this.isExpanded,
    required this.isDark,
    required this.palette,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const int maxLines = 5;
    final bool isLong =
        description.split('\n').length > maxLines || description.length > 250;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: palette.textSecondary,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: palette.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          if (isLong) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onToggle,
              child: Row(
                children: [
                  Text(
                    isExpanded ? 'Réduire' : 'Lire la suite',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Catégories (chips)
// ============================================================
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final ThemePalette palette;
  final bool isDark;

  const _CategoryChips({
    required this.categories,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((cat) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: palette.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// Étoiles de notation (1-5) — visible pour TOUS les livres
// ============================================================
class _StarRating extends StatelessWidget {
  final double rating;
  final ThemePalette palette;
  final ValueChanged<double>? onChanged;

  const _StarRating({
    required this.rating,
    required this.palette,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surfaceCardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final starValue = i + 1.0;
          final filled = starValue <= rating;
          final halfFilled =
              !filled && (starValue - 0.5) <= rating;

          return GestureDetector(
            onTap: onChanged != null ? () => onChanged!(starValue) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AnimatedScale(
                scale: filled ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  filled
                      ? Icons.star_rounded
                      : halfFilled
                          ? Icons.star_half_rounded
                          : Icons.star_border_rounded,
                  size: 34,
                  color: filled
                      ? const Color(0xFFD97A60)
                      : palette.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ============================================================
// Section session : lancer ou reprendre une session
// ============================================================
class _SessionActionSection extends ConsumerWidget {
  final ReadingSession? activeSession;
  final String bookId;
  final ThemePalette palette;
  final bool isDark;

  const _SessionActionSection({
    required this.activeSession,
    required this.bookId,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = activeSession != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasActive) ...[
            // Infos de la session active
            Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: palette.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Session active',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8E4E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'En cours',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B8E4E),
                    ),
                  ),
                ),
              ],
            ),
            if (activeSession!.startPage != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded,
                      size: 14, color: palette.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Débuté page ${activeSession!.startPage}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.session(bookId));
                },
                icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
                label: const Text('Reprendre la lecture'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Aucune session active
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline_rounded,
                  size: 22,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Pas de session en cours',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Lancer une nouvelle session
                  final db = ref.read(databaseProvider);
                  db.startSession(bookId);
                  ref.invalidate(activeBookSessionProvider(bookId));
                  ref.invalidate(bookSessionsProvider(bookId));
                  Navigator.pushNamed(context, AppRouter.session(bookId));
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: const Text('Lancer une session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// Liste des sessions
// ============================================================
class _SessionList extends ConsumerWidget {
  final AsyncValue<List<ReadingSession>> sessionsAsync;
  final String? bookTitle;
  final ThemePalette palette;
  final bool isDark;

  const _SessionList({
    required this.sessionsAsync,
    required this.palette,
    required this.isDark,
    this.bookTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return sessionsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erreur : $err',
          style: GoogleFonts.inter(color: AppTheme.error),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? palette.surfaceCardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('⏱️', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  'Aucune séance',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez la lecture pour suivre votre progression',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: sessions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionTile(
              session: s,
              bookTitle: bookTitle,
              palette: palette,
            ),
          )).toList(),
        );
      },
    );
  }
}

// ============================================================
// Tuile de session individuelle
// ============================================================
class _SessionTile extends StatelessWidget {
  final ReadingSession session;
  final String? bookTitle;
  final ThemePalette palette;

  const _SessionTile({
    required this.session,
    required this.palette,
    this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    final duration = session.durationSeconds != null
        ? Duration(seconds: session.durationSeconds!)
        : null;

    final dateStr = _formatSessionDate(session.startTime);
    final timeStr = _formatTime(session.startTime);
    final durStr = _formatDurationShort(duration);
    final pagesStr = session.pagesRead != null
        ? '${session.pagesRead} pages'
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceCardLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: palette.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: palette.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      durStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    if (pagesStr != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.auto_stories_rounded,
                          size: 13, color: palette.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        pagesStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Heure
          Text(
            timeStr,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSessionDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return 'Hier';
    if (diff < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDurationShort(Duration? duration) {
    if (duration == null) return '—';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0) return '${minutes}m';
    return '< 1m';
  }
}

// ============================================================
// Barre d'action en bas — toujours "Lire"
// ============================================================
class _BottomActionBar extends StatelessWidget {
  final Book book;
  final ThemePalette palette;
  final bool isDark;
  final VoidCallback onRead;

  const _BottomActionBar({
    required this.book,
    required this.palette,
    required this.isDark,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? palette.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: onRead,
            icon: const Icon(Icons.menu_book_rounded, size: 22),
            label: const Text('Lire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
