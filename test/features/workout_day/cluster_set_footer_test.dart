import 'package:flutter_test/flutter_test.dart';
import 'package:iron_log/features/workout_day/presentation/widgets/technique/cluster_set_footer.dart';

void main() {
  group('ClusterSetFooter.progressPercent', () {
    test('returns 0 when total is zero', () {
      expect(ClusterSetFooter.progressPercent(0, 0), 0);
    });

    test('rounds completion percentage', () {
      expect(ClusterSetFooter.progressPercent(1, 3), 33);
      expect(ClusterSetFooter.progressPercent(2, 3), 67);
      expect(ClusterSetFooter.progressPercent(3, 3), 100);
    });
  });
}
