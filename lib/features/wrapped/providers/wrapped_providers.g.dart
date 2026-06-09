// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrapped_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$monthlyWrappedHash() => r'7c8abc8ad49c2612705756a13b70e5f70eb420a8';

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

/// Provides all data needed for the monthly "wrapped" view for a given
/// [month] and [year].
///
/// Copied from [monthlyWrapped].
@ProviderFor(monthlyWrapped)
const monthlyWrappedProvider = MonthlyWrappedFamily();

/// Provides all data needed for the monthly "wrapped" view for a given
/// [month] and [year].
///
/// Copied from [monthlyWrapped].
class MonthlyWrappedFamily extends Family<AsyncValue<MonthlyWrapped>> {
  /// Provides all data needed for the monthly "wrapped" view for a given
  /// [month] and [year].
  ///
  /// Copied from [monthlyWrapped].
  const MonthlyWrappedFamily();

  /// Provides all data needed for the monthly "wrapped" view for a given
  /// [month] and [year].
  ///
  /// Copied from [monthlyWrapped].
  MonthlyWrappedProvider call(int month, int year) {
    return MonthlyWrappedProvider(month, year);
  }

  @override
  MonthlyWrappedProvider getProviderOverride(
    covariant MonthlyWrappedProvider provider,
  ) {
    return call(provider.month, provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyWrappedProvider';
}

/// Provides all data needed for the monthly "wrapped" view for a given
/// [month] and [year].
///
/// Copied from [monthlyWrapped].
class MonthlyWrappedProvider extends FutureProvider<MonthlyWrapped> {
  /// Provides all data needed for the monthly "wrapped" view for a given
  /// [month] and [year].
  ///
  /// Copied from [monthlyWrapped].
  MonthlyWrappedProvider(int month, int year)
    : this._internal(
        (ref) => monthlyWrapped(ref as MonthlyWrappedRef, month, year),
        from: monthlyWrappedProvider,
        name: r'monthlyWrappedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$monthlyWrappedHash,
        dependencies: MonthlyWrappedFamily._dependencies,
        allTransitiveDependencies:
            MonthlyWrappedFamily._allTransitiveDependencies,
        month: month,
        year: year,
      );

  MonthlyWrappedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
    required this.year,
  }) : super.internal();

  final int month;
  final int year;

  @override
  Override overrideWith(
    FutureOr<MonthlyWrapped> Function(MonthlyWrappedRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyWrappedProvider._internal(
        (ref) => create(ref as MonthlyWrappedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
        year: year,
      ),
    );
  }

  @override
  FutureProviderElement<MonthlyWrapped> createElement() {
    return _MonthlyWrappedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyWrappedProvider &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyWrappedRef on FutureProviderRef<MonthlyWrapped> {
  /// The parameter `month` of this provider.
  int get month;

  /// The parameter `year` of this provider.
  int get year;
}

class _MonthlyWrappedProviderElement
    extends FutureProviderElement<MonthlyWrapped>
    with MonthlyWrappedRef {
  _MonthlyWrappedProviderElement(super.provider);

  @override
  int get month => (origin as MonthlyWrappedProvider).month;
  @override
  int get year => (origin as MonthlyWrappedProvider).year;
}

String _$generateWrappedHash() => r'f9707e9afb2006e90c301e419e01b472ce2c8ffb';

abstract class _$GenerateWrapped
    extends BuildlessAsyncNotifier<MonthlyWrapped> {
  late final int month;
  late final int year;

  FutureOr<MonthlyWrapped> build(int month, int year);
}

/// Generates a monthly wrapped snapshot and stores it.
///
/// This can be used to "freeze" a wrapped view at a point in time,
/// or to trigger a regeneration.
///
/// Copied from [GenerateWrapped].
@ProviderFor(GenerateWrapped)
const generateWrappedProvider = GenerateWrappedFamily();

/// Generates a monthly wrapped snapshot and stores it.
///
/// This can be used to "freeze" a wrapped view at a point in time,
/// or to trigger a regeneration.
///
/// Copied from [GenerateWrapped].
class GenerateWrappedFamily extends Family<AsyncValue<MonthlyWrapped>> {
  /// Generates a monthly wrapped snapshot and stores it.
  ///
  /// This can be used to "freeze" a wrapped view at a point in time,
  /// or to trigger a regeneration.
  ///
  /// Copied from [GenerateWrapped].
  const GenerateWrappedFamily();

  /// Generates a monthly wrapped snapshot and stores it.
  ///
  /// This can be used to "freeze" a wrapped view at a point in time,
  /// or to trigger a regeneration.
  ///
  /// Copied from [GenerateWrapped].
  GenerateWrappedProvider call(int month, int year) {
    return GenerateWrappedProvider(month, year);
  }

  @override
  GenerateWrappedProvider getProviderOverride(
    covariant GenerateWrappedProvider provider,
  ) {
    return call(provider.month, provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'generateWrappedProvider';
}

/// Generates a monthly wrapped snapshot and stores it.
///
/// This can be used to "freeze" a wrapped view at a point in time,
/// or to trigger a regeneration.
///
/// Copied from [GenerateWrapped].
class GenerateWrappedProvider
    extends AsyncNotifierProviderImpl<GenerateWrapped, MonthlyWrapped> {
  /// Generates a monthly wrapped snapshot and stores it.
  ///
  /// This can be used to "freeze" a wrapped view at a point in time,
  /// or to trigger a regeneration.
  ///
  /// Copied from [GenerateWrapped].
  GenerateWrappedProvider(int month, int year)
    : this._internal(
        () => GenerateWrapped()
          ..month = month
          ..year = year,
        from: generateWrappedProvider,
        name: r'generateWrappedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$generateWrappedHash,
        dependencies: GenerateWrappedFamily._dependencies,
        allTransitiveDependencies:
            GenerateWrappedFamily._allTransitiveDependencies,
        month: month,
        year: year,
      );

  GenerateWrappedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.month,
    required this.year,
  }) : super.internal();

  final int month;
  final int year;

  @override
  FutureOr<MonthlyWrapped> runNotifierBuild(
    covariant GenerateWrapped notifier,
  ) {
    return notifier.build(month, year);
  }

  @override
  Override overrideWith(GenerateWrapped Function() create) {
    return ProviderOverride(
      origin: this,
      override: GenerateWrappedProvider._internal(
        () => create()
          ..month = month
          ..year = year,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        month: month,
        year: year,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<GenerateWrapped, MonthlyWrapped>
  createElement() {
    return _GenerateWrappedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GenerateWrappedProvider &&
        other.month == month &&
        other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GenerateWrappedRef on AsyncNotifierProviderRef<MonthlyWrapped> {
  /// The parameter `month` of this provider.
  int get month;

  /// The parameter `year` of this provider.
  int get year;
}

class _GenerateWrappedProviderElement
    extends AsyncNotifierProviderElement<GenerateWrapped, MonthlyWrapped>
    with GenerateWrappedRef {
  _GenerateWrappedProviderElement(super.provider);

  @override
  int get month => (origin as GenerateWrappedProvider).month;
  @override
  int get year => (origin as GenerateWrappedProvider).year;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
