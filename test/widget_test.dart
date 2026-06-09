import 'package:flutter_test/flutter_test.dart';
import 'package:musiary/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MusiaryApp());
    expect(find.byType(MusiaryApp), findsOneWidget);
  });
}
