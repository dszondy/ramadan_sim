import 'package:flutter/material.dart';

import '../../../app/models/participant_type.dart';
import '../../../shared/widgets/big_question_panel.dart';
import '../../../shared/widgets/giant_choice_button.dart';
import '../../../shared/widgets/retro_page.dart';

class GenderQuestionScreen extends StatelessWidget {
  const GenderQuestionScreen({super.key, required this.onSelected});

  final ValueChanged<ParticipantType> onSelected;

  @override
  Widget build(BuildContext context) {
    return RetroPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BigQuestionPanel(
            text: "I'm participating in ramadan a... ?",
            fontSize: 34,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: GiantChoiceButton(
                  label: 'MAN',
                  buttonColor: const Color(0xFF45C4FF),
                  onPressed: () => onSelected(ParticipantType.man),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: GiantChoiceButton(
                  label: 'WOMAN',
                  buttonColor: const Color(0xFFFF78B2),
                  onPressed: () => onSelected(ParticipantType.woman),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GiantChoiceButton(
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
