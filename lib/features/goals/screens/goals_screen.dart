import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lecto/core/theme/app_theme.dart';
import 'package:lecto/core/database/providers.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/utils/formatters.dart';
import 'package:lecto/features/goals/providers/goal_providers.dart';
import 'package:lecto/shared/widgets/empty_state.dart';

/// Goal setting and tracking screen.
///
/// Shows:
///   - Current goals display with circular progress
///   - "Add Goal" button
///   - Options: yearly books target, monthly pages target, yearly minutes target
///   - Progress bars
///   - Goal completion celebration
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _celebrationController;
  bool _showAddDialog = false;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    _celebrationController.forward().then((_) {
      _celebrationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final goalsAsync = ref.watch(goalsProvider);
    final yearlyBooksProgress = ref.watch(
      currentGoalProgressProvider(year),
    );
    final monthlyPagesProgress = ref.watch(
      currentGoalProgressProvider(year, month: month),
    );
    final yearlyMinutesProgress = ref.watch(
      currentGoalProgressProvider(year),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reading Goals',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (goals) {
          if (goals.isEmpty && !_showAddDialog) {
            return Center(
              child: EmptyState(
                emoji: '🎯',
                title: 'No goals set yet',
                subtitle: 'Set a reading goal to stay motivated!',
                actionLabel: 'Set a Goal',
                onAction: () => setState(() => _showAddDialog = true),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Formatters.formatMonthYear(month, year)}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),

                // Goals list
                ...goals.map((goal) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _GoalCard(
                        goal: goal,
                        onDelete: () => _deleteGoal(goal.id),
                        onCelebrate: goal.progress >= goal.target
                            ? _triggerCelebration
                            : null,
                      ),
                    )),

                if (goals.isEmpty && _showAddDialog) _buildAddForm(year, month),

                if (goals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _showAddDialog = true),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Goal'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ],

                // Celebration overlay
                if (_celebrationController.isAnimating)
                  _CelebrationOverlay(controller: _celebrationController),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddForm(int year, int month) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.surfaceCard
            : Colors.grey.withValues(alpha: 0.04),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'New Goal',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showAddDialog = false),
                child: Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GoalOptionTile(
            icon: Icons.menu_book_rounded,
            title: 'Yearly Books Target',
            subtitle: 'Set how many books you want to read this year',
            onTap: () => _showGoalInput('books', 'Yearly Books Goal', year: year),
          ),
          const Divider(height: 24),
          _GoalOptionTile(
            icon: Icons.auto_stories_rounded,
            title: 'Monthly Pages Target',
            subtitle: 'Set a pages-per-month goal',
            onTap: () => _showGoalInput('pages', 'Monthly Pages Goal', year: year, month: month),
          ),
          const Divider(height: 24),
          _GoalOptionTile(
            icon: Icons.schedule_rounded,
            title: 'Yearly Minutes Target',
            subtitle: 'Set total reading minutes for the year',
            onTap: () => _showGoalInput('minutes', 'Yearly Minutes Goal', year: year),
          ),
        ],
      ),
    );
  }

  void _showGoalInput(String type, String title, {required int year, int? month}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter target value...',
            suffixText: type == 'books'
                ? 'books'
                : type == 'pages'
                    ? 'pages'
                    : 'minutes',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final target = int.tryParse(controller.text);
              if (target == null || target <= 0) return;
              Navigator.pop(ctx);
              await ref.read(setGoalProvider({
                    'type': type,
                    'target': target,
                    'year': year,
                    'month': month,
                  }).notifier).setGoal();
              setState(() => _showAddDialog = false);
            },
            child: const Text('Set Goal'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(String id) async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    db.deleteGoal(id);
    ref.invalidate(goalsProvider);
    ref.invalidate(currentGoalProgressProvider(now.year));
  }
}

class _GoalCard extends StatelessWidget {
  final ReadingGoal goal;
  final VoidCallback onDelete;
  final VoidCallback? onCelebrate;

  const _GoalCard({
    required this.goal,
    required this.onDelete,
    this.onCelebrate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isComplete = goal.progress >= goal.target;
    final percentage = goal.target > 0
        ? (goal.progress / goal.target).clamp(0.0, 1.0)
        : 0.0;
    final (icon, label, unit) = switch (goal.type) {
      'books' => (Icons.menu_book_rounded, 'Books', ' books'),
      'pages' => (Icons.auto_stories_rounded, 'Pages', ' pages'),
      'minutes' => (Icons.schedule_rounded, 'Minutes', ' min'),
      _ => (Icons.flag_rounded, 'Goal', ''),
    };

    final goalName = goal.month != null
        ? 'Monthly ${goal.type}'
        : 'Yearly ${goal.type}';

    return Container(
      padding: const EdgeInsets.all(20),
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
          // Circular progress
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 6,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? AppTheme.success : AppTheme.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(percentage * 100).round()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isComplete ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      goalName,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${goal.progress} of ${goal.target}$unit',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (isComplete)
                  Row(
                    children: [
                      Icon(Icons.celebration_rounded, size: 16, color: AppTheme.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Goal completed! 🎉',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Delete
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.error.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.delete_rounded, size: 18, color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GoalOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CelebrationOverlay extends AnimatedWidget {
  final AnimationController controller;

  const _CelebrationOverlay({required this.controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: 1.0 - controller.value,
            child: Transform.scale(
              scale: 1.0 + controller.value * 0.5,
              child: Text(
                '🎉',
                style: TextStyle(fontSize: 80 + controller.value * 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
