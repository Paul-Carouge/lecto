// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recommendationsHash() => r'8b273d2eb269b9a3e5b6720a996e16035579656b';

/// Provides the list of non-dismissed recommendations from the database,
/// ordered by score (highest first).
///
/// Copied from [recommendations].
@ProviderFor(recommendations)
final recommendationsProvider = FutureProvider<List<Recommendation>>.internal(
  recommendations,
  name: r'recommendationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recommendationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecommendationsRef = FutureProviderRef<List<Recommendation>>;
String _$recommendationEngineHash() =>
    r'838cb2e69e59b50a0728e1c8fee9b1a4048e61a6';

/// Generates book recommendations by analyzing the user's finished books
/// (genres and authors) and fetching similar books via the Google Books API.
///
/// Strategy:
///   1. Collect the top genres from finished books.
///   2. Collect popular authors from finished books.
///   3. For each genre, fetch similar books via Google Books.
///   4. For each author, fetch more books by that author.
///   5. Score, deduplicate, and save the results.
///
/// Copied from [RecommendationEngine].
@ProviderFor(RecommendationEngine)
final recommendationEngineProvider =
    AsyncNotifierProvider<RecommendationEngine, List<Recommendation>>.internal(
      RecommendationEngine.new,
      name: r'recommendationEngineProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recommendationEngineHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecommendationEngine = AsyncNotifier<List<Recommendation>>;
String _$dismissRecommendationHash() =>
    r'8ee407d7f47d584f0c56d6548752254fd1cb7f74';

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

abstract class _$DismissRecommendation extends BuildlessAsyncNotifier<void> {
  late final String recommendationId;

  FutureOr<void> build(String recommendationId);
}

/// Marks a recommendation as dismissed in the database.
///
/// Copied from [DismissRecommendation].
@ProviderFor(DismissRecommendation)
const dismissRecommendationProvider = DismissRecommendationFamily();

/// Marks a recommendation as dismissed in the database.
///
/// Copied from [DismissRecommendation].
class DismissRecommendationFamily extends Family<AsyncValue<void>> {
  /// Marks a recommendation as dismissed in the database.
  ///
  /// Copied from [DismissRecommendation].
  const DismissRecommendationFamily();

  /// Marks a recommendation as dismissed in the database.
  ///
  /// Copied from [DismissRecommendation].
  DismissRecommendationProvider call(String recommendationId) {
    return DismissRecommendationProvider(recommendationId);
  }

  @override
  DismissRecommendationProvider getProviderOverride(
    covariant DismissRecommendationProvider provider,
  ) {
    return call(provider.recommendationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dismissRecommendationProvider';
}

/// Marks a recommendation as dismissed in the database.
///
/// Copied from [DismissRecommendation].
class DismissRecommendationProvider
    extends AsyncNotifierProviderImpl<DismissRecommendation, void> {
  /// Marks a recommendation as dismissed in the database.
  ///
  /// Copied from [DismissRecommendation].
  DismissRecommendationProvider(String recommendationId)
    : this._internal(
        () => DismissRecommendation()..recommendationId = recommendationId,
        from: dismissRecommendationProvider,
        name: r'dismissRecommendationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dismissRecommendationHash,
        dependencies: DismissRecommendationFamily._dependencies,
        allTransitiveDependencies:
            DismissRecommendationFamily._allTransitiveDependencies,
        recommendationId: recommendationId,
      );

  DismissRecommendationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recommendationId,
  }) : super.internal();

  final String recommendationId;

  @override
  FutureOr<void> runNotifierBuild(covariant DismissRecommendation notifier) {
    return notifier.build(recommendationId);
  }

  @override
  Override overrideWith(DismissRecommendation Function() create) {
    return ProviderOverride(
      origin: this,
      override: DismissRecommendationProvider._internal(
        () => create()..recommendationId = recommendationId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recommendationId: recommendationId,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<DismissRecommendation, void> createElement() {
    return _DismissRecommendationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DismissRecommendationProvider &&
        other.recommendationId == recommendationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, recommendationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DismissRecommendationRef on AsyncNotifierProviderRef<void> {
  /// The parameter `recommendationId` of this provider.
  String get recommendationId;
}

class _DismissRecommendationProviderElement
    extends AsyncNotifierProviderElement<DismissRecommendation, void>
    with DismissRecommendationRef {
  _DismissRecommendationProviderElement(super.provider);

  @override
  String get recommendationId =>
      (origin as DismissRecommendationProvider).recommendationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
