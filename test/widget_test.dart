import 'package:flutter_test/flutter_test.dart';
import 'package:stepquest/app.dart';

void main() {
  testWidgets('StepQuest smoke test: App launches, displays splash and navigates',
      (WidgetTester tester) async {
    await tester.pumpWidget(const StepQuestApp());

    // Initially displays StepQuest splash elements
    expect(find.text('StepQuest'), findsWidgets);
    expect(find.text('Atteins tes objectifs'), findsOneWidget);

    // Advance time past the splash delay to settle animations and timers
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Now on login screen
    expect(find.text('Bon retour !'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
