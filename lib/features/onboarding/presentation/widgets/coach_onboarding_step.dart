import 'package:flutter/material.dart';

class CoachOnboardingStep extends StatelessWidget {
  final VoidCallback onNext;

  const CoachOnboardingStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports, size: 80, color: Color(0xFF00E676)),
          const SizedBox(height: 32),
          Text(
            'Coach Access',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text(
            'To start managing teams, you need to be invited by a Club Owner or request access to an existing organization.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () {
              // Simulated request access
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Access request sent to nearby clubs.')),
              );
              onNext();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('REQUEST ACCESS & CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onNext,
            child: const Text('I will wait for an invitation', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}
