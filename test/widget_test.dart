import 'package:flutter_test/flutter_test.dart';
import 'package:pawnder/main.dart';

void main() {
  testWidgets('Pawnder app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PawnderApp());

    expect(find.byType(PawnderApp), findsOneWidget);
  });
}