import 'package:flutter/material.dart';

import '../features/game/presentation/game_screen.dart';
import '../features/onboarding/presentation/caution_screen.dart';
import '../features/onboarding/presentation/gender_question_screen.dart';
import '../features/onboarding/presentation/ready_screen.dart';
import '../features/results/presentation/broke_fast_screen.dart';
import '../runtime_context.dart';
import 'models/app_screen.dart';
import 'models/participant_type.dart';

class RamadanSimApp extends StatefulWidget {
  const RamadanSimApp({super.key});

  @override
  State<RamadanSimApp> createState() => _RamadanSimAppState();
}

class _RamadanSimAppState extends State<RamadanSimApp> {
  ParticipantType? _participantType;
  RuntimeContext? _runtimeContext;
  AppScreen _screen = AppScreen.genderQuestion;
  bool _accelerometerGranted = false;
  double _lastRunSeconds = 0;

  Future<void> _selectParticipantType(ParticipantType type) async {
    final runtimeContext = detectRuntimeContext();

    setState(() {
      _participantType = type;
      _runtimeContext = runtimeContext;
      _accelerometerGranted =
          runtimeContext.motionSupport != MotionSupport.browserAccelerometer;
      _screen = AppScreen.caution;
    });
  }

  void _showReadyScreen() {
    setState(() {
      _screen = AppScreen.ready;
    });
  }

  void _startGame() {
    setState(() {
      _screen = AppScreen.game;
    });
  }

  void _showBrokeFastScreen(double seconds) {
    setState(() {
      _lastRunSeconds = seconds;
      _screen = AppScreen.brokeFast;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ramadan Sim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFFC9C1A6),
        fontFamily: 'Times New Roman',
      ),
      home: switch (_screen) {
        AppScreen.genderQuestion => GenderQuestionScreen(
          onSelected: _selectParticipantType,
        ),
        AppScreen.caution => CautionScreen(onContinue: _showReadyScreen),
        AppScreen.ready => ReadyScreen(
          participantType: _participantType!,
          runtimeContext: _runtimeContext!,
          accelerometerGranted: _accelerometerGranted,
          onStartGame: _startGame,
        ),
        AppScreen.game => FallingObjectGameScreen(
          onGameOver: _showBrokeFastScreen,
          playerAssetPath: _participantType!.playerAssetPath,
        ),
        AppScreen.brokeFast => BrokeFastScreen(
          onTryAgain: _startGame,
          survivalSeconds: _lastRunSeconds,
        ),
      },
    );
  }
}
