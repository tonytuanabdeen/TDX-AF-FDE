import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fde_bank/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FdeBankApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
