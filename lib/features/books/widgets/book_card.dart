import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/utils/formatters.dart';

/// A beautiful card widget for displaying a book in the library grid.
///
/// Shows the cover image, title, author, a status badge,
/// and a reading progress bar if the book is currently being read.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final double? width;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final status = book.status;
    final isReading = status == ReadingStatus.reading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'book_cover_${book.id}',
        child: Container(
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? AppTheme.surfaceCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cover image — fixed height
              SizedBox(
                height: 140,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: _buildCover(),
                ),
              ),
              // Info area
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // Author
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badge
                    if (isReading && book.pageCount != null && book.pageCount! > 0)
                      _buildProgressBar(context)
                    else
                      _buildStatusBadge(context, status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: book.coverUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => _coverPlaceholder(),
        errorWidget: (_, __, ___) => _coverPlaceholder(),
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          size: 36,
          color: AppTheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, ReadingStatus status) {
    final (label, color) = _statusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: 0.0,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '0%',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  (String, Color) _statusData(ReadingStatus status) {
    return switch (status) {
      ReadingStatus.reading => ('En cours', AppTheme.primary),
      ReadingStatus.finished => ('Terminé', AppTheme.success),
      ReadingStatus.abandoned => ('Abandonné', AppTheme.error),
      ReadingStatus.wantToRead => ('À lire', AppTheme.warning),
    };
  }
}

/// A compact horizontal book card for use in lists (e.g., home screen).
class BookCardHorizontal extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final Widget? trailing;

  const BookCardHorizontal({
    super.key,
    required this.book,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? AppTheme.surfaceCard : Colors.white,
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
            // Cover thumbnail
            Hero(
              tag: 'book_cover_${book.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 70,
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _miniPlaceholder(),
                          errorWidget: (_, __, ___) => _miniPlaceholder(),
                        )
                      : _miniPlaceholder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatPages(book.pageCount),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.book_rounded, size: 24, color: AppTheme.primary.withValues(alpha: 0.3)),
    );
  }
}
