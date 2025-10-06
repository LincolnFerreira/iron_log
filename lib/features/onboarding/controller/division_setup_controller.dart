// features/onboarding/controller/division_setup_controller.dart
import 'package:iron_log/features/onboarding/controller/division_setup_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:iron_log/features/onboarding/model/division_type.dart';

part 'division_setup_controller.g.dart';

@riverpod
class DivisionSetupController extends _$DivisionSetupController {
  @override
  DivisionSetupState build() {
    return const DivisionSetupState();
  }

  void selectMethod(int? method) {
    state = state.copyWith(selectedMethod: method);
  }

  void selectDivision(DivisionType type) {
    state = state.copyWith(selectedDivision: type);
  }

  void setFrequency(int value) {
    state = state.copyWith(frequency: value);
  }

  void reset() {
    state = const DivisionSetupState();
  }
}
