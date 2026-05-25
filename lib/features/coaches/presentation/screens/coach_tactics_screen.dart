import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class CoachTacticsScreen extends StatefulWidget {
  const CoachTacticsScreen({super.key});

  @override
  State<CoachTacticsScreen> createState() => _CoachTacticsScreenState();
}

class _CoachTacticsScreenState extends State<CoachTacticsScreen> {
  String _format = '11v11';
  String _selected = '4-3-3';

  static const _formationsByFormat = <String, List<_Formation>>{
    '11v11': [
      _Formation('4-3-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.72), _Pos('CB', 0.35, 0.72), _Pos('CB', 0.65, 0.72), _Pos('RB', 0.9, 0.72)],
        [_Pos('CM', 0.2, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.8, 0.50)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ], 'Balanced attack and defence'),
      _Formation('4-4-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.72), _Pos('CB', 0.35, 0.72), _Pos('CB', 0.65, 0.72), _Pos('RB', 0.9, 0.72)],
        [_Pos('LM', 0.1, 0.50), _Pos('CM', 0.35, 0.50), _Pos('CM', 0.65, 0.50), _Pos('RM', 0.9, 0.50)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ], 'Classic double striker system'),
      _Formation('3-5-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.72), _Pos('CB', 0.5, 0.72), _Pos('CB', 0.8, 0.72)],
        [_Pos('LWB', 0.05, 0.52), _Pos('CM', 0.28, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.72, 0.50), _Pos('RWB', 0.95, 0.52)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ], 'Wing-back dominance'),
      _Formation('4-2-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.72), _Pos('CB', 0.35, 0.72), _Pos('CB', 0.65, 0.72), _Pos('RB', 0.9, 0.72)],
        [_Pos('DM', 0.35, 0.56), _Pos('DM', 0.65, 0.56)],
        [_Pos('LW', 0.15, 0.40), _Pos('CAM', 0.5, 0.38), _Pos('RW', 0.85, 0.40)],
        [_Pos('ST', 0.5, 0.20)],
      ], 'Single striker with CAM'),
      _Formation('5-3-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LWB', 0.05, 0.70), _Pos('CB', 0.25, 0.74), _Pos('CB', 0.5, 0.74), _Pos('CB', 0.75, 0.74), _Pos('RWB', 0.95, 0.70)],
        [_Pos('CM', 0.25, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.75, 0.50)],
        [_Pos('ST', 0.35, 0.24), _Pos('ST', 0.65, 0.24)],
      ], 'Defensive solidity'),
    ],
    '9v9': [
      _Formation('3-3-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.72), _Pos('CB', 0.5, 0.72), _Pos('CB', 0.8, 0.72)],
        [_Pos('CM', 0.2, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.8, 0.50)],
        [_Pos('ST', 0.35, 0.26), _Pos('ST', 0.65, 0.26)],
      ], 'Most common 9v9 formation'),
      _Formation('3-2-3', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.72), _Pos('CB', 0.5, 0.72), _Pos('CB', 0.8, 0.72)],
        [_Pos('CM', 0.35, 0.50), _Pos('CM', 0.65, 0.50)],
        [_Pos('LW', 0.15, 0.26), _Pos('ST', 0.5, 0.22), _Pos('RW', 0.85, 0.26)],
      ], 'Attack-minded 9v9'),
      _Formation('4-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('LB', 0.1, 0.72), _Pos('CB', 0.37, 0.72), _Pos('CB', 0.63, 0.72), _Pos('RB', 0.9, 0.72)],
        [_Pos('CM', 0.2, 0.50), _Pos('CM', 0.5, 0.50), _Pos('CM', 0.8, 0.50)],
        [_Pos('ST', 0.5, 0.24)],
      ], 'Defensive 9v9 structure'),
    ],
    '6v6': [
      _Formation('2-2-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.70), _Pos('CB', 0.7, 0.70)],
        [_Pos('CM', 0.3, 0.48), _Pos('CM', 0.7, 0.48)],
        [_Pos('ST', 0.5, 0.24)],
      ], 'Balanced 6-aside'),
      _Formation('1-3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.5, 0.72)],
        [_Pos('LM', 0.2, 0.50), _Pos('CM', 0.5, 0.50), _Pos('RM', 0.8, 0.50)],
        [_Pos('ST', 0.5, 0.24)],
      ], 'Midfield control 6-aside'),
      _Formation('2-1-2', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.70), _Pos('CB', 0.7, 0.70)],
        [_Pos('CM', 0.5, 0.50)],
        [_Pos('LW', 0.25, 0.26), _Pos('RW', 0.75, 0.26)],
      ], 'Wide attack 6-aside'),
    ],
    '5v5': [
      _Formation('2-1-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.3, 0.70), _Pos('CB', 0.7, 0.70)],
        [_Pos('CM', 0.5, 0.48)],
        [_Pos('ST', 0.5, 0.24)],
      ], 'Classic 5-aside'),
      _Formation('1-2-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.5, 0.72)],
        [_Pos('CM', 0.3, 0.48), _Pos('CM', 0.7, 0.48)],
        [_Pos('ST', 0.5, 0.24)],
      ], 'Midfield-heavy 5-aside'),
      _Formation('3-1', [
        [_Pos('GK', 0.5, 0.92)],
        [_Pos('CB', 0.2, 0.70), _Pos('CB', 0.5, 0.70), _Pos('CB', 0.8, 0.70)],
        [_Pos('ST', 0.5, 0.28)],
      ], 'Defensive 5-aside'),
    ],
  };

  List<_Formation> get _currentFormations => _formationsByFormat[_format]!;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formation = _currentFormations.firstWhere((f) => f.name == _selected);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('TACTICS', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: Column(
        children: [
          // Format selector
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['11v11', '9v9', '6v6', '5v5'].map((fmt) {
                final active = fmt == _format;
                return GestureDetector(
                  onTap: () => setState(() {
                    _format = fmt;
                    _selected = _formationsByFormat[fmt]!.first.name;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? PremiumTheme.neonGreen
                          : PremiumTheme.neonGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? PremiumTheme.neonGreen
                            : PremiumTheme.neonGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      fmt,
                      style: TextStyle(
                        color: active ? Colors.black : PremiumTheme.neonGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Formation selector
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _currentFormations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _currentFormations[i];
                final active = f.name == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = f.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? PremiumTheme.neonGreen
                          : PremiumTheme.neonGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active
                            ? PremiumTheme.neonGreen
                            : PremiumTheme.neonGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      f.name,
                      style: TextStyle(
                        color: active ? Colors.black : PremiumTheme.neonGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  formation.description,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Pitch
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        _buildPitch(w, h),
                        for (final line in formation.lines)
                          for (final pos in line)
                            Positioned(
                              left: pos.x * w - 22,
                              top: pos.y * h - 25,
                              child: _buildPlayer(pos.label),
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _legendItem('GK', Colors.amber),
                _legendItem('DEF', PremiumTheme.electricBlue),
                _legendItem('MID', PremiumTheme.neonGreen),
                _legendItem('ATT', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitch(double w, double h) {
    return CustomPaint(
      size: Size(w, h),
      painter: _PitchPainter(),
    );
  }

  Widget _buildPlayer(String label) {
    final color = _posColor(label);
    return SizedBox(
      width: 44,
      height: 50,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: Text(
                label.length > 2 ? label.substring(0, 2) : label,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
          ),
        ],
      ),
    );
  }

  Color _posColor(String pos) {
    if (pos == 'GK') return Colors.amber.shade700;
    if (pos.contains('B') || pos == 'SW') return PremiumTheme.electricBlue;
    if (pos == 'ST' || pos.contains('W') || pos == 'CF' || pos == 'CAM') return Colors.redAccent;
    return PremiumTheme.neonGreen;
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Pos {
  final String label;
  final double x;
  final double y;
  const _Pos(this.label, this.x, this.y);
}

class _Formation {
  final String name;
  final List<List<_Pos>> lines;
  final String description;
  const _Formation(this.name, this.lines, this.description);
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grass = Paint()..color = const Color(0xFF2E7D32);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grass);

    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final stripeH = size.height / 8;
    for (int i = 0; i < 8; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, size.width, stripeH), stripe);
    }

    canvas.drawRect(Rect.fromLTRB(8, 8, size.width - 8, size.height - 8), line);
    canvas.drawLine(Offset(8, size.height / 2), Offset(size.width - 8, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.14, line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3, Paint()..color = Colors.white.withValues(alpha: 0.5));

    final bw = size.width * 0.55;
    final bh = size.height * 0.14;
    final bx = (size.width - bw) / 2;
    canvas.drawRect(Rect.fromLTWH(bx, 8, bw, bh), line);
    canvas.drawRect(Rect.fromLTWH(bx, size.height - 8 - bh, bw, bh), line);

    final gw = size.width * 0.2;
    final gh = size.height * 0.03;
    final gx = (size.width - gw) / 2;
    canvas.drawRect(Rect.fromLTWH(gx, 5, gw, gh), line);
    canvas.drawRect(Rect.fromLTWH(gx, size.height - 5 - gh, gw, gh), line);
  }

  @override
  bool shouldRepaint(_PitchPainter old) => false;
}
