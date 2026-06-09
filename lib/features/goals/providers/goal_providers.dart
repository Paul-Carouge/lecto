import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lecto/core/database/database.dart';
import 'package:lecto/core/database/providers.dart';

part 'goal_providers.g.dart';

// ============================================================
// All goals
// ============================================================

/// Provides the list of all reading goals from the database.
@Riverpod(keepAlive: true)
Future<List<ReadingGoal>> goals(GoalsRef ref) async {
  final db = ref.watch(databaseProvider);
  return db.getGoals();
}

// ============================================================
// Current goal progress
// ============================================================

/// Computes the progress toward the current month's or year's goal.
///
/// If [month] is provided, looks for a monthly goal for that month and year.
/// If [month] is null, looks for a yearly goal for [year].
/// Returns a map with:
///   - `goal`: the [ReadingGoal] (or null if no goal exists)
///   - `target`: the target value
///   - `progress`: the current progress
///   - `percentage`: the completion percentage (0.0–1.0)
///   - `remaining`: what's left to reach the target
class GoalProgress {
  final ReadingGoal? goal;
  final int target;
  final int progress;
  final double percentage;
  final int remaining;

  const GoalProgress({
    this.goal,
    this.target = 0,
    this.progress = 0,
    this.percentage = 0.0,
    this.remaining = 0,
  });

  /// Whether the goal exists.
  bool get hasGoal => goal != null;

  /// Whether the goal has been completed.
  bool get isComplete => percentage >= 1.0;
}

/// Provides the current goal progress for a given [year] and optional [month].
@Riverpod(keepAlive: true)
Future<GoalProgress> currentGoalProgress(CurrentGoalProgressRef ref, int year, {int? month}) async {
  final db = ref.watch(databaseProvider);
  final goals = db.getGoals(year: year, month: month);

  if (goals.isEmpty) {
    return const GoalProgress();
  }

  // Use the first matching goal (there should typically be one per period)
  final goal = goals.first;
  final progress = goal.progress;
  final target = goal.target;
  final percentage = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
  final remaining = target > progress ? target - progress : 0;

  return GoalProgress(
    goal: goal,
    target: target,
    progress: progress,
    percentage: percentage,
    remaining: remaining,
  );
}

// ============================================================
// Set a new goal
// ============================================================

/// Creates a new reading goal and saves it to the database.
///
/// Parameters (via the provider family argument):
///   - `type`: one of 'books', 'pages', 'minutes'
///   - `target`: the target number
///   - `year`: the target year
///   - `month`: optional month (null = yearly goal)
@Riverpod(keepAlive: true)
class SetGoal extends _$SetGoal {
  @override
  Future<ReadingGoal> build(Map<String, dynamic> params) {
    throw UnimplementedError('Use ref.read(setGoalProvider.notifier).setGoal(...)');
  }

  /// Creates and saves a new goal to the database.
  /// The type, target, year, and month are read from the provider family params.
  Future<ReadingGoal> setGoal() async {
    final db = ref.read(databaseProvider);
    final type = params['type'] as String;
    final target = params['target'] as int;
    final year = params['year'] as int;
    final month = params['month'] as int?;
    final goal = db.setGoal(ReadingGoal(
      id: '',
      year: year,
      month: month,
      type: type,
      target: target,
      progress: 0,
    ));

    ref.invalidate(goalsProvider);
    ref.invalidate(currentGoalProgressProvider);

    return goal;
  }
}

// ============================================================
// Update goal progress
// ============================================================

/// Updates the progress value for an existing goal.
@Riverpod(keepAlive: true)
class UpdateGoalProgress extends _$UpdateGoalProgress {
  @override
  Future<void> build(String goalId, int progress) {
    throw UnimplementedError('Use ref.read(updateGoalProgressProvider(goalId, progress).notifier).applyUpdate()');
  }

  /// Persists the new progress value and invalidates dependent providers.
  Future<void> applyUpdate() async {
    final db = ref.read(databaseProvider);
    final goalId = this.goalId;
    final progress = this.progress;
    db.updateGoalProgress(goalId, progress);

    ref.invalidate(goalsProvider);
    ref.invalidate(currentGoalProgressProvider);
  }
}
