import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piano_rhythm_master/theme/app_theme.dart';
import 'package:piano_rhythm_master/widgets/gradient_background.dart';

void main() {
  testWidgets('GradientBackground renders its child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const GradientBackground(child: Text('hello')),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });
}
