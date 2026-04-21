import 'package:flutter/material.dart';

import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/orleon_widgets.dart';

class LineupScreen extends StatefulWidget {
  final String? teamName;
  final String? opponent;
  final DateTime? matchDate;

  const LineupScreen({
    super.key,
    this.teamName,
    this.opponent,
    this.matchDate,
  });

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen> {
  String _formation = '4-3-3';
  final Set<int> _selected = <int>{};

  static const _formations = ['4-3-3', '4-4-2', '4-2-3-1', '3-5-2'];

  // Demo roster — real impl wires to provider
  final List<_PlayerVM> _roster = List.generate(
    22,
    (i) => _PlayerVM(
      id: i + 1,
      number: i + 1,
      name: _names[i % _names.length],
      position: _positions[i % _positions.length],
      rating: 7.0 + (i % 5) * 0.3,
    ),
  );

  static const _names = [
    'Oliver', 'Liam', 'Noah', 'Elias', 'Luca', 'Hugo', 'Arthur', 'Jules',
    'Ethan', 'Nolan', 'Leo', 'Gabriel', 'Adam', 'Raphael', 'Nathan',
    'Paul', 'Aaron', 'Mark', 'Tom', 'Marc', 'Kai', 'Sam',
  ];
  static const _positions = ['GK', 'DEF', 'DEF', 'DEF', 'MID', 'MID', 'MID', 'FOR', 'FOR'];

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;
    final submitEnabled = selectedCount == 11;

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _formationSwitcher(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: AspectRatio(
                aspectRatio: 1.3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: PremiumTheme.pitchGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: PremiumTheme.softShadow,
                    ),
                    child: LayoutBuilder(
                      builder: (ctx, c) {
                        final positions = _positionsFor(_formation);
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _PitchPainter()),
                            ),
                            ...positions.asMap().entries.map((entry) {
                              final i = entry.key;
                              final off = entry.value;
                              final selected = i < _selected.length;
                              final player = selected
                                  ? _roster.firstWhere(
                                      (p) => p.id == _selected.elementAt(i),
                                      orElse: () => _roster.first,
                                    )
                                  : null;
                              return Positioned(
                                left: off.dx * c.maxWidth - 19,
                                top: off.dy * c.maxHeight - 19,
                                child: _PitchSlot(player: player),
                              );
                            }),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '$selectedCount / 11',
                    style: TextStyle(
                      color: submitEnabled
                          ? PremiumTheme.neonGreen
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'selected',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (selectedCount > 0)
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      style: TextButton.styleFrom(
                        foregroundColor: PremiumTheme.danger,
                      ),
                      child: const Text(
                        'CLEAR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _rosterList()),
            _submitBar(submitEnabled),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final team = widget.teamName ?? 'My Team';
    final opp = widget.opponent ?? 'Opponent';
    final d = widget.matchDate ?? DateTime.now().add(const Duration(days: 1));
    final when = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$team  vs  $opp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  when,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'LINEUP',
            style: TextStyle(
              color: PremiumTheme.neonGreen,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _formationSwitcher() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _formations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _formations[i];
            final active = f == _formation;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active
                    ? PremiumTheme.neonGreen
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? PremiumTheme.neonGreen
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _formation = f),
                child: Center(
                  child: Text(
                    f,
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _rosterList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: _roster.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _roster[i];
        final sel = _selected.contains(p.id);
        return OrleonCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          borderColor: sel
              ? PremiumTheme.neonGreen.withValues(alpha: 0.5)
              : PremiumTheme.borderGrey,
          onTap: () {
            setState(() {
              if (sel) {
                _selected.remove(p.id);
              } else if (_selected.length < 11) {
                _selected.add(p.id);
              }
            });
          },
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${p.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.position} · Rating ${p.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel
                      ? PremiumTheme.neonGreen
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: sel ? PremiumTheme.neonGreen : Colors.white24,
                    width: 2,
                  ),
                ),
                child: sel
                    ? const Icon(Icons.check, color: Colors.black, size: 16)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _submitBar(bool enabled) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: PremiumTheme.cardNavy,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: enabled
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: PremiumTheme.neonGreen,
                        content: Text(
                          'Lineup submitted',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.neonGreen,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
              disabledForegroundColor: Colors.white38,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              enabled ? 'SUBMIT LINEUP' : 'SELECT 11 PLAYERS',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Offset> _positionsFor(String formation) {
    // 11 slots, normalized to pitch size (0..1)
    // Goalkeeper at bottom, attackers at top
    switch (formation) {
      case '4-4-2':
        return const [
          Offset(0.5, 0.92), // GK
          Offset(0.18, 0.74), Offset(0.39, 0.74), Offset(0.61, 0.74), Offset(0.82, 0.74), // DEF
          Offset(0.18, 0.48), Offset(0.39, 0.48), Offset(0.61, 0.48), Offset(0.82, 0.48), // MID
          Offset(0.35, 0.18), Offset(0.65, 0.18), // FOR
        ];
      case '4-2-3-1':
        return const [
          Offset(0.5, 0.92),
          Offset(0.18, 0.74), Offset(0.39, 0.74), Offset(0.61, 0.74), Offset(0.82, 0.74),
          Offset(0.35, 0.56), Offset(0.65, 0.56),
          Offset(0.22, 0.34), Offset(0.5, 0.34), Offset(0.78, 0.34),
          Offset(0.5, 0.14),
        ];
      case '3-5-2':
        return const [
          Offset(0.5, 0.92),
          Offset(0.25, 0.74), Offset(0.5, 0.74), Offset(0.75, 0.74),
          Offset(0.1, 0.52), Offset(0.3, 0.52), Offset(0.5, 0.52), Offset(0.7, 0.52), Offset(0.9, 0.52),
          Offset(0.35, 0.18), Offset(0.65, 0.18),
        ];
      case '4-3-3':
      default:
        return const [
          Offset(0.5, 0.92),
          Offset(0.18, 0.74), Offset(0.39, 0.74), Offset(0.61, 0.74), Offset(0.82, 0.74),
          Offset(0.28, 0.52), Offset(0.5, 0.52), Offset(0.72, 0.52),
          Offset(0.22, 0.2), Offset(0.5, 0.14), Offset(0.78, 0.2),
        ];
    }
  }
}

class _PlayerVM {
  final int id;
  final int number;
  final String name;
  final String position;
  final double rating;
  const _PlayerVM({
    required this.id,
    required this.number,
    required this.name,
    required this.position,
    required this.rating,
  });
}

class _PitchSlot extends StatelessWidget {
  final _PlayerVM? player;
  const _PitchSlot({this.player});

  @override
  Widget build(BuildContext context) {
    final filled = player != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: filled ? PremiumTheme.primaryGradient : null,
        color: filled ? null : Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: filled ? Colors.white : Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        filled ? '${player!.number}' : '+',
        style: TextStyle(
          color: filled ? Colors.black : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      stroke,
    );

    // Halfway line
    canvas.drawLine(
      Offset(rect.left, size.height / 2),
      Offset(rect.right, size.height / 2),
      stroke,
    );

    // Center circle + dot
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.09,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );

    // Penalty boxes (top + bottom)
    final boxW = size.width * 0.55;
    final boxH = size.height * 0.18;
    final topBox = Rect.fromLTWH(
      (size.width - boxW) / 2,
      rect.top,
      boxW,
      boxH,
    );
    final bottomBox = Rect.fromLTWH(
      (size.width - boxW) / 2,
      rect.bottom - boxH,
      boxW,
      boxH,
    );
    canvas.drawRect(topBox, stroke);
    canvas.drawRect(bottomBox, stroke);

    // Goal areas
    final gW = size.width * 0.28;
    final gH = size.height * 0.08;
    canvas.drawRect(
      Rect.fromLTWH((size.width - gW) / 2, rect.top, gW, gH),
      stroke,
    );
    canvas.drawRect(
      Rect.fromLTWH((size.width - gW) / 2, rect.bottom - gH, gW, gH),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
