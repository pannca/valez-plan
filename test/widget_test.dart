import 'package:flutter_test/flutter_test.dart';
import 'package:valezplan/main.dart';

void main() {
  testWidgets('ValezPlan smoke test', (WidgetTester tester) async {
    // Verifikasi bahwa ValezPlanApp dapat di-mount
    await tester.pumpWidget(const ValezPlanApp());
    expect(find.byType(ValezPlanApp), findsOneWidget);
  });
}
