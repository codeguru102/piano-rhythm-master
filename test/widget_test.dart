import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:piano_rhythm_master/theme/app_theme.dart';
import 'package:piano_rhythm_master/widgets/brand_mark.dart';
import 'package:piano_rhythm_master/widgets/gradient_background.dart';
import 'package:piano_rhythm_master/widgets/loading_progress.dart';

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

  testWidgets('LoadingProgress communicates its stage and percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: LoadingProgress(
            value: 0.68,
            status: 'Opening your song library',
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Opening your song library'), findsOneWidget);
    expect(find.text('68%'), findsOneWidget);
  });

  testWidgets('BrandMark exposes the product identity', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: BrandMark()),
      ),
    );

    expect(find.bySemanticsLabel('Piano Rhythm Master'), findsOneWidget);
  });
}
