import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../lineups/models/player_lineup_model.dart';

class MatchTacticsBoardScreen extends StatefulWidget {
  final List<PlayerLineupModel> starters;

  const MatchTacticsBoardScreen({
    Key? key,
    required this.starters,
  }) : super(key: key);

  @override
  State<MatchTacticsBoardScreen> createState() => _MatchTacticsBoardScreenState();
}

class _MatchTacticsBoardScreenState extends State<MatchTacticsBoardScreen> {
  late List<PlayerLineupModel> _players;
  String _selectedFormation = '4-4-2';

  // Relative coordinate presets for formations (posX, posY)
  final Map<String, List<Point>> _formationPresets = {
    '4-4-2': [
      Point(0.5, 0.88), // GK
      Point(0.15, 0.70), Point(0.38, 0.72), Point(0.62, 0.72), Point(0.85, 0.70), // DF
      Point(0.15, 0.45), Point(0.38, 0.48), Point(0.62, 0.48), Point(0.85, 0.45), // MF
      Point(0.35, 0.20), Point(0.65, 0.20), // FW
    ],
    '4-3-3': [
      Point(0.5, 0.88), // GK
      Point(0.15, 0.70), Point(0.38, 0.72), Point(0.62, 0.72), Point(0.85, 0.70), // DF
      Point(0.25, 0.48), Point(0.50, 0.52), Point(0.75, 0.48), // MF
      Point(0.20, 0.22), Point(0.50, 0.18), Point(0.80, 0.22), // FW
    ],
    '3-5-2': [
      Point(0.5, 0.88), // GK
      Point(0.25, 0.72), Point(0.50, 0.75), Point(0.75, 0.72), // DF
      Point(0.15, 0.48), Point(0.32, 0.50), Point(0.50, 0.53), Point(0.68, 0.50), Point(0.85, 0.48), // MF
      Point(0.35, 0.20), Point(0.65, 0.20), // FW
    ],
  };

  @override
  void initState() {
    super.initState();
    // Clone starting players list to avoid modifying the original list prematurely
    _players = widget.starters.map((p) => PlayerLineupModel(
      id: p.id,
      name: p.name,
      position: p.position,
      isStarting: p.isStarting,
      jerseyNumber: p.jerseyNumber,
      posX: p.posX,
      posY: p.posY,
    )).toList();

    // If coordinates are not set, apply the default 4-4-2 layout
    if (_players.isNotEmpty && _players.every((p) => p.posX == null || p.posY == null)) {
      _applyPreset('4-4-2');
    }
  }

  void _applyPreset(String formation) {
    final preset = _formationPresets[formation];
    if (preset == null || _players.isEmpty) return;

    setState(() {
      _selectedFormation = formation;
      
      // Auto-assign positions based on indices:
      // Group players by GK, then DF, MF, FW to match preset coordinates layout
      final gks = _players.where((p) => p.position == 'GK').toList();
      final dfs = _players.where((p) => p.position == 'DF').toList();
      final mfs = _players.where((p) => p.position == 'MF').toList();
      final fws = _players.where((p) => p.position == 'FW').toList();
      final rest = _players.where((p) => !['GK', 'DF', 'MF', 'FW'].contains(p.position)).toList();

      final sortedList = [...gks, ...dfs, ...mfs, ...fws, ...rest];
      
      for (int i = 0; i < sortedList.length; i++) {
        if (i < preset.length) {
          final p = sortedList[i];
          // Find reference in _players and update coordinates
          final target = _players.firstWhere((element) => element.id == p.id);
          target.posX = preset[i].x;
          target.posY = preset[i].y;
          
          // Sync position role based on preset zone
          if (i == 0) {
            target.position = 'GK';
          } else if (formation == '3-5-2') {
            if (i >= 1 && i <= 3) target.position = 'DF';
            if (i >= 4 && i <= 8) target.position = 'MF';
            if (i >= 9) target.position = 'FW';
          } else if (formation == '4-4-2') {
            if (i >= 1 && i <= 4) target.position = 'DF';
            if (i >= 5 && i <= 8) target.position = 'MF';
            if (i >= 9) target.position = 'FW';
          } else if (formation == '4-3-3') {
            if (i >= 1 && i <= 4) target.position = 'DF';
            if (i >= 5 && i <= 7) target.position = 'MF';
            if (i >= 8) target.position = 'FW';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Доска тактики',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _players);
            },
            child: const Text(
              'Готово',
              style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _players.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer_rounded, size: 64, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет игроков стартового состава',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Сначала выберите игроков стартового состава на предыдущем экране',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Preset Selector Chips
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['4-4-2', '4-3-3', '3-5-2'].map((f) {
                      final bool active = _selectedFormation == f;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            f,
                            style: TextStyle(
                              color: active ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: active,
                          selectedColor: const Color(0xFF00E676),
                          backgroundColor: const Color(0xFF1E2640),
                          onSelected: (selected) {
                            if (selected) _applyPreset(f);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Text(
                    'Перетащите игроков пальцем по полю, чтобы настроить тактическую расстановку',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),

                // Interactive Soccer Pitch Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final double doubleHeight = constraints.maxHeight;

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3516), Color(0xFF0D1D09)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // 1. Soccer Pitch Markings (White lines)
                              Positioned(
                                left: 0, right: 0, top: doubleHeight / 2,
                                child: Container(height: 1.5, color: Colors.white.withOpacity(0.15)),
                              ),
                              Center(
                                child: Container(
                                  width: w * 0.26,
                                  height: w * 0.26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                                  ),
                                ),
                              ),
                              // Penalty area (Top)
                              Positioned(
                                top: 0,
                                left: w * 0.2,
                                right: w * 0.2,
                                height: doubleHeight * 0.15,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              // Goal area (Top)
                              Positioned(
                                top: 0,
                                left: w * 0.35,
                                right: w * 0.35,
                                height: doubleHeight * 0.05,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      bottom: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              // Penalty area (Bottom)
                              Positioned(
                                bottom: 0,
                                left: w * 0.2,
                                right: w * 0.2,
                                height: doubleHeight * 0.15,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              // Goal area (Bottom)
                              Positioned(
                                bottom: 0,
                                left: w * 0.35,
                                right: w * 0.35,
                                height: doubleHeight * 0.05,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      right: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                      top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Render each draggable Player Token
                              ..._players.map((p) {
                                final double rx = p.posX ?? 0.5;
                                final double ry = p.posY ?? 0.5;
                                final double px = rx * w;
                                final double py = ry * doubleHeight;

                                return Positioned(
                                  left: px - 25,
                                  top: py - 25,
                                  width: 50,
                                  height: 65,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        double newX = rx + (details.delta.dx / w);
                                        double newY = ry + (details.delta.dy / doubleHeight);
                                        p.posX = newX.clamp(0.06, 0.94);
                                        p.posY = newY.clamp(0.06, 0.94);
                                      });
                                    },
                                    child: _buildTacticsToken(p),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }

  Widget _buildTacticsToken(PlayerLineupModel p) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: p.position == 'GK' ? Colors.orangeAccent : const Color(0xFF00E676), 
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            p.jerseyNumber != null ? '${p.jerseyNumber}' : '#',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.65),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class Point {
  final double x;
  final double y;
  const Point(this.x, this.y);
}
