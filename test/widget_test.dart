// HealthGuard AI Widget Smoke Test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1healthgaurdai/main.dart';

void main() {
  testWidgets('App builds and boots smoke test', (WidgetTester tester) async {
    // Set a realistic viewport size to avoid layout overflows during test
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    // Let any timers/animations complete
    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);

    // Reset the physical size after the test completes
    addTearDown(tester.view.resetPhysicalSize);
  });
}
