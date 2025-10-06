import 'package:equatable/equatable.dart';
import 'package:iron_log/features/onboarding/model/division_type.dart';

class DivisionSetupState extends Equatable {
  final int? selectedMethod;
  final DivisionType? selectedDivision;
  final int frequency;

  const DivisionSetupState({
    this.selectedMethod,
    this.selectedDivision,
    this.frequency = 1,
  });

  bool get canContinueMethod => selectedMethod != null;
  bool get canContinueDivision => selectedDivision != null;

  DivisionSetupState copyWith({
    int? selectedMethod,
    DivisionType? selectedDivision,
    int? frequency,
  }) {
    return DivisionSetupState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      selectedDivision: selectedDivision ?? this.selectedDivision,
      frequency: frequency ?? this.frequency,
    );
  }

  @override
  List<Object?> get props => [selectedMethod, selectedDivision, frequency];
}
