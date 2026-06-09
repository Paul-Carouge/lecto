import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/theme/app_theme.dart';

/// A widget for displaying a single book recommendation in a card.
///
/// Shows the cover image, title, author, reason for recommendation,
/// and a dismiss button.
class RecommendationCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverUrl;
  final String recommendationType;
  final double score;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const RecommendationCard({
    super.key,
    required this.title,
    required this.author,
    this.coverUrl,
    this.recommendationType = 'genre_similar',
    this.score = 0.0,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reason = switch (recommendationType) {
      'genre_similar' => 'Parce que vous aimez ce genre',
      'author_similar' => 'Par un auteur que vous lisez',
      'popular' => 'Populaire dans vos genres',
      _ => 'Recommandé pour vous',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppTheme.surfaceCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 80,
                child: coverUrl != null && coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _coverPlaceholder(),
                        errorWidget: (_, __, ___) => _coverPlaceholder(),
                      )
                    : _coverPlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: _reasonColor(recommendationType).withValues(alpha: 0.1),
                    ),
                    child: Text(
                      reason,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _reasonColor(recommendationType),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Dismiss button
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
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
        borderRadius: BorderRadius.circular(10),
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
          size: 28,
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Color _reasonColor(String type) {
    return switch (type) {
      'genre_similar' => AppTheme.primary,
      'author_similar' => AppTheme.accent,
      'popular' => AppTheme.success,
      _ => AppTheme.primary,
    };
  }
}
