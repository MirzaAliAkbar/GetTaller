import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gettaller_app/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GetTallerApp(),
      ),
    );
    // App should render without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
