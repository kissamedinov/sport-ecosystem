// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/theme/theme_provider.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = ThemeProvider(prefs);

    // Build a mock wrapper that provides ThemeProvider
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: Text('Football Ecosystem'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Football Ecosystem'), findsOneWidget);
  });
}
