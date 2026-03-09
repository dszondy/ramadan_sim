import 'package:flutter/material.dart';

import '../../../shared/widgets/giant_choice_button.dart';
import '../../../shared/widgets/retro_page.dart';

class BrokeFastScreen extends StatelessWidget {
  static const double _secondsPerDay = 24 * 60 * 60;

  const BrokeFastScreen({
    super.key,
    required this.onTryAgain,
    required this.survivalSeconds,
  });

  final VoidCallback onTryAgain;
  final double survivalSeconds;

  String get _fastedDayPercentageText {
    final percentage = (survivalSeconds / _secondsPerDay) * 100;

    for (var decimals = 2; decimals <= 10; decimals++) {
      final formatted = percentage.toStringAsFixed(decimals);
      final nonZeroDigits = formatted.replaceAll(RegExp(r'[^1-9]'), '').length;
      if (nonZeroDigits >= 2) {
        return formatted;
      }
    }

    return percentage.toStringAsExponential(2);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final titleSize = width < 500
        ? 42.0
        : width < 900
        ? 64.0
        : 82.0;
    final emojiSize = width < 500 ? 32.0 : 40.0;

    return RetroPage(
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
            'you fasted a total of ${survivalSeconds.toStringAsFixed(1)} seconds',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "that's like $_fastedDayPercentageText% of the day",
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
          GiantChoiceButton(
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
