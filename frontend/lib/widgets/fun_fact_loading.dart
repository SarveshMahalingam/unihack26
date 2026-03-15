import 'dart:math';
import 'package:flutter/material.dart';

class FunFactLoadingDialog extends StatefulWidget {
  const FunFactLoadingDialog({super.key});

  @override
  State<FunFactLoadingDialog> createState() => _FunFactLoadingDialogState();
}

class _FunFactLoadingDialogState extends State<FunFactLoadingDialog> {
  final List<String> _facts = [
    "Analyzing ingredients... Did you know the barcode was invented in 1952 and was inspired by Morse code?",
    "Cross-referencing your profile... Apples are more effective at waking you up than coffee!",
    "Checking ethics scores... Sustainable farming practices can increase crop yields by up to 58%.",
    "Scanning dietary matches... Strawberries aren't technically berries, but bananas are!",
    "Decoding the Nutri-Score... Honey is the only food that never spoils!"
  ];
  
  late String _currentFact;

  @override
  void initState() {
    super.initState();
    // Pick a random fact when the dialog opens
    _currentFact = _facts[Random().nextInt(_facts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF008C5A)),
            const SizedBox(height: 24),
            const Text(
              "Just a second...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _currentFact,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}