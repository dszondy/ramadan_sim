import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:ramadan_sim/app/ramadan_sim_app.dart';
import 'package:ramadan_sim/features/game/presentation/game_screen.dart';
import 'package:ramadan_sim/features/results/presentation/broke_fast_screen.dart';

void main() {
  testWidgets('selecting a choice can reach the game screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RamadanSimApp());

    expect(find.text("I'm participating in ramadan a... ?"), findsOneWidget);
    expect(find.text('MAN'), findsOneWidget);
    expect(find.text('WOMAN'), findsOneWidget);
    expect(find.text('OTHER'), findsOneWidget);

    await tester.tap(find.text('MAN'));
    await tester.pumpAndSettle();

    expect(find.text('CAUTON!!!'), findsOneWidget);
    expect(find.text('I UNDERSTAND'), findsOneWidget);

    await tester.tap(find.text('I UNDERSTAND'));
    await tester.pumpAndSettle();

    expect(find.text('Ready?'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pumpAndSettle();

    expect(find.byType(FallingObjectGameScreen), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('broke fast screen renders retro failure state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BrokeFastScreen(onTryAgain: () {}, survivalSeconds: 12.3),
      ),
    );

    expect(find.text('You just broke your fast'), findsOneWidget);
    expect(find.text('you fasted 12.3 seconds'), findsOneWidget);
    expect(find.text("that's like 0.0142% of the day"), findsOneWidget);
    expect(find.text(':( '), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(find.text('(but if its your birthsday its fine)'), findsOneWidget);
  });
}
