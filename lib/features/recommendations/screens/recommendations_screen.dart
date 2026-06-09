import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/features/recommendations/providers/recommendation_providers.dart';
import 'package:lecto/core/router/app_router.dart';

// ============================================================
// RecommendationsScreen — Écran Recommandations redessiné
// ============================================================

/// Écran de recommandations repensé avec :
///   - Grille 2 colonnes en cascade/masonry
///   - Cartes avec couverture, titre, auteur, badge
///   - Swipe pour dismiss (fond terracotta)
///   - Skeleton shimmer au chargement
///   - Stagger d'entrée animé
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends ConsumerState<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _generateRecommendations() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await ref.read(recommendationEngineProvider.notifier).generate();
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recsAsync = ref.watch(recommendationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? ThemePalette.terracotta : ThemePalette.terracotta;
    final scaffoldBg = isDark
        ? palette.surfaceDark
        : const Color(0xFFF8F5F0);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Recommandations',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isGenerating ? null : _generateRecommendations,
            tooltip: 'Nouvelles recommandations',
          ),
        ],
      ),
      body: recsAsync.when(
        loading: () => _buildLoadingShimmer(palette, isDark),
        error: (err, _) => _buildErrorState(err, palette, isDark),
        data: (recs) {
          if (recs.isEmpty) {
            return _buildEmptyState(palette, isDark);
          }
          // Lancer l'animation stagger au premier build avec données
          if (!_staggerController.isAnimating && !_staggerController.isCompleted) {
            _staggerController.forward();
          }
          return _buildRecommendationGrid(recs, palette, isDark);
        },
      ),
    );
  }

  // ============================================================
  // Loading shimmer — 4 skeleton cards
  // ============================================================
  Widget _buildLoadingShimmer(ThemePalette palette, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de titre skeleton
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 4),
            child: _ShimmerBox(
              width: 200,
              height: 18,
              borderRadius: 6,
              isDark: isDark,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSkeletonCard(isDark),
                    const SizedBox(height: 16),
                    _buildSkeletonCard(isDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildSkeletonCard(isDark),
                    const SizedBox(height: 16),
                    _buildSkeletonCard(isDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark) {
    final cardColor = isDark
        ? const Color(0xFF2A2725)
        : Colors.white;
    final skeletonBase = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover placeholder
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _ShimmerBox(
              height: 120,
              borderRadius: 0,
              isDark: isDark,
              baseColor: skeletonBase,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  height: 13,
                  width: double.infinity,
                  borderRadius: 4,
                  isDark: isDark,
                  baseColor: skeletonBase,
                ),
                const SizedBox(height: 6),
                _ShimmerBox(
                  height: 13,
                  width: 120,
                  borderRadius: 4,
                  isDark: isDark,
                  baseColor: skeletonBase,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  height: 10,
                  width: 100,
                  borderRadius: 4,
                  isDark: isDark,
                  baseColor: skeletonBase,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Empty state
  // ============================================================
  Widget _buildEmptyState(ThemePalette palette, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 48,
                color: palette.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune recommandation',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? palette.textOnDark : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ajoutez et terminez des livres\npour obtenir des recommandations',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isDark
                    ? palette.textOnDark.withValues(alpha: 0.6)
                    : palette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.library);
                },
                icon: const Icon(Icons.explore_rounded, size: 20),
                label: Text(
                  'Explorer la bibliothèque',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Error state
  // ============================================================
  Widget _buildErrorState(Object err, ThemePalette palette, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: palette.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? palette.textOnDark : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              err.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? palette.textOnDark.withValues(alpha: 0.5)
                    : palette.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _generateRecommendations,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Réessayer',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Recommendation grid — 2 colonnes masonry
  // ============================================================
  Widget _buildRecommendationGrid(
    List<Recommendation> recs,
    ThemePalette palette,
    bool isDark,
  ) {
    // Distribution en deux colonnes pour un effet masonry
    final leftCol = <Recommendation>[];
    final rightCol = <Recommendation>[];
    for (var i = 0; i < recs.length; i++) {
      if (i.isEven) {
        leftCol.add(recs[i]);
      } else {
        rightCol.add(recs[i]);
      }
    }

    return RefreshIndicator(
      onRefresh: _generateRecommendations,
      color: palette.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Indicateur de génération subtil
          if (_isGenerating)
            SliverToBoxAdapter(
              child: _buildGeneratingBanner(palette, isDark),
            ),
          // En-tête
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Découvrez votre prochaine lecture',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? palette.textOnDark.withValues(alpha: 0.7)
                          : palette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${recs.length} suggestions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? palette.textOnDark.withValues(alpha: 0.5)
                          : palette.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Grille masonry
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colonne gauche
                  Expanded(
                    child: Column(
                      children: List.generate(leftCol.length, (i) {
                        return _buildCardWrapper(
                          leftCol[i],
                          i * 2,
                          recs.length,
                          palette,
                          isDark,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Colonne droite (décalée)
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 24), // décalage
                        ...List.generate(rightCol.length, (i) {
                          return _buildCardWrapper(
                            rightCol[i],
                            i * 2 + 1,
                            recs.length,
                            palette,
                            isDark,
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Espacement bas
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // ============================================================
  // Bannière "Génération en cours"
  // ============================================================
  Widget _buildGeneratingBanner(ThemePalette palette, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: palette.primary.withValues(alpha: isDark ? 0.15 : 0.08),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Génération de nouvelles recommandations…',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: palette.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Card wrapper — stagger + Dismissible
  // ============================================================
  Widget _buildCardWrapper(
    Recommendation rec,
    int index,
    int total,
    ThemePalette palette,
    bool isDark,
  ) {
    final delay = (index * 80).clamp(0, 600);
    final anim = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(
        delay / 600,
        ((delay + 200) / 600).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    final card = AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - anim.value)),
            child: child,
          ),
        );
      },
      child: _RecommendationCard(
        recommendation: rec,
        palette: palette,
        isDark: isDark,
        onDismiss: () {
          ref
              .read(dismissRecommendationProvider(rec.id).notifier)
              .dismiss();
        },
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.bookDetail(rec.bookId),
          );
        },
      ),
    );

    // Wrapper Dismissible pour le swipe
    return Dismissible(
      key: ValueKey('reco_${rec.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: palette.primary,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.do_not_disturb_alt_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Pas\nintéressé',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        ref
            .read(dismissRecommendationProvider(rec.id).notifier)
            .dismiss();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card,
      ),
    );
  }
}

// ============================================================
// Recommendation card widget
// ============================================================
class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final ThemePalette palette;
  final bool isDark;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.palette,
    required this.isDark,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rec = recommendation;

    final reasonLabel = switch (rec.recommendationType) {
      'genre_similar' => 'Basé sur vos lectures',
      'author_similar' => 'Par un auteur suivi',
      'popular' => 'Populaire',
      _ => 'Recommandé',
    };

    final reasonColor = switch (rec.recommendationType) {
      'genre_similar' => palette.primary,
      'author_similar' => palette.accent,
      'popular' => const Color(0xFF10B981),
      _ => palette.primary,
    };

    final cardColor = isDark
        ? const Color(0xFF2A2725)
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity,
                height: 120,
                child: rec.coverUrl != null && rec.coverUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: rec.coverUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _coverPlaceholder(palette),
                        errorWidget: (context, url, error) =>
                            _coverPlaceholder(palette),
                      )
                    : _coverPlaceholder(palette),
              ),
            ),
            // Infos
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    rec.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: isDark ? palette.textOnDark : palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Auteur
                  Text(
                    rec.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? palette.textOnDark.withValues(alpha: 0.6)
                          : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Badge raison
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: reasonColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rec.recommendationType == 'popular'
                              ? Icons.trending_up_rounded
                              : rec.recommendationType == 'author_similar'
                                  ? Icons.person_rounded
                                  : Icons.auto_stories_rounded,
                          size: 12,
                          color: reasonColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            reasonLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: reasonColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ThemePalette palette) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.15),
            palette.accent.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          size: 40,
          color: palette.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

// ============================================================
// Shimmer box widget
// ============================================================
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;
  final Color? baseColor;

  const _ShimmerBox({
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    required this.isDark,
    this.baseColor,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ??
        (widget.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.12));
    final highlight = widget.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.18);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                base,
                highlight,
                base,
              ],
              stops: [
                max(0.0, _animation.value - 0.5),
                _animation.value,
                min(1.0, _animation.value + 0.5),
              ],
            ),
          ),
        );
      },
    );
  }
}
