import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/features/books/providers/book_providers.dart';
import 'package:lecto/features/sessions/providers/session_providers.dart';

/// The reading session timer screen.
///
/// Features a large timer display, page tracker, and controls.
class ActiveSessionScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ActiveSessionScreen({super.key, required this.bookId});

  @override
  ConsumerState<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends ConsumerState<ActiveSessionScreen>
    with WidgetsBindingObserver {
  final _startPageController = TextEditingController();
  bool _showStartPageInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _startPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(activeSessionProvider.notifier);
    if (state == AppLifecycleState.paused && notifier.state.isRunning) {
      notifier.pauseSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final db = ref.watch(databaseProvider);
    final bookAsync = ref.watch(currentBookProvider(widget.bookId));
    final sessionState = ref.watch(activeSessionProvider);

    return bookAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (book) {
        if (book == null) {
          return const Scaffold(
            body: Center(child: Text('Book not found')),
          );
        }

        final hasStarted = sessionState.isRunning || sessionState.sessionId != null;

        return Scaffold(
          backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
          appBar: AppBar(
            title: Text(
              book.title,
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Book info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Timer display
                _TimerDisplay(
                  elapsed: sessionState.elapsed,
                  isRunning: sessionState.isRunning,
                ),

                const Spacer(flex: 1),

                // Page tracker
                if (hasStarted) ...[
                  _PageTracker(
                    currentPage: sessionState.currentPage,
                    totalPages: book.pageCount ?? 0,
                    onPageChange: (page) {
                      ref.read(activeSessionProvider.notifier).updateCurrentPage(page);
                    },
                  ),
                ] else ...[
                  // Start page input or start button
                  if (_showStartPageInput)
                    _StartPageInput(
                      controller: _startPageController,
                      onSubmit: () {
                        final page = int.tryParse(_startPageController.text);
                        ref.read(activeSessionProvider.notifier).startSession(
                          widget.bookId,
                          startPage: page,
                        );
                      },
                      onSkip: () {
                        ref.read(activeSessionProvider.notifier).startSession(widget.bookId);
                      },
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Ready to read?',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StartButton(
                          onPressed: () {
                            setState(() => _showStartPageInput = true);
                          },
                        ),
                      ],
                    ),
                ],

                const Spacer(flex: 1),

                // Control buttons
                if (hasStarted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        // Stop button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                ref.read(activeSessionProvider.notifier).endSession();
                                if (context.mounted) Navigator.pop(context);
                              },
                              icon: const Icon(Icons.stop_rounded, size: 20),
                              label: Text(
                                'Stop',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.error,
                                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pause/Resume button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final notifier = ref.read(activeSessionProvider.notifier);
                                if (sessionState.isRunning) {
                                  notifier.pauseSession();
                                } else {
                                  notifier.resumeSession();
                                }
                              },
                              icon: Icon(
                                sessionState.isRunning
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 22,
                              ),
                              label: Text(
                                sessionState.isRunning ? 'Pause' : 'Resume',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final Duration elapsed;
  final bool isRunning;

  const _TimerDisplay({
    required this.elapsed,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          timeStr,
          style: GoogleFonts.outfit(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isRunning ? 80 : 40,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: isRunning ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _PageTracker extends StatelessWidget {
  final int? currentPage;
  final int totalPages;
  final void Function(int) onPageChange;

  const _PageTracker({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChange,
  });

  @override
  Widget build(BuildContext context) {
    final page = currentPage ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surfaceCard
            : Colors.grey.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Text(
            totalPages > 0
                ? 'Page $page of $totalPages'
                : 'Page $page',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageButton(
                icon: Icons.exposure_minus_1_rounded,
                onPressed: page > 0 ? () => onPageChange((page - 1).clamp(0, totalPages)) : null,
              ),
              const SizedBox(width: 8),
              _PageButton(
                icon: Icons.remove_rounded,
                onPressed: page > 0 ? () => onPageChange((page - 1).clamp(0, totalPages)) : null,
                small: true,
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
                child: Text(
                  page.toString(),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _PageButton(
                icon: Icons.add_rounded,
                onPressed: () => onPageChange(page + 1),
                small: true,
              ),
              const SizedBox(width: 8),
              _PageButton(
                icon: Icons.plus_one_rounded,
                onPressed: () => onPageChange(page + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool small;

  const _PageButton({
    required this.icon,
    this.onPressed,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 44.0;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: onPressed != null
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.05),
        ),
        child: Icon(
          icon,
          size: small ? 18 : 22,
          color: onPressed != null ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

class _StartPageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onSkip;

  const _StartPageInput({
    required this.controller,
    required this.onSubmit,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surfaceCard
            : Colors.grey.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Text(
            'What page are you on?',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Start Reading'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primary, AppTheme.primaryDark],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}


