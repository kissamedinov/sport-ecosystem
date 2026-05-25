import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/premium_theme.dart';

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

class _LineupScreenState extends State<LineupScreen>
    with SingleTickerProviderStateMixin {
  String _formation = '4-3-3';
  final Set<int> _selected = <int>{};
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  static const _formations = ['4-3-3', '4-4-2', '4-2-3-1', '3-5-2'];

  final List<_PlayerVM> _roster = List.generate(22, (i) => _PlayerVM(
    id: i + 1,
    number: i + 1,
    name: _names[i % _names.length],
    position: _positions[i % _positions.length],
    rating: 7.0 + (i % 5) * 0.3,
  ));

  static const _names = [
    'Oliver', 'Liam', 'Noah', 'Elias', 'Luca', 'Hugo', 'Arthur', 'Jules',
    'Ethan', 'Nolan', 'Leo', 'Gabriel', 'Adam', 'Raphael', 'Nathan',
    'Paul', 'Aaron', 'Mark', 'Tom', 'Marc', 'Kai', 'Sam',
  ];
  static const _positions = [
    'GK', 'DEF', 'DEF', 'DEF', 'MID', 'MID', 'MID', 'FWD', 'FWD',
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  void _updateProgress(int count) {
    _progressAnim = Tween<double>(begin: _progressAnim.value, end: count / 11).animate(
      CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut),
    );
    _progressCtrl
      ..reset()
      ..forward();
  }

  void _togglePlayer(_PlayerVM p) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(p.id)) {
        _selected.remove(p.id);
      } else if (_selected.length < 11) {
        _selected.add(p.id);
      }
      _updateProgress(_selected.length);
    });
  }

  Color _posColor(String pos) {
    switch (pos) {
      case 'GK': return const Color(0xFFFFC107);
      case 'DEF': return PremiumTheme.electricBlue;
      case 'MID': return PremiumTheme.neonGreen;
      case 'FWD': return const Color(0xFFFF5252);
      default: return PremiumTheme.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected.length;
    final ready = selected == 11;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildFormationBar()),
                SliverToBoxAdapter(child: _buildPitch()),
                SliverToBoxAdapter(child: _buildCounterRow(selected, ready)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildPlayerCard(_roster[i]),
                      childCount: _roster.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildSubmitBar(ready),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    final team = widget.teamName ?? 'My Team';
    final opp = widget.opponent ?? 'Opponent';
    final d = widget.matchDate ?? DateTime.now().add(const Duration(days: 1));
    final when =
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}'
        '  ·  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0D2118), const Color(0xFF0A0E12)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF5F5F5)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.chevron_left_rounded,
                    color: Theme.of(context).colorScheme.onSurface, size: 28),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(team,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Text('VS',
                            style: TextStyle(color: PremiumTheme.neonGreen,
                                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        Flexible(
                          child: Text(opp,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16, fontWeight: FontWeight.w900),
                            overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(when,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                ),
                child: const Text('LINEUP',
                  style: TextStyle(color: PremiumTheme.neonGreen,
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FORMATION BAR ────────────────────────────────────────────────────────────

  Widget _buildFormationBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _formations.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = _formations[i];
            final active = f == _formation;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _formation = f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: active ? PremiumTheme.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? PremiumTheme.neonGreen
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(f,
                  style: TextStyle(
                    color: active ? Colors.black : Theme.of(context).colorScheme.onSurface,
                    fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── PITCH ────────────────────────────────────────────────────────────────────

  Widget _buildPitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AspectRatio(
        aspectRatio: 0.68,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B6B2F), Color(0xFF145024)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.08),
                blurRadius: 24, spreadRadius: 2,
              ),
            ],
          ),
          child: LayoutBuilder(builder: (ctx, c) {
            final positions = _positionsFor(_formation);
            final posLabels = _positionLabels(_formation);
            return Stack(children: [
              Positioned.fill(child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(painter: _PitchPainter()),
              )),
              ...positions.asMap().entries.map((e) {
                final i = e.key;
                final off = e.value;
                final pid = i < _selected.length ? _selected.elementAt(i) : null;
                final player = pid != null
                    ? _roster.firstWhere((p) => p.id == pid, orElse: () => _roster.first)
                    : null;
                final label = i < posLabels.length ? posLabels[i] : '';
                return Positioned(
                  left: off.dx * c.maxWidth - 22,
                  top: off.dy * c.maxHeight - 28,
                  child: _PitchSlot(player: player, posLabel: label, posColor: _posColorFor(label)),
                );
              }),
            ]);
          }),
        ),
      ),
    );
  }

  Color _posColorFor(String label) {
    if (label == 'GK') return const Color(0xFFFFC107);
    if (label.contains('B') || label == 'DEF') return PremiumTheme.electricBlue;
    if (label.contains('M') || label == 'MID') return PremiumTheme.neonGreen;
    return const Color(0xFFFF5252);
  }

  // ── COUNTER ROW ──────────────────────────────────────────────────────────────

  Widget _buildCounterRow(int count, bool ready) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          RichText(text: TextSpan(children: [
            TextSpan(
              text: '$count',
              style: TextStyle(
                color: ready ? PremiumTheme.neonGreen : Theme.of(context).colorScheme.onSurface,
                fontSize: 22, fontWeight: FontWeight.w900),
            ),
            TextSpan(
              text: ' / 11  selected',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ])),
          const Spacer(),
          _legendChip('GK', const Color(0xFFFFC107)),
          const SizedBox(width: 6),
          _legendChip('DEF', PremiumTheme.electricBlue),
          const SizedBox(width: 6),
          _legendChip('MID', PremiumTheme.neonGreen),
          const SizedBox(width: 6),
          _legendChip('FWD', const Color(0xFFFF5252)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _selected.clear();
                  _updateProgress(0);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: PremiumTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PremiumTheme.danger.withValues(alpha: 0.3)),
                ),
                child: const Text('CLEAR',
                  style: TextStyle(color: PremiumTheme.danger,
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progressAnim.value,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(
                ready ? PremiumTheme.neonGreen : PremiumTheme.electricBlue),
              minHeight: 4,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  // ── PLAYER CARD ──────────────────────────────────────────────────────────────

  Widget _buildPlayerCard(_PlayerVM p) {
    final sel = _selected.contains(p.id);
    final posColor = _posColor(p.position);
    final canAdd = _selected.length < 11 || sel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: canAdd ? () => _togglePlayer(p) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? PremiumTheme.neonGreen.withValues(alpha: 0.07)
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel
                  ? PremiumTheme.neonGreen.withValues(alpha: 0.4)
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            // Jersey number
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: sel
                    ? PremiumTheme.neonGreen.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel
                      ? PremiumTheme.neonGreen.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              alignment: Alignment.center,
              child: Text('${p.number}',
                style: TextStyle(
                  color: sel
                      ? PremiumTheme.neonGreen
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            // Position color bar
            Container(
              width: 3, height: 36,
              decoration: BoxDecoration(
                color: posColor.withValues(alpha: sel ? 1.0 : 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            // Name + info
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: posColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(p.position,
                      style: TextStyle(color: posColor,
                          fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text('★ ${p.rating.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.9),
                      fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ],
            )),
            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? PremiumTheme.neonGreen : Colors.transparent,
                border: Border.all(
                  color: sel
                      ? PremiumTheme.neonGreen
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: sel
                  ? const Icon(Icons.check_rounded, color: Colors.black, size: 16)
                  : (!canAdd
                      ? Icon(Icons.lock_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                          size: 13)
                      : null),
            ),
          ]),
        ),
      ),
    );
  }

  // ── SUBMIT BAR ───────────────────────────────────────────────────────────────

  Widget _buildSubmitBar(bool ready) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        border: Border(
          top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: ready
                  ? () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: PremiumTheme.neonGreen,
                        content: const Text('Lineup submitted!',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ));
                      Navigator.of(context).pop();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.neonGreen,
                disabledBackgroundColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
                disabledForegroundColor:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                foregroundColor: Colors.black,
                elevation: ready ? 4 : 0,
                shadowColor: PremiumTheme.neonGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (ready) ...[
                  const Icon(Icons.check_circle_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  ready ? 'SUBMIT LINEUP' : 'SELECT ${11 - _selected.length} MORE PLAYERS',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── FORMATIONS ───────────────────────────────────────────────────────────────

  List<Offset> _positionsFor(String formation) {
    switch (formation) {
      case '4-4-2':
        return const [
          Offset(0.5, 0.91),
          Offset(0.15, 0.73), Offset(0.38, 0.73), Offset(0.62, 0.73), Offset(0.85, 0.73),
          Offset(0.15, 0.50), Offset(0.38, 0.50), Offset(0.62, 0.50), Offset(0.85, 0.50),
          Offset(0.33, 0.22), Offset(0.67, 0.22),
        ];
      case '4-2-3-1':
        return const [
          Offset(0.5, 0.91),
          Offset(0.15, 0.74), Offset(0.38, 0.74), Offset(0.62, 0.74), Offset(0.85, 0.74),
          Offset(0.33, 0.57), Offset(0.67, 0.57),
          Offset(0.18, 0.36), Offset(0.5, 0.36), Offset(0.82, 0.36),
          Offset(0.5, 0.14),
        ];
      case '3-5-2':
        return const [
          Offset(0.5, 0.91),
          Offset(0.25, 0.73), Offset(0.5, 0.73), Offset(0.75, 0.73),
          Offset(0.1, 0.52), Offset(0.3, 0.52), Offset(0.5, 0.52), Offset(0.7, 0.52), Offset(0.9, 0.52),
          Offset(0.33, 0.22), Offset(0.67, 0.22),
        ];
      case '4-3-3':
      default:
        return const [
          Offset(0.5, 0.91),
          Offset(0.15, 0.73), Offset(0.38, 0.73), Offset(0.62, 0.73), Offset(0.85, 0.73),
          Offset(0.25, 0.50), Offset(0.5, 0.50), Offset(0.75, 0.50),
          Offset(0.18, 0.20), Offset(0.5, 0.14), Offset(0.82, 0.20),
        ];
    }
  }

  List<String> _positionLabels(String formation) {
    switch (formation) {
      case '4-4-2':
        return ['GK', 'LB', 'CB', 'CB', 'RB', 'LM', 'CM', 'CM', 'RM', 'ST', 'ST'];
      case '4-2-3-1':
        return ['GK', 'LB', 'CB', 'CB', 'RB', 'DM', 'DM', 'LW', 'AM', 'RW', 'ST'];
      case '3-5-2':
        return ['GK', 'CB', 'CB', 'CB', 'LWB', 'CM', 'CM', 'CM', 'RWB', 'ST', 'ST'];
      case '4-3-3':
      default:
        return ['GK', 'LB', 'CB', 'CB', 'RB', 'CM', 'CM', 'CM', 'LW', 'ST', 'RW'];
    }
  }
}

// ── HELPERS ──────────────────────────────────────────────────────────────────

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
  final String posLabel;
  final Color posColor;

  const _PitchSlot({this.player, required this.posLabel, required this.posColor});

  @override
  Widget build(BuildContext context) {
    final filled = player != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: filled
                ? LinearGradient(colors: [posColor, posColor.withValues(alpha: 0.7)])
                : null,
            color: filled ? null : Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: filled ? posColor : Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: filled
                ? [BoxShadow(color: posColor.withValues(alpha: 0.45), blurRadius: 10, spreadRadius: 1)]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            filled ? '${player!.number}' : '+',
            style: TextStyle(
              color: filled ? Colors.black : Colors.white.withValues(alpha: 0.7),
              fontSize: filled ? 14 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: (filled ? posColor : Colors.white).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            filled ? player!.position : posLabel,
            style: TextStyle(
              color: filled ? posColor : Colors.white.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(14)), stroke);

    // Halfway line
    canvas.drawLine(Offset(rect.left, size.height / 2), Offset(rect.right, size.height / 2), stroke);

    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.11, stroke);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 3,
        Paint()..color = Colors.white.withValues(alpha: 0.4));

    // Penalty boxes
    final bW = size.width * 0.55;
    final bH = size.height * 0.14;
    canvas.drawRect(Rect.fromLTWH((size.width - bW) / 2, rect.top, bW, bH), stroke);
    canvas.drawRect(Rect.fromLTWH((size.width - bW) / 2, rect.bottom - bH, bW, bH), stroke);

    // Goal areas
    final gW = size.width * 0.28;
    final gH = size.height * 0.06;
    canvas.drawRect(Rect.fromLTWH((size.width - gW) / 2, rect.top, gW, gH), stroke);
    canvas.drawRect(Rect.fromLTWH((size.width - gW) / 2, rect.bottom - gH, gW, gH), stroke);

    // Corner arcs
    final cornerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (final c in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      canvas.drawArc(Rect.fromCenter(center: c, width: 20, height: 20), 0, 3.14 * 2, false, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

