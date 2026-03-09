import 'package:flutter/material.dart';

import '../../../app/models/participant_type.dart';
import '../../../runtime_context.dart';
import '../../../shared/widgets/big_question_panel.dart';
import '../../../shared/widgets/giant_choice_button.dart';
import '../../../shared/widgets/retro_page.dart';

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
    return RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BigQuestionPanel(text: 'Ready?', fontSize: 56),
          const SizedBox(height: 24),
          GiantChoiceButton(
            label: 'START',
            buttonColor: const Color(0xFF7DFF72),
            fullWidth: true,
            onPressed: onStartGame,
          ),
        ],
      ),
    );
  }
}
