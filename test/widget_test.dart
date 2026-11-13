// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sholatblok/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SholatBlokApp()),
    );
    // Verifikasi bahwa app dapat dirender tanpa crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
