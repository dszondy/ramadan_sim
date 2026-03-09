import 'package:flutter/material.dart';

import '../../../shared/widgets/big_question_panel.dart';
import '../../../shared/widgets/giant_choice_button.dart';
import '../../../shared/widgets/retro_page.dart';

class CautionScreen extends StatelessWidget {
  const CautionScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BigQuestionPanel(text: 'CAUTON!!!', fontSize: 56),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            color: const Color(0xFFEEE7CC),
            child: const Text(
              'This is a very realistic ramadan simulator. We take no responsibility for any damages that may occur',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 28),
          GiantChoiceButton(
            label: 'I UNDERSTAND',
            buttonColor: const Color(0xFF7DFF72),
            fullWidth: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
