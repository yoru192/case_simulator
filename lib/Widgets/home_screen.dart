import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onCasesTap;

  const HomeScreen({
    super.key,
    required this.onCasesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              children: [
                Text(
                  "CASE SIMULATOR",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Welcome to CS:GO Case Simulator!",
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  "To begin opening cases, tap icon\non the bottom and select case.",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  "Have fun and Good luck!",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _CaseButton(onTap: onCasesTap),
        ],
      ),
    );
  }
}

class _CaseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CaseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_giftcard, size: 60, color: Colors.white),
            SizedBox(height: 10),
            Text(
              "Select case here...",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
