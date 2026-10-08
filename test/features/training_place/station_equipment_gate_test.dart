import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/training_place/domain/station_equipment_gate.dart';

void main() {
  test('máquina, cabo e smith pedem estação', () {
    expect(stationEquipmentRequiresStation('Máquina'), isTrue);
    expect(stationEquipmentRequiresStation('maquina'), isTrue);
    expect(stationEquipmentRequiresStation('Cabo'), isTrue);
    expect(stationEquipmentRequiresStation('Smith'), isTrue);
    expect(stationEquipmentRequiresStation('máquina'), isTrue);
  });

  test('barra, haltere e tipo ausente não pedem estação', () {
    expect(stationEquipmentRequiresStation('Barra'), isFalse);
    expect(stationEquipmentRequiresStation('Haltere'), isFalse);
    expect(stationEquipmentRequiresStation('Anilha'), isFalse);
    expect(stationEquipmentRequiresStation('Elástico'), isFalse);
    expect(stationEquipmentRequiresStation('Bodyweight'), isFalse);
    expect(stationEquipmentRequiresStation(null), isFalse);
    expect(stationEquipmentRequiresStation('  '), isFalse);
  });
}
