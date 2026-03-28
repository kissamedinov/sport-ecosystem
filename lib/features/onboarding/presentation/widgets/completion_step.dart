import 'package:flutter/material.dart';

class CompletionStep extends StatelessWidget {
  final VoidCallback onFinish;

  const CompletionStep({super.key, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFF00E676)),
          const SizedBox(height: 32),
          Text(
            'All Set!',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your profile is ready. Welcome to the future of football management.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('FINISH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
