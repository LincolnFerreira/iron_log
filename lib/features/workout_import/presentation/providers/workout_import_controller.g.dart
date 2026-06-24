// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_import_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workoutImportControllerHash() =>
    r'017ccc406c0223af6aca86d6fa5da06b02d53321';

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

abstract class _$WorkoutImportController
    extends BuildlessAutoDisposeAsyncNotifier<WorkoutImportReviewState?> {
  late final String draftId;

  FutureOr<WorkoutImportReviewState?> build(String draftId);
}

/// See also [WorkoutImportController].
@ProviderFor(WorkoutImportController)
const workoutImportControllerProvider = WorkoutImportControllerFamily();

/// See also [WorkoutImportController].
class WorkoutImportControllerFamily
    extends Family<AsyncValue<WorkoutImportReviewState?>> {
  /// See also [WorkoutImportController].
  const WorkoutImportControllerFamily();

  /// See also [WorkoutImportController].
  WorkoutImportControllerProvider call(String draftId) {
    return WorkoutImportControllerProvider(draftId);
  }

  @override
  WorkoutImportControllerProvider getProviderOverride(
    covariant WorkoutImportControllerProvider provider,
  ) {
    return call(provider.draftId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'workoutImportControllerProvider';
}

/// See also [WorkoutImportController].
class WorkoutImportControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          WorkoutImportController,
          WorkoutImportReviewState?
        > {
  /// See also [WorkoutImportController].
  WorkoutImportControllerProvider(String draftId)
    : this._internal(
        () => WorkoutImportController()..draftId = draftId,
        from: workoutImportControllerProvider,
        name: r'workoutImportControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$workoutImportControllerHash,
        dependencies: WorkoutImportControllerFamily._dependencies,
        allTransitiveDependencies:
            WorkoutImportControllerFamily._allTransitiveDependencies,
        draftId: draftId,
      );

  WorkoutImportControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.draftId,
  }) : super.internal();

  final String draftId;

  @override
  FutureOr<WorkoutImportReviewState?> runNotifierBuild(
    covariant WorkoutImportController notifier,
  ) {
    return notifier.build(draftId);
  }

  @override
  Override overrideWith(WorkoutImportController Function() create) {
    return ProviderOverride(
      origin: this,
      override: WorkoutImportControllerProvider._internal(
        () => create()..draftId = draftId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        draftId: draftId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    WorkoutImportController,
    WorkoutImportReviewState?
  >
  createElement() {
    return _WorkoutImportControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutImportControllerProvider && other.draftId == draftId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, draftId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WorkoutImportControllerRef
    on AutoDisposeAsyncNotifierProviderRef<WorkoutImportReviewState?> {
  /// The parameter `draftId` of this provider.
  String get draftId;
}

class _WorkoutImportControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          WorkoutImportController,
          WorkoutImportReviewState?
        >
    with WorkoutImportControllerRef {
  _WorkoutImportControllerProviderElement(super.provider);

  @override
  String get draftId => (origin as WorkoutImportControllerProvider).draftId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
