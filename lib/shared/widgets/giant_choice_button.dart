import 'package:flutter/material.dart';

class GiantChoiceButton extends StatelessWidget {
  const GiantChoiceButton({
    super.key,
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
