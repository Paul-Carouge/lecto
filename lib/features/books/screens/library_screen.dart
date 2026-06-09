import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/books/widgets/book_card.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// Main book library screen showing all books in a beautiful grid.
///
/// Features:
///   - Search bar at top
///   - Filter chips for reading status
///   - Beautiful book cards with cover, title, author, progress
///   - Tap to navigate to book detail
///   - FAB to add a book
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  ReadingStatus? _selectedFilter;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bibliothèque',
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par titre, auteur ou ISBN...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: isDark ? AppTheme.surfaceCard : Colors.grey.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

          // Filter chips
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'Tous',
                  selected: _selectedFilter == null,
                  onTap: () => setState(() => _selectedFilter = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'En cours',
                  selected: _selectedFilter == ReadingStatus.reading,
                  onTap: () => setState(() => _selectedFilter = ReadingStatus.reading),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Terminé',
                  selected: _selectedFilter == ReadingStatus.finished,
                  onTap: () => setState(() => _selectedFilter = ReadingStatus.finished),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'À lire',
                  selected: _selectedFilter == ReadingStatus.wantToRead,
                  onTap: () => setState(() => _selectedFilter = ReadingStatus.wantToRead),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Abandonné',
                  selected: _selectedFilter == ReadingStatus.abandoned,
                  onTap: () => setState(() => _selectedFilter = ReadingStatus.abandoned),
                ),
              ],
            ),
          ),

          // Book grid
          Expanded(
            child: _buildBookList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-book'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildBookList() {
    final search = _searchController.text.trim();

    if (_selectedFilter != null) {
      return _BookGrid(
        provider: booksByStatusProvider(_selectedFilter!),
        searchFilter: search.isNotEmpty ? search : null,
        ref: ref,
        onBookTap: (book) => Navigator.pushNamed(context, '/book/${book.id}'),
      );
    }

    return _BookGrid(
      provider: allBooksProvider,
      searchFilter: search.isNotEmpty ? search : null,
      ref: ref,
      onBookTap: (book) => Navigator.pushNamed(context, '/book/${book.id}'),
    );
  }
}

class _BookGrid extends ConsumerWidget {
  final dynamic provider;
  final String? searchFilter;
  final void Function(Book) onBookTap;
  final WidgetRef ref;

  const _BookGrid({
    required this.provider,
    this.searchFilter,
    required this.onBookTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final asyncBooks = ref.watch(provider as FutureProvider<List<Book>>);

    return asyncBooks.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const _BookCardSkeleton(),
        ),
      ),
      error: (err, _) => EmptyState(
        emoji: '😵',
        title: 'Une erreur est survenue',
        subtitle: err.toString(),
      ),
      data: (books) {
        var filtered = books;
        if (searchFilter != null && searchFilter!.isNotEmpty) {
          final q = searchFilter!.toLowerCase();
          filtered = books.where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q) ||
            (b.isbn?.toLowerCase().contains(q) ?? false)
          ).toList();
        }

        if (filtered.isEmpty) {
          return EmptyState(
            emoji: searchFilter != null ? '🔍' : '📚',
            title: searchFilter != null ? 'Aucun livre trouvé' : 'Votre bibliothèque est vide',
            subtitle: searchFilter != null
                ? 'Essayez un autre terme de recherche'
                : 'Ajoutez votre premier livre pour commencer !',
            actionLabel: 'Ajouter un livre',
            actionIcon: Icons.add_rounded,
            onAction: () => Navigator.pushNamed(context, '/add-book'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final book = filtered[index];
                return BookCard(
                  book: book,
                  onTap: () => onBookTap(book),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? AppTheme.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.surfaceCard
                  : Colors.grey.withValues(alpha: 0.1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _BookCardSkeleton extends StatelessWidget {
  const _BookCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppTheme.surfaceCard : Colors.grey.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
