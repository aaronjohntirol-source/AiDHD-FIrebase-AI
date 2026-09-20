import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aidhd/app.dart';
import 'package:aidhd/providers/app_provider.dart';

void main() {
  testWidgets('AIDHD app starts successfully', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = AppProvider();
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const AidhdApp(),
      ),
    );

    expect(find.byType(AidhdApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
