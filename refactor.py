import sys

with open("lib/features/coaches/presentation/screens/coach_attendance_screen.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if line.startswith("  void _showFeedbackSheet("):
        start_idx = i
    if line.startswith("  Widget _buildSubmitBtn() {"):
        end_idx = i
        break

if start_idx != -1 and end_idx != -1:
    new_method = """  void _showFeedbackSheet(BuildContext context, String playerId, String playerName) {
    if (_selectedSessionId == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FeedbackBottomSheet(
        playerId: playerId,
        playerName: playerName,
        sessionId: _selectedSessionId!,
      ),
    );
  }

"""
    lines[start_idx:end_idx] = [new_method]

    new_class = """
class _FeedbackBottomSheet extends StatefulWidget {
  final String playerId;
  final String playerName;
  final String sessionId;

  const _FeedbackBottomSheet({
    required this.playerId,
    required this.playerName,
    required this.sessionId,
  });

  @override
  State<_FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<_FeedbackBottomSheet> {
  double technical = 0;
  double tactical = 0;
  double physical = 0;
  double discipline = 0;
  late final TextEditingController textController;
  late final FocusNode focusNode;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget _buildSlider(BuildContext ctx, String label, double value, ValueChanged<double> onChanged, Color color) {
    final cs = Theme.of(ctx).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.1),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 24,
          left: 20, right: 20, top: 20,
        ),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceBase(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Feedback for ${widget.playerName}', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cs.onSurface)),
              const SizedBox(height: 24),
              
              _buildSlider(context, 'Technical', technical, (v) => setState(() => technical = v), const Color(0xFF42A5F5)),
              _buildSlider(context, 'Tactical', tactical, (v) => setState(() => tactical = v), PremiumTheme.neonGreen),
              _buildSlider(context, 'Physical', physical, (v) => setState(() => physical = v), Colors.amber),
              _buildSlider(context, 'Discipline', discipline, (v) => setState(() => discipline = v), const Color(0xFFB490D0)),
              
              const SizedBox(height: 24),
              TextField(
                controller: textController,
                focusNode: focusNode,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Message to parent...',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final provider = context.read<AcademyProvider>();
                    final success = await provider.submitCoachFeedback(
                      widget.playerId, 
                      widget.sessionId, 
                      technical.toInt(), 
                      tactical.toInt(), 
                      physical.toInt(), 
                      discipline.toInt(), 
                      textController.text
                    );
                    if (!mounted) return;
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Feedback sent to parent' : 'Failed to send feedback'),
                          backgroundColor: success ? PremiumTheme.neonGreen : Colors.red,
                        )
                      );
                  },
                  child: const Text('SEND FEEDBACK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
"""
    lines.append(new_class)
    
    with open("lib/features/coaches/presentation/screens/coach_attendance_screen.dart", "w", encoding="utf-8") as f:
        f.writelines(lines)
    print("Success")
else:
    print("Failed to find boundaries")
