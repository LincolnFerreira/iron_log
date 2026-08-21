// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_timer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$workoutTimerHash() => r'952dd72b7898a2c3331bc12c5404ffd95b5980ec';

/// Provider that manages the workout session timer
/// Stores the start timestamp and provides elapsed time calculation
///
/// Copied from [WorkoutTimer].
@ProviderFor(WorkoutTimer)
final workoutTimerProvider = NotifierProvider<WorkoutTimer, DateTime?>.internal(
  WorkoutTimer.new,
  name: r'workoutTimerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$workoutTimerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WorkoutTimer = Notifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
