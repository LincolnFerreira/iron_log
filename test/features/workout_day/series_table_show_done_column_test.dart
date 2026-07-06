import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/domain/entities/series_entry.dart';
import 'package:iron_log/features/workout_day/presentation/components/molecules/series_table.dart';

void main() {
  testWidgets('SeriesTable hides FEITO when showDoneColumn is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeriesTable(
            count: 1,
            weight: '40',
            reps: '10',
            entries: [
              SeriesEntry(index: 0, weight: '40', reps: '10'),
            ],
            showDoneColumn: false,
            onEntriesChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('FEITO'), findsNothing);
  });
}
