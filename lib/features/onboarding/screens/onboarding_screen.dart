import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/theme/themes.dart';
import 'package:lecto/core/theme/theme_provider.dart';
import 'package:lecto/features/onboarding/providers/onboarding_providers.dart';

/// A full‑screen onboarding shown only once, on first launch.
///
/// Three slides:
///  1. "Bienvenue sur Lecto" – app logo + tagline
///  2. "Suivez vos lectures"   – feature highlights in a grid
///  3. "Prêt à lire ?"         – privacy note + "Commencer" button
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController(viewportFraction: 1.0);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.lightImpact();
    await ref.read(onboardingActionsProvider).markSeen();

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(themePaletteProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg =
        isDark ? palette.surfaceDark : palette.surfaceLight;
    final Color surface =
        isDark ? palette.surfaceCardDark : palette.surfaceCardLight;
    final Color onSurface =
        isDark ? palette.textOnDark : palette.textPrimary;
    final Color onSurfaceSecondary =
        isDark
            ? palette.textOnDark.withValues(alpha: 0.6)
            : palette.textSecondary;
    final Color primary = isDark ? palette.primaryLight : palette.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Top: Skip button ----------
            _buildTopBar(primary, onSurfaceSecondary),

            // ---------- Middle: PageView slides ----------
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: 3,
                itemBuilder: (context, index) => AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) =>
                      _buildSlideContent(
                        index,
                        palette,
                        primary,
                        surface,
                        onSurface,
                        onSurfaceSecondary,
                        isDark,
                      ),
                ),
              ),
            ),

            // ---------- Bottom: dots + next / start ----------
            _buildBottomBar(primary, onSurfaceSecondary),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(Color primary, Color onSurfaceSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < 2)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                );
              },
              child: Text(
                'Passer',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceSecondary,
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Slide content (with fade + scale animation)
  // ---------------------------------------------------------------------------

  Widget _buildSlideContent(
    int index,
    ThemePalette palette,
    Color primary,
    Color surface,
    Color onSurface,
    Color onSurfaceSecondary,
    bool isDark,
  ) {
    // fade + scale driven by PageView scroll position
    double value = _currentPage == index ? 1.0 : 0.0;
    if (_pageController.hasClients) {
      value = _pageController.page! - index;
      // value ∈ [-1, 1]; normalise to [0, 1]
      value = 1.0 - value.abs().clamp(0.0, 1.0);
    }

    return AnimatedOpacity(
      opacity: value,
      duration: const Duration(milliseconds: 300),
      child: Transform.scale(
        scale: 0.85 + (value * 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: switch (index) {
              0 => _SlideWelcome(
                  palette: palette,
                  primary: primary,
                  onSurface: onSurface,
                  onSurfaceSecondary: onSurfaceSecondary,
                  isDark: isDark,
                ),
              1 => _SlideFeatures(
                  primary: primary,
                  onSurface: onSurface,
                  onSurfaceSecondary: onSurfaceSecondary,
                  surface: surface,
                  isDark: isDark,
                ),
              2 => _SlideReady(
                  primary: primary,
                  onSurface: onSurface,
                  onSurfaceSecondary: onSurfaceSecondary,
                  onComplete: _completeOnboarding,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom bar – page dots + next / start button
  // ---------------------------------------------------------------------------

  Widget _buildBottomBar(Color primary, Color secondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isActive ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive ? primary : primary.withValues(alpha: 0.25),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Next / Start button
        if (_currentPage < 2)
          _buildNextButton(primary)
        else
          _buildStartButton(primary),
      ],
    );
  }

  Widget _buildNextButton(Color primary) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: primary,
        borderRadius: BorderRadius.circular(28),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _goToNextPage,
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(Color primary) {
    return SizedBox(
      width: 220,
      height: 54,
      child: ElevatedButton(
        onPressed: _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        child: const Text('Commencer'),
      ),
    );
  }
}

// =============================================================================
// Slide 1 : Bienvenue
// =============================================================================

class _SlideWelcome extends StatelessWidget {
  const _SlideWelcome({
    required this.palette,
    required this.primary,
    required this.onSurface,
    required this.onSurfaceSecondary,
    required this.isDark,
  });

  final ThemePalette palette;
  final Color primary;
  final Color onSurface;
  final Color onSurfaceSecondary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App icon / logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.primary, palette.primaryLight],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'L',
              style: GoogleFonts.outfit(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Title
        Text(
          'Bienvenue sur Lecto',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 16),

        // Tagline
        Text(
          'Votre carnet de lecture personnel',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: onSurfaceSecondary,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 48),

        // Subtle description
        Text(
          'Suivez chaque livre, chaque minute de lecture,\net découvrez vos habitudes de lecteur.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: onSurfaceSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Slide 2 : Fonctionnalités
// =============================================================================

class _SlideFeatures extends StatelessWidget {
  const _SlideFeatures({
    required this.primary,
    required this.onSurface,
    required this.onSurfaceSecondary,
    required this.surface,
    required this.isDark,
  });

  final Color primary;
  final Color onSurface;
  final Color onSurfaceSecondary;
  final Color surface;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Suivez vos lectures',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Tout ce dont vous avez besoin pour\ngérer votre vie de lecteur',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: onSurfaceSecondary,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 36),

        // Feature grid (2×2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: const [
              _FeatureCard(
                icon: Icons.timer_outlined,
                title: 'Minuteur',
                description: 'Chronomètrez vos\nsessions de lecture',
              ),
              _FeatureCard(
                icon: Icons.bar_chart_rounded,
                title: 'Statistiques',
                description: 'Visualisez votre\nprogression',
              ),
              _FeatureCard(
                icon: Icons.flag_rounded,
                title: 'Objectifs',
                description: 'Fixez-vous des\ndéfis de lecture',
              ),
              _FeatureCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Recommandations',
                description: 'Découvrez vos\nprochains livres',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = ThemePalette.fromOption(
      isDark ? AppThemeOption.terracotta : AppThemeOption.terracotta,
    );
    final Color primary = isDark ? palette.primaryLight : palette.primary;
    final Color cardBg =
        isDark ? palette.surfaceCardDark : palette.surfaceCardLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? palette.textOnDark : palette.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color:
                  isDark
                      ? palette.textOnDark.withValues(alpha: 0.6)
                      : palette.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Slide 3 : Prêt à lire ?
// =============================================================================

class _SlideReady extends StatelessWidget {
  const _SlideReady({
    required this.primary,
    required this.onSurface,
    required this.onSurfaceSecondary,
    required this.onComplete,
  });

  final Color primary;
  final Color onSurface;
  final Color onSurfaceSecondary;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: primary,
            size: 48,
          ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          'Prêt à lire ?',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: onSurface,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 16),

        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Lecto fonctionne hors ligne.\nVos données de lecture restent sur votre appareil\net ne sont jamais partagées.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: onSurfaceSecondary,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Privacy badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                '100 % privé & hors ligne',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
