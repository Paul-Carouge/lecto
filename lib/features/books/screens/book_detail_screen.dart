import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

// ============================================================
// BookDetailScreen — écran détail du livre, version redesigned
// ============================================================

/// Écran de détail d'un livre, complètement repensé.
///
/// Affiche :
///   - AppBar avec titre + retour
///   - Grande couverture centrée (200px)
///   - Titre (Outfit 22 bold), Auteur (Inter 15 muted)
///   - Badge de statut coloré
///   - Grille d'infos 2×2 (Pages, ISBN, Éditeur, Date)
///   - Description expandable
///   - Catégories en chips
///   - Sessions associées
///   - Bouton d'action principal contextuel
///   - Note par étoiles si terminé
///   - Changement de statut rapide
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final sessionsAsync = ref.watch(bookSessionsProvider(widget.bookId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return bookAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erreur : $err')),
      ),
      data: (book) {
        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              emoji: '😕',
              title: 'Livre introuvable',
            ),
          );
        }

        final sessionsList = sessionsAsync.valueOrNull ?? [];

        return Scaffold(
          backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          body: CustomScrollView(
            slivers: [
              // ========== AppBar ==========
              SliverAppBar(
                expandedHeight: 0,
                pinned: true,
                backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : AppTheme.textPrimary,
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
                    color: isDark ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                actions: [
                  PopupMenuButton<ReadingStatus>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? Colors.white70 : AppTheme.textSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (status) {
                      _updateStatus(book, status);
                    },
                    itemBuilder: (_) => [
                      _statusMenuItem(
                        'À lire',
                        ReadingStatus.wantToRead,
                        Icons.bookmark_border_rounded,
                        AppTheme.warning,
                        book.status,
                      ),
                      _statusMenuItem(
                        'En cours',
                        ReadingStatus.reading,
                        Icons.menu_book_rounded,
                        _statusColor(ReadingStatus.reading),
                        book.status,
                      ),
                      _statusMenuItem(
                        'Terminé',
                        ReadingStatus.finished,
                        Icons.check_circle_outline_rounded,
                        _statusColor(ReadingStatus.finished),
                        book.status,
                      ),
                      _statusMenuItem(
                        'Abandonné',
                        ReadingStatus.abandoned,
                        Icons.block_rounded,
                        _statusColor(ReadingStatus.abandoned),
                        book.status,
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: AppTheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Supprimer',
                              style: GoogleFonts.inter(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      child: _BookCover(book: book),
                    ),
                    const SizedBox(height: 24),

                    // ---- 2. Titre + Auteur + Statut ----
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _TitleSection(book: book),
                    ),
                    const SizedBox(height: 24),

                    // ---- 3. Grille d'infos 2×2 ----
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _InfoGrid(book: book),
                    ),
                    const SizedBox(height: 24),

                    // ---- 4. Description ----
                    if (book.description != null &&
                        book.description!.isNotEmpty) ...[
                      _SectionHeader(title: 'Description'),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _DescriptionCard(
                          description: book.description!,
                          isExpanded: _descriptionExpanded,
                          onToggle: () {
                            setState(() {
                              _descriptionExpanded = !_descriptionExpanded;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 5. Catégories ----
                    if (book.categories.isNotEmpty) ...[
                      _SectionHeader(title: 'Catégories'),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _CategoryChips(categories: book.categories),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 6. Note personnelle (si terminé) ----
                    if (book.status == ReadingStatus.finished) ...[
                      _SectionHeader(title: 'Ma note'),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _StarRating(
                          rating: _pendingRating ?? book.myRating ?? 0,
                          onChanged: (rating) {
                            setState(() => _pendingRating = rating);
                            _updateRating(book.id, rating);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ---- 7. Sessions associées ----
                    _SectionHeader(
                      title: 'Séances de lecture',
                      trailing: sessionsList.isNotEmpty
                          ? Text(
                              '${sessionsList.length} séance${sessionsList.length > 1 ? 's' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
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
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),

          // ========== Bouton d'action flottant en bas ==========
          bottomNavigationBar: _BottomActionBar(
            book: book,
            onStartReading: () {
              Navigator.pushNamed(context, '/session/${book.id}');
            },
            onMarkFinished: () {
              _updateStatus(book, ReadingStatus.finished);
            },
            onRateBook: () {
              // Défile jusqu'à la section note
            },
          ),
        );
      },
    );
  }

  PopupMenuItem<ReadingStatus> _statusMenuItem(
    String label,
    ReadingStatus status,
    IconData icon,
    Color color,
    ReadingStatus currentStatus,
  ) {
    final isSelected = status == currentStatus;
    return PopupMenuItem(
      value: isSelected ? null : status,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? color : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check_circle_rounded, size: 18, color: color),
          ],
        ],
      ),
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
}

// ============================================================
// Couverture
// ============================================================
class _BookCover extends StatelessWidget {
  final Book book;

  const _BookCover({required this.book});

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
                  errorWidget: (_, _, _) => _CoverPlaceholder(),
                )
              : const _CoverPlaceholder(),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.6),
            AppTheme.accent.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.menu_book_rounded, size: 56, color: Colors.white38),
      ),
    );
  }
}

// ============================================================
// Titre + Auteur + Badge statut
// ============================================================
class _TitleSection extends StatelessWidget {
  final Book book;

  const _TitleSection({required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          book.title,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),

        // Auteur
        Text(
          book.author,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),

        // Badge de statut
        _StatusBadge(status: book.status),
      ],
    );
  }
}

// ============================================================
// Badge de statut coloré
// ============================================================
Color _statusColor(ReadingStatus status) {
  return switch (status) {
    ReadingStatus.reading => AppTheme.accent, // terracotta
    ReadingStatus.finished => AppTheme.success, // green
    ReadingStatus.wantToRead => AppTheme.textSecondary, // grey
    ReadingStatus.abandoned => AppTheme.error, // red
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

  const _InfoGrid({required this.book});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <_InfoItem>[
      _InfoItem(
        icon: Icons.auto_stories_rounded,
        label: 'Pages',
        value: book.pageCount?.toString() ?? '—',
      ),
      _InfoItem(
        icon: Icons.qr_code_rounded,
        label: 'ISBN',
        value: book.isbn ?? '—',
      ),
      _InfoItem(
        icon: Icons.business_rounded,
        label: 'Éditeur',
        value: book.publisher ?? '—',
      ),
      _InfoItem(
        icon: Icons.calendar_today_rounded,
        label: 'Date de publication',
        value: book.publishedDate ?? '—',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => _InfoTile(item: items[i]),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;

  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
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
// Section header
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
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
// Description (expandable/collapsible)
// ============================================================
class _DescriptionCard extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _DescriptionCard({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const int maxLines = 5;
    final isLong = description.split('\n').length > maxLines ||
        description.length > 250;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            secondChild: Text(
              description,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
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
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppTheme.primary,
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

  const _CategoryChips({required this.categories});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              cat,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// Étoiles de notation (1-5)
// ============================================================
class _StarRating extends StatelessWidget {
  final double rating;
  final ValueChanged<double>? onChanged;

  const _StarRating({required this.rating, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surfaceCard
            : Colors.white,
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
          final halfFilled = !filled && (starValue - 0.5) <= rating;

          return GestureDetector(
            onTap: onChanged != null ? () => onChanged!(starValue) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedScale(
                scale: filled ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  filled
                      ? Icons.star_rounded
                      : halfFilled
                          ? Icons.star_half_rounded
                          : Icons.star_border_rounded,
                  size: 32,
                  color: filled
                      ? AppTheme.warning
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
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
// Liste des sessions
// ============================================================
class _SessionList extends ConsumerWidget {
  final AsyncValue<List<ReadingSession>> sessionsAsync;
  final String? bookTitle;

  const _SessionList({
    required this.sessionsAsync,
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
        child: Text('Erreur : $err'),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.surfaceCard
                  : Colors.white,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez la lecture pour suivre votre progression',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
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

  const _SessionTile({required this.session, this.bookTitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        color: isDark ? AppTheme.surfaceCard : Colors.white,
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
              color: AppTheme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Durée
                    Icon(Icons.schedule_rounded,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      durStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (pagesStr != null) ...[
                      const SizedBox(width: 14),
                      Icon(Icons.auto_stories_rounded,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        pagesStr,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
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
              color: AppTheme.textSecondary,
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
// Barre d'action en bas (contextuelle selon le statut)
// ============================================================
class _BottomActionBar extends StatelessWidget {
  final Book book;
  final VoidCallback onStartReading;
  final VoidCallback onMarkFinished;
  final VoidCallback onRateBook;

  const _BottomActionBar({
    required this.book,
    required this.onStartReading,
    required this.onMarkFinished,
    required this.onRateBook,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
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
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (book.status) {
      case ReadingStatus.wantToRead:
        return _ActionButton(
          icon: Icons.play_arrow_rounded,
          label: 'Commencer la lecture',
          color: AppTheme.primary,
          onPressed: onStartReading,
        );

      case ReadingStatus.reading:
        return _ActionButton(
          icon: Icons.check_rounded,
          label: 'Marquer comme terminé',
          color: AppTheme.success,
          onPressed: onMarkFinished,
        );

      case ReadingStatus.finished:
        return _ActionButton(
          icon: Icons.star_rounded,
          label: 'Noter ce livre',
          color: AppTheme.warning,
          onPressed: onRateBook,
        );

      case ReadingStatus.abandoned:
        return _ActionButton(
          icon: Icons.play_arrow_rounded,
          label: 'Reprendre la lecture',
          color: AppTheme.primary,
          onPressed: onStartReading,
        );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
    );
  }
}
