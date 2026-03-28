import 'package:flutter/material.dart';

class PlayerOnboardingStep extends StatefulWidget {
  final Function(String position) onNext;

  const PlayerOnboardingStep({super.key, required this.onNext});

  @override
  State<PlayerOnboardingStep> createState() => _PlayerOnboardingStepState();
}

class _PlayerOnboardingStepState extends State<PlayerOnboardingStep> {
  String _selectedPosition = 'FW';
  final List<String> _positions = ['GK', 'DF', 'MF', 'FW'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.sports_soccer, size: 60, color: Color(0xFF00E676)),
          const SizedBox(height: 24),
          Text(
            'Your Position',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'What is your preferred position on the pitch?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _positions.map((pos) {
              final isSelected = _selectedPosition == pos;
              return GestureDetector(
                onTap: () => setState(() => _selectedPosition = pos),
                child: Container(
                  width: 140,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00E676).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E676) : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      pos,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => widget.onNext(_selectedPosition),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF00E676),
            ),
            child: const Text('CONTINUE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
