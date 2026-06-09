// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$goalsHash() => r'0c0a18e435bb15a66a0e0a7a656c90e755a5e559';

/// Provides the list of all reading goals from the database.
///
/// Copied from [goals].
@ProviderFor(goals)
final goalsProvider = FutureProvider<List<ReadingGoal>>.internal(
  goals,
  name: r'goalsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$goalsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoalsRef = FutureProviderRef<List<ReadingGoal>>;
String _$currentGoalProgressHash() =>
    r'f4ab299b6a2151ea0f5787eb5ec74df5dd8d3860';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Provides the current goal progress for a given [year] and optional [month].
///
/// Copied from [currentGoalProgress].
@ProviderFor(currentGoalProgress)
const currentGoalProgressProvider = CurrentGoalProgressFamily();

/// Provides the current goal progress for a given [year] and optional [month].
///
/// Copied from [currentGoalProgress].
class CurrentGoalProgressFamily extends Family<AsyncValue<GoalProgress>> {
  /// Provides the current goal progress for a given [year] and optional [month].
  ///
  /// Copied from [currentGoalProgress].
  const CurrentGoalProgressFamily();

  /// Provides the current goal progress for a given [year] and optional [month].
  ///
  /// Copied from [currentGoalProgress].
  CurrentGoalProgressProvider call(int year, {int? month}) {
    return CurrentGoalProgressProvider(year, month: month);
  }

  @override
  CurrentGoalProgressProvider getProviderOverride(
    covariant CurrentGoalProgressProvider provider,
  ) {
    return call(provider.year, month: provider.month);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'currentGoalProgressProvider';
}

/// Provides the current goal progress for a given [year] and optional [month].
///
/// Copied from [currentGoalProgress].
class CurrentGoalProgressProvider extends FutureProvider<GoalProgress> {
  /// Provides the current goal progress for a given [year] and optional [month].
  ///
  /// Copied from [currentGoalProgress].
  CurrentGoalProgressProvider(int year, {int? month})
    : this._internal(
        (ref) => currentGoalProgress(
          ref as CurrentGoalProgressRef,
          year,
          month: month,
        ),
        from: currentGoalProgressProvider,
        name: r'currentGoalProgressProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$currentGoalProgressHash,
        dependencies: CurrentGoalProgressFamily._dependencies,
        allTransitiveDependencies:
            CurrentGoalProgressFamily._allTransitiveDependencies,
        year: year,
        month: month,
      );

  CurrentGoalProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int year;
  final int? month;

  @override
  Override overrideWith(
    FutureOr<GoalProgress> Function(CurrentGoalProgressRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CurrentGoalProgressProvider._internal(
        (ref) => create(ref as CurrentGoalProgressRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  FutureProviderElement<GoalProgress> createElement() {
    return _CurrentGoalProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentGoalProgressProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CurrentGoalProgressRef on FutureProviderRef<GoalProgress> {
  /// The parameter `year` of this provider.
  int get year;

  /// The parameter `month` of this provider.
  int? get month;
}

class _CurrentGoalProgressProviderElement
    extends FutureProviderElement<GoalProgress>
    with CurrentGoalProgressRef {
  _CurrentGoalProgressProviderElement(super.provider);

  @override
  int get year => (origin as CurrentGoalProgressProvider).year;
  @override
  int? get month => (origin as CurrentGoalProgressProvider).month;
}

String _$setGoalHash() => r'96d1579a1c18e94859ae03b9735a39411dcc0404';

abstract class _$SetGoal extends BuildlessAsyncNotifier<ReadingGoal> {
  late final Map<String, dynamic> params;

  FutureOr<ReadingGoal> build(Map<String, dynamic> params);
}

/// Creates a new reading goal and saves it to the database.
///
/// Parameters (via the provider family argument):
///   - `type`: one of 'books', 'pages', 'minutes'
///   - `target`: the target number
///   - `year`: the target year
///   - `month`: optional month (null = yearly goal)
///
/// Copied from [SetGoal].
@ProviderFor(SetGoal)
const setGoalProvider = SetGoalFamily();

/// Creates a new reading goal and saves it to the database.
///
/// Parameters (via the provider family argument):
///   - `type`: one of 'books', 'pages', 'minutes'
///   - `target`: the target number
///   - `year`: the target year
///   - `month`: optional month (null = yearly goal)
///
/// Copied from [SetGoal].
class SetGoalFamily extends Family<AsyncValue<ReadingGoal>> {
  /// Creates a new reading goal and saves it to the database.
  ///
  /// Parameters (via the provider family argument):
  ///   - `type`: one of 'books', 'pages', 'minutes'
  ///   - `target`: the target number
  ///   - `year`: the target year
  ///   - `month`: optional month (null = yearly goal)
  ///
  /// Copied from [SetGoal].
  const SetGoalFamily();

  /// Creates a new reading goal and saves it to the database.
  ///
  /// Parameters (via the provider family argument):
  ///   - `type`: one of 'books', 'pages', 'minutes'
  ///   - `target`: the target number
  ///   - `year`: the target year
  ///   - `month`: optional month (null = yearly goal)
  ///
  /// Copied from [SetGoal].
  SetGoalProvider call(Map<String, dynamic> params) {
    return SetGoalProvider(params);
  }

  @override
  SetGoalProvider getProviderOverride(covariant SetGoalProvider provider) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'setGoalProvider';
}

/// Creates a new reading goal and saves it to the database.
///
/// Parameters (via the provider family argument):
///   - `type`: one of 'books', 'pages', 'minutes'
///   - `target`: the target number
///   - `year`: the target year
///   - `month`: optional month (null = yearly goal)
///
/// Copied from [SetGoal].
class SetGoalProvider extends AsyncNotifierProviderImpl<SetGoal, ReadingGoal> {
  /// Creates a new reading goal and saves it to the database.
  ///
  /// Parameters (via the provider family argument):
  ///   - `type`: one of 'books', 'pages', 'minutes'
  ///   - `target`: the target number
  ///   - `year`: the target year
  ///   - `month`: optional month (null = yearly goal)
  ///
  /// Copied from [SetGoal].
  SetGoalProvider(Map<String, dynamic> params)
    : this._internal(
        () => SetGoal()..params = params,
        from: setGoalProvider,
        name: r'setGoalProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$setGoalHash,
        dependencies: SetGoalFamily._dependencies,
        allTransitiveDependencies: SetGoalFamily._allTransitiveDependencies,
        params: params,
      );

  SetGoalProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final Map<String, dynamic> params;

  @override
  FutureOr<ReadingGoal> runNotifierBuild(covariant SetGoal notifier) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(SetGoal Function() create) {
    return ProviderOverride(
      origin: this,
      override: SetGoalProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<SetGoal, ReadingGoal> createElement() {
    return _SetGoalProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SetGoalProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SetGoalRef on AsyncNotifierProviderRef<ReadingGoal> {
  /// The parameter `params` of this provider.
  Map<String, dynamic> get params;
}

class _SetGoalProviderElement
    extends AsyncNotifierProviderElement<SetGoal, ReadingGoal>
    with SetGoalRef {
  _SetGoalProviderElement(super.provider);

  @override
  Map<String, dynamic> get params => (origin as SetGoalProvider).params;
}

String _$updateGoalProgressHash() =>
    r'c3bcc373705511d91608e9c92404fd1caf6674b4';

abstract class _$UpdateGoalProgress extends BuildlessAsyncNotifier<void> {
  late final String goalId;
  late final int progress;

  FutureOr<void> build(String goalId, int progress);
}

/// Updates the progress value for an existing goal.
///
/// Copied from [UpdateGoalProgress].
@ProviderFor(UpdateGoalProgress)
const updateGoalProgressProvider = UpdateGoalProgressFamily();

/// Updates the progress value for an existing goal.
///
/// Copied from [UpdateGoalProgress].
class UpdateGoalProgressFamily extends Family<AsyncValue<void>> {
  /// Updates the progress value for an existing goal.
  ///
  /// Copied from [UpdateGoalProgress].
  const UpdateGoalProgressFamily();

  /// Updates the progress value for an existing goal.
  ///
  /// Copied from [UpdateGoalProgress].
  UpdateGoalProgressProvider call(String goalId, int progress) {
    return UpdateGoalProgressProvider(goalId, progress);
  }

  @override
  UpdateGoalProgressProvider getProviderOverride(
    covariant UpdateGoalProgressProvider provider,
  ) {
    return call(provider.goalId, provider.progress);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'updateGoalProgressProvider';
}

/// Updates the progress value for an existing goal.
///
/// Copied from [UpdateGoalProgress].
class UpdateGoalProgressProvider
    extends AsyncNotifierProviderImpl<UpdateGoalProgress, void> {
  /// Updates the progress value for an existing goal.
  ///
  /// Copied from [UpdateGoalProgress].
  UpdateGoalProgressProvider(String goalId, int progress)
    : this._internal(
        () => UpdateGoalProgress()
          ..goalId = goalId
          ..progress = progress,
        from: updateGoalProgressProvider,
        name: r'updateGoalProgressProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$updateGoalProgressHash,
        dependencies: UpdateGoalProgressFamily._dependencies,
        allTransitiveDependencies:
            UpdateGoalProgressFamily._allTransitiveDependencies,
        goalId: goalId,
        progress: progress,
      );

  UpdateGoalProgressProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.goalId,
    required this.progress,
  }) : super.internal();

  final String goalId;
  final int progress;

  @override
  FutureOr<void> runNotifierBuild(covariant UpdateGoalProgress notifier) {
    return notifier.build(goalId, progress);
  }

  @override
  Override overrideWith(UpdateGoalProgress Function() create) {
    return ProviderOverride(
      origin: this,
      override: UpdateGoalProgressProvider._internal(
        () => create()
          ..goalId = goalId
          ..progress = progress,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        goalId: goalId,
        progress: progress,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<UpdateGoalProgress, void> createElement() {
    return _UpdateGoalProgressProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateGoalProgressProvider &&
        other.goalId == goalId &&
        other.progress == progress;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, goalId.hashCode);
    hash = _SystemHash.combine(hash, progress.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateGoalProgressRef on AsyncNotifierProviderRef<void> {
  /// The parameter `goalId` of this provider.
  String get goalId;

  /// The parameter `progress` of this provider.
  int get progress;
}

class _UpdateGoalProgressProviderElement
    extends AsyncNotifierProviderElement<UpdateGoalProgress, void>
    with UpdateGoalProgressRef {
  _UpdateGoalProgressProviderElement(super.provider);

  @override
  String get goalId => (origin as UpdateGoalProgressProvider).goalId;
  @override
  int get progress => (origin as UpdateGoalProgressProvider).progress;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
