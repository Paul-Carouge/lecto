import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';
import 'package:lecto/features/sessions/widgets/session_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';
import 'package:lecto/shared/widgets/stat_card.dart';

/// Detail view of a book with all its information and actions.
///
/// Features:
///   - Hero cover image at top
///   - Title, author, rating
///   - Status chip with changeable selector
///   - Stats summary (pages read, sessions, time)
///   - Reading sessions list for this book
///   - "Start Reading" / "Resume" button
///   - Notes section
///   - AppBar with edit/delete actions
class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(currentBookProvider(bookId));
    final sessionsAsync = ref.watch(bookSessionsProvider(bookId));

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
              title: 'Book not found',
            ),
          );
        }
        return _BookDetailContent(
          book: book,
          sessionsAsync: sessionsAsync,
        );
      },
    );
  }
}

class _BookDetailContent extends ConsumerWidget {
  final Book book;
  final AsyncValue<List<ReadingSession>> sessionsAsync;

  const _BookDetailContent({
    required this.book,
    required this.sessionsAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with cover behind
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'book_cover_${book.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover image
                    if (book.coverUrl != null && book.coverUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: book.coverUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _coverGradient(),
                      )
                    else
                      _coverGradient(),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    // Title overlay at bottom
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => _showStatusPicker(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.white),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status + Rating row
                Row(
                  children: [
                    _StatusChip(book: book),
                    const Spacer(),
                    if (book.myRating != null)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < book.myRating!.round();
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 20,
                              color: filled ? AppTheme.warning : AppTheme.textSecondary.withValues(alpha: 0.3),
                            );
                          }),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(child: StatCardCompact(
                      label: 'Pages lues',
                      value: Formatters.formatPagesShort(book.pageCount),
                      icon: Icons.auto_stories_rounded,
                      color: AppTheme.primary,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatCardCompact(
                      label: 'Séances',
                      value: '${_countSessions(ref)}',
                      icon: Icons.timer_rounded,
                      color: AppTheme.accent,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: StatCardCompact(
                      label: 'Temps total',
                      value: Formatters.formatDuration(_totalTime(ref)),
                      icon: Icons.schedule_rounded,
                      color: AppTheme.success,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Start/Resume button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/session/${book.id}'),
                    icon: Icon(
                      book.status == ReadingStatus.finished
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded,
                      size: 22,
                    ),
                    label: Text(
                      book.status == ReadingStatus.finished
                          ? 'Relire'
                          : book.status == ReadingStatus.reading
                              ? 'Continuer la lecture'
                              : 'Commencer la lecture',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                if (book.description != null && book.description!.isNotEmpty) ...[
                  _SectionTitle(title: 'Description'),
                  const SizedBox(height: 8),
                  Text(
                    book.description!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Details
                if (book.publisher != null || book.isbn != null || book.pageCount != null) ...[
                  _SectionTitle(title: 'Détails'),
                  const SizedBox(height: 8),
                  _DetailRow(label: 'Éditeur', value: book.publisher),
                  _DetailRow(label: 'ISBN', value: book.isbn),
                  _DetailRow(label: 'Pages', value: book.pageCount?.toString()),
                  _DetailRow(label: 'Date de publication', value: book.publishedDate),
                  _DetailRow(label: 'Langue', value: book.language),
                  const SizedBox(height: 24),
                ],

                // Notes
                if (book.notes != null && book.notes!.isNotEmpty) ...[
                  _SectionTitle(title: 'Notes'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark ? AppTheme.surfaceCard.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.06),
                    ),
                    child: Text(
                      book.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Reading sessions
                _SectionTitle(title: 'Séances de lecture'),
                const SizedBox(height: 8),
                _SessionList(sessionsAsync: sessionsAsync),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  int _countSessions(WidgetRef ref) {
    final sessions = ref.watch(bookSessionsProvider(book.id));
    return sessions.valueOrNull?.length ?? 0;
  }

  Duration _totalTime(WidgetRef ref) {
    final sessions = ref.watch(bookSessionsProvider(book.id));
    final list = sessions.valueOrNull ?? [];
    return Duration(
      seconds: list.fold<int>(0, (sum, s) => sum + (s.durationSeconds ?? 0)),
    );
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Changer le statut',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...ReadingStatus.values.map((status) {
                final (label, icon, color) = switch (status) {
                  ReadingStatus.wantToRead => ('À lire', Icons.bookmark_border_rounded, AppTheme.warning),
                  ReadingStatus.reading => ('En cours de lecture', Icons.menu_book_rounded, AppTheme.primary),
                  ReadingStatus.finished => ('Terminé', Icons.check_circle_outline_rounded, AppTheme.success),
                  ReadingStatus.abandoned => ('Abandonné', Icons.block_rounded, AppTheme.error),
                };
                final isSelected = status == book.status;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(icon, color: isSelected ? color : AppTheme.textSecondary),
                    title: Text(label),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded, color: color, size: 22)
                        : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: isSelected ? color.withValues(alpha: 0.08) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(updateBookStatusProvider(book.id, status).notifier).applyUpdate();
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Supprimer "${book.title}" ?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: const Text('Cela supprimera définitivement le livre et toutes ses séances de lecture.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              db.deleteBook(book.id);
              ref.invalidate(allBooksProvider);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

Widget _coverGradient() {
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
      child: Icon(Icons.menu_book_rounded, size: 80, color: Colors.white38),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final Book book;

  const _StatusChip({required this.book});

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (book.status) {
      ReadingStatus.wantToRead => ('À lire', Icons.bookmark_border_rounded, AppTheme.warning),
      ReadingStatus.reading => ('En cours', Icons.menu_book_rounded, AppTheme.primary),
      ReadingStatus.finished => ('Terminé', Icons.check_circle_outline_rounded, AppTheme.success),
      ReadingStatus.abandoned => ('Abandonné', Icons.block_rounded, AppTheme.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const _DetailRow({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionList extends ConsumerWidget {
  final AsyncValue<List<ReadingSession>> sessionsAsync;

  const _SessionList({required this.sessionsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return sessionsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      )),
      error: (err, _) => Text('Erreur : $err'),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: EmptyState(
              emoji: '⏱️',
              title: 'Aucune séance',
              subtitle: 'Commencez à lire pour suivre votre progression !',
            ),
          );
        }
        return Column(
          children: sessions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SessionCard(session: s),
          )).toList(),
        );
      },
    );
  }
}
