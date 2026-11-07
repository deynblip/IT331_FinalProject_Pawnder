import 'package:flutter_test/flutter_test.dart';
import 'package:paw_kie/main.dart';

void main() {
  testWidgets('Pawnder app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PawnderApp());

    expect(find.byType(PawnderApp), findsOneWidget);
  });
}