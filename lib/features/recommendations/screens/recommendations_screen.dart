import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/features/recommendations/providers/recommendation_providers.dart';
import 'package:lecto/features/recommendations/widgets/recommendation_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// Book recommendations screen.
///
/// Shows:
///   - Cards with cover, title, author, reason
///   - Dismiss button on each card
///   - Refresh button to generate new recommendations
///   - Categories like "Because you read X", "Similar genres", "Popular"
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recommandations',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(recommendationEngineProvider.notifier).generate();
            },
            tooltip: 'Actualiser les recommandations',
          ),
        ],
      ),
      body: recsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (recs) {
          if (recs.isEmpty) {
            return Center(
              child: EmptyState(
                emoji: '📖',
                title: 'Aucune recommandation',
                subtitle: 'Ajoutez et terminez d\'abord des livres !',
                actionLabel: 'Générer des recommandations',
                onAction: () {
                  ref.read(recommendationEngineProvider.notifier).generate();
                },
              ),
            );
          }

          // Group by type
          final grouped = <String, List<Recommendation>>{};
          for (final rec in recs) {
            grouped.putIfAbsent(rec.recommendationType, () => []).add(rec);
          }

          final typeLabels = {
            'genre_similar': 'Basé sur vos lectures similaires',
            'author_similar': 'Par des auteurs que vous connaissez',
            'popular': 'Populaire dans vos genres',
          };

          final typeEmojis = {
            'genre_similar': '📚',
            'author_similar': '✍️',
            'popular': '🔥',
          };

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(recommendationEngineProvider.notifier).generate();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
              children: [
                Text(
                  'Découvrez votre prochaine lecture',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                ...grouped.entries.map((entry) {
                  final type = entry.key;
                  final items = entry.value;
                  final label = typeLabels[type] ?? 'Recommandations';
                  final emoji = typeEmojis[type] ?? '📖';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...items.map((rec) {
                          // We lookup the book data... For now, use recommendation metadata
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RecommendationCard(
                              title: 'Book #${rec.bookId.substring(0, 6)}',
                              author: 'Auteur inconnu',
                              recommendationType: rec.recommendationType,
                              score: rec.score,
                              onDismiss: () {
                                ref.read(
                                  dismissRecommendationProvider(rec.id).notifier,
                                ).dismiss();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
