import 'package:flutter_test/flutter_test.dart';
import 'package:kratos/main.dart';

void main() {
  testWidgets('App renders welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KratosApp());
    expect(find.text('KRATOS'), findsOneWidget);
  });
}
