import 'package:flutter/material.dart';

import 'game_screen.dart';
import 'runtime_context.dart';

void main() {
  runApp(const RamadanSimApp());
}

enum ParticipantType { man, woman, other }

enum AppScreen { genderQuestion, accelerometerPrompt, ready, game, brokeFast }

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
  bool _isRequestingAccelerometer = false;
  double _lastRunSeconds = 0;

  Future<void> _selectParticipantType(ParticipantType type) async {
    final runtimeContext = detectRuntimeContext();

    setState(() {
      _participantType = type;
      _runtimeContext = runtimeContext;
      _accelerometerGranted = false;
      _screen = runtimeContext.needsBrowserAccelerometerPrompt
          ? AppScreen.accelerometerPrompt
          : AppScreen.ready;
    });
  }

  Future<void> _enableBrowserAccelerometer() async {
    setState(() {
      _isRequestingAccelerometer = true;
    });

    final granted = await requestBrowserAccelerometerAccess();

    if (!mounted) {
      return;
    }

    setState(() {
      _accelerometerGranted = granted;
      _isRequestingAccelerometer = false;
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
        AppScreen.accelerometerPrompt => AccelerometerPromptScreen(
          isRequesting: _isRequestingAccelerometer,
          onEnable: _enableBrowserAccelerometer,
        ),
        AppScreen.ready => ReadyScreen(
          participantType: _participantType!,
          runtimeContext: _runtimeContext!,
          accelerometerGranted: _accelerometerGranted,
          onStartGame: _startGame,
        ),
        AppScreen.game => FallingObjectGameScreen(
          onGameOver: _showBrokeFastScreen,
          playerAssetPath: _playerAssetPath(_participantType!),
        ),
        AppScreen.brokeFast => BrokeFastScreen(
          onTryAgain: _startGame,
          survivalSeconds: _lastRunSeconds,
        ),
      },
    );
  }

  String _playerAssetPath(ParticipantType participantType) {
    return switch (participantType) {
      ParticipantType.man => 'assets/rs_man.png',
      ParticipantType.woman => 'assets/rs_woman.png',
      ParticipantType.other => 'assets/rs_other.png',
    };
  }
}

class GenderQuestionScreen extends StatelessWidget {
  const GenderQuestionScreen({super.key, required this.onSelected});

  final ValueChanged<ParticipantType> onSelected;

  @override
  Widget build(BuildContext context) {
    return _RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BigQuestionPanel(
            text: "I'm participating in ramadan a... ?",
            fontSize: 34,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _GiantChoiceButton(
                  label: 'MAN',
                  buttonColor: const Color(0xFF45C4FF),
                  onPressed: () => onSelected(ParticipantType.man),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _GiantChoiceButton(
                  label: 'WOMAN',
                  buttonColor: const Color(0xFFFF78B2),
                  onPressed: () => onSelected(ParticipantType.woman),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GiantChoiceButton(
            label: 'OTHER',
            buttonColor: const Color(0xFFFFD84D),
            fullWidth: true,
            onPressed: () => onSelected(ParticipantType.other),
          ),
        ],
      ),
    );
  }
}

class AccelerometerPromptScreen extends StatelessWidget {
  const AccelerometerPromptScreen({
    super.key,
    required this.onEnable,
    required this.isRequesting,
  });

  final VoidCallback onEnable;
  final bool isRequesting;

  @override
  Widget build(BuildContext context) {
    return _RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BigQuestionPanel(
            text: 'Browser accelerometer needed',
            fontSize: 34,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: const Color(0xFFEEE7CC),
            child: const Text(
              'You are on a phone browser. Allow motion access so the game can use the accelerometer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _GiantChoiceButton(
            label: isRequesting ? 'WAIT...' : 'ALLOW',
            buttonColor: const Color(0xFF7DFF72),
            fullWidth: true,
            onPressed: isRequesting ? () {} : onEnable,
          ),
        ],
      ),
    );
  }
}

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({
    super.key,
    required this.participantType,
    required this.runtimeContext,
    required this.accelerometerGranted,
    required this.onStartGame,
  });

  final ParticipantType participantType;
  final RuntimeContext runtimeContext;
  final bool accelerometerGranted;
  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    return _RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BigQuestionPanel(text: 'Ready?', fontSize: 56),
          const SizedBox(height: 28),
          _InfoPanel(text: 'Selected: ${participantType.name.toUpperCase()}'),
          const SizedBox(height: 16),
          _InfoPanel(text: 'Platform: ${_platformLabel(runtimeContext.mode)}'),
          const SizedBox(height: 16),
          _InfoPanel(text: 'Motion: ${_motionLabel()}'),
          const SizedBox(height: 24),
          _GiantChoiceButton(
            label: 'START',
            buttonColor: const Color(0xFF7DFF72),
            fullWidth: true,
            onPressed: onStartGame,
          ),
        ],
      ),
    );
  }

  String _motionLabel() {
    return switch (runtimeContext.motionSupport) {
      MotionSupport.none => 'NONE',
      MotionSupport.deviceAccelerometer => 'DEVICE ACCELEROMETER',
      MotionSupport.browserAccelerometer =>
        accelerometerGranted
            ? 'BROWSER ACCELEROMETER ENABLED'
            : 'BROWSER ACCELEROMETER NOT GRANTED',
    };
  }

  String _platformLabel(RuntimeMode mode) {
    return switch (mode) {
      RuntimeMode.desktopBrowser => 'DESKTOP BROWSER',
      RuntimeMode.mobileBrowser => 'MOBILE BROWSER',
      RuntimeMode.androidApp => 'ANDROID APP',
      RuntimeMode.iosApp => 'IOS APP',
      RuntimeMode.other => 'OTHER',
    };
  }
}

class BrokeFastScreen extends StatelessWidget {
  const BrokeFastScreen({
    super.key,
    required this.onTryAgain,
    required this.survivalSeconds,
  });

  final VoidCallback onTryAgain;
  final double survivalSeconds;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 500
        ? 42.0
        : width < 900
        ? 64.0
        : 82.0;
    final emojiSize = width < 500 ? 32.0 : 40.0;

    return _RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            color: const Color(0xFFEEE7CC),
            child: Text(
              'You just broke your fast',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'you lasted a total ${survivalSeconds.toStringAsFixed(1)} seconds',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            ':( ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: emojiSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          _GiantChoiceButton(
            label: 'TRY AGAIN',
            buttonColor: const Color(0xFF7DFF72),
            fullWidth: true,
            onPressed: onTryAgain,
          ),
          const SizedBox(height: 18),
          const Text(
            '(but if its your birthsday its fine)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetroPage extends StatelessWidget {
  const _RetroPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 900 ? 120.0 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BigQuestionPanel extends StatelessWidget {
  const _BigQuestionPanel({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFEEE7CC),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD8D0B5),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _GiantChoiceButton extends StatelessWidget {
  const _GiantChoiceButton({
    required this.label,
    required this.buttonColor,
    required this.onPressed,
    this.fullWidth = false,
  });

  final String label;
  final Color buttonColor;
  final VoidCallback onPressed;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.black,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.black, width: 3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: 140, child: button);
    }

    return SizedBox(height: 140, child: button);
  }
}
