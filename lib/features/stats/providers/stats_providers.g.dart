// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bookshelfStatsHash() => r'd1005b4f646baf3c5b59d1fff9cadcf642ac38fa';

/// Provides aggregated bookshelf statistics.
///
/// Copied from [bookshelfStats].
@ProviderFor(bookshelfStats)
final bookshelfStatsProvider = FutureProvider<BookshelfStats>.internal(
  bookshelfStats,
  name: r'bookshelfStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bookshelfStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BookshelfStatsRef = FutureProviderRef<BookshelfStats>;
String _$monthlyStatsHash() => r'181a453af4bf7e83f7557e84b13f61fc8050a669';

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

/// Provides a map of month (1–12) to total pages read in that month
/// for the given [year].
///
/// Copied from [monthlyStats].
@ProviderFor(monthlyStats)
const monthlyStatsProvider = MonthlyStatsFamily();

/// Provides a map of month (1–12) to total pages read in that month
/// for the given [year].
///
/// Copied from [monthlyStats].
class MonthlyStatsFamily extends Family<AsyncValue<Map<int, int>>> {
  /// Provides a map of month (1–12) to total pages read in that month
  /// for the given [year].
  ///
  /// Copied from [monthlyStats].
  const MonthlyStatsFamily();

  /// Provides a map of month (1–12) to total pages read in that month
  /// for the given [year].
  ///
  /// Copied from [monthlyStats].
  MonthlyStatsProvider call(int year) {
    return MonthlyStatsProvider(year);
  }

  @override
  MonthlyStatsProvider getProviderOverride(
    covariant MonthlyStatsProvider provider,
  ) {
    return call(provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyStatsProvider';
}

/// Provides a map of month (1–12) to total pages read in that month
/// for the given [year].
///
/// Copied from [monthlyStats].
class MonthlyStatsProvider extends FutureProvider<Map<int, int>> {
  /// Provides a map of month (1–12) to total pages read in that month
  /// for the given [year].
  ///
  /// Copied from [monthlyStats].
  MonthlyStatsProvider(int year)
    : this._internal(
        (ref) => monthlyStats(ref as MonthlyStatsRef, year),
        from: monthlyStatsProvider,
        name: r'monthlyStatsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$monthlyStatsHash,
        dependencies: MonthlyStatsFamily._dependencies,
        allTransitiveDependencies:
            MonthlyStatsFamily._allTransitiveDependencies,
        year: year,
      );

  MonthlyStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<Map<int, int>> Function(MonthlyStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyStatsProvider._internal(
        (ref) => create(ref as MonthlyStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  FutureProviderElement<Map<int, int>> createElement() {
    return _MonthlyStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyStatsProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyStatsRef on FutureProviderRef<Map<int, int>> {
  /// The parameter `year` of this provider.
  int get year;
}

class _MonthlyStatsProviderElement extends FutureProviderElement<Map<int, int>>
    with MonthlyStatsRef {
  _MonthlyStatsProviderElement(super.provider);

  @override
  int get year => (origin as MonthlyStatsProvider).year;
}

String _$monthlyDurationHash() => r'9a49b6b656d7834d06872a0a986a435d9354cb51';

/// Provides a map of month (1–12) to total [Duration] spent reading
/// in that month for the given [year].
///
/// Copied from [monthlyDuration].
@ProviderFor(monthlyDuration)
const monthlyDurationProvider = MonthlyDurationFamily();

/// Provides a map of month (1–12) to total [Duration] spent reading
/// in that month for the given [year].
///
/// Copied from [monthlyDuration].
class MonthlyDurationFamily extends Family<AsyncValue<Map<int, int>>> {
  /// Provides a map of month (1–12) to total [Duration] spent reading
  /// in that month for the given [year].
  ///
  /// Copied from [monthlyDuration].
  const MonthlyDurationFamily();

  /// Provides a map of month (1–12) to total [Duration] spent reading
  /// in that month for the given [year].
  ///
  /// Copied from [monthlyDuration].
  MonthlyDurationProvider call(int year) {
    return MonthlyDurationProvider(year);
  }

  @override
  MonthlyDurationProvider getProviderOverride(
    covariant MonthlyDurationProvider provider,
  ) {
    return call(provider.year);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyDurationProvider';
}

/// Provides a map of month (1–12) to total [Duration] spent reading
/// in that month for the given [year].
///
/// Copied from [monthlyDuration].
class MonthlyDurationProvider extends FutureProvider<Map<int, int>> {
  /// Provides a map of month (1–12) to total [Duration] spent reading
  /// in that month for the given [year].
  ///
  /// Copied from [monthlyDuration].
  MonthlyDurationProvider(int year)
    : this._internal(
        (ref) => monthlyDuration(ref as MonthlyDurationRef, year),
        from: monthlyDurationProvider,
        name: r'monthlyDurationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$monthlyDurationHash,
        dependencies: MonthlyDurationFamily._dependencies,
        allTransitiveDependencies:
            MonthlyDurationFamily._allTransitiveDependencies,
        year: year,
      );

  MonthlyDurationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
  }) : super.internal();

  final int year;

  @override
  Override overrideWith(
    FutureOr<Map<int, int>> Function(MonthlyDurationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyDurationProvider._internal(
        (ref) => create(ref as MonthlyDurationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
      ),
    );
  }

  @override
  FutureProviderElement<Map<int, int>> createElement() {
    return _MonthlyDurationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyDurationProvider && other.year == year;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyDurationRef on FutureProviderRef<Map<int, int>> {
  /// The parameter `year` of this provider.
  int get year;
}

class _MonthlyDurationProviderElement
    extends FutureProviderElement<Map<int, int>>
    with MonthlyDurationRef {
  _MonthlyDurationProviderElement(super.provider);

  @override
  int get year => (origin as MonthlyDurationProvider).year;
}

String _$topGenresHash() => r'edc48c87a7850cebc0fae56923230c1e72a071c1';

/// Provides a map of genre/category to the number of finished books
/// in that genre. Sorted by count descending, limited to the top 5.
///
/// Copied from [topGenres].
@ProviderFor(topGenres)
final topGenresProvider = FutureProvider<Map<String, int>>.internal(
  topGenres,
  name: r'topGenresProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$topGenresHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TopGenresRef = FutureProviderRef<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
