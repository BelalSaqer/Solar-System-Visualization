import 'package:flutter_test/flutter_test.dart';

import 'package:solar_system_flutter/main.dart';

void main() {
  testWidgets('App renders the solar system home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SolarSystemApp());
    await tester.pump();

    expect(find.text('Pause Rotation'), findsOneWidget);
    expect(find.text('Planet Info'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });
}
