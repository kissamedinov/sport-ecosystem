import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/core/api/stats_api_service.dart';
import 'package:mobile/core/theme/premium_theme.dart';

import 'package:mobile/features/lineups/models/lineup.dart';
import 'package:mobile/features/lineups/repositories/lineup_repository.dart';

class LiveMatchScreen extends StatefulWidget {
  final String matchId;
  final String teamId;
  final String homeTeamName;
  final String awayTeamName;

  const LiveMatchScreen({
    super.key,
    required this.matchId,
    required this.teamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  final StatsApiService _statsApi = StatsApiService();
  final LineupRepository _lineupRepo = LineupRepository();

  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  int _homeScore = 0;
  int _awayScore = 0;

  MatchLineup? _lineup;
  bool _lineupLoading = true;

  final List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadLineup();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLineup() async {
    final lineup = await _lineupRepo.fetchTeamLineup(widget.matchId, widget.teamId);
    setState(() {
      _lineup = lineup;
      _lineupLoading = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  String get _timeDisplay {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  int get _currentMinute => (_seconds ~/ 60) + 1;

  void _showEventDialog(String eventType, Color color, IconData icon) {
    if (_lineup == null || _lineup!.players.isEmpty) {
      _postEventWithoutPlayer(eventType);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlayerPickerSheet(
        players: _lineup!.players,
        eventType: eventType,
        color: color,
        icon: icon,
        minute: _currentMinute,
        onSelect: (player) => _postEvent(eventType, player),
      ),
    );
  }

  Future<void> _postEventWithoutPlayer(String eventType) async {
    try {
      await _statsApi.postMatchEvent(widget.matchId, {
        'event_type': eventType,
        'minute': _currentMinute,
        'team_id': widget.teamId,
      });
      setState(() {
        _events.insert(0, {
          'type': eventType,
          'minute': _currentMinute,
          'player': null,
        });
        if (eventType == 'GOAL' || eventType == 'PENALTY_GOAL') _homeScore++;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _postEvent(String eventType, LineupPlayer player) async {
    try {
      await _statsApi.postMatchEvent(widget.matchId, {
        'event_type': eventType,
        'minute': _currentMinute,
        'team_id': widget.teamId,
        if (player.playerId != null) 'player_id': player.playerId,
        if (player.childProfileId != null) 'child_profile_id': player.childProfileId,
      });
      setState(() {
        _events.insert(0, {
          'type': eventType,
          'minute': _currentMinute,
          'player': player,
        });
        if (eventType == 'GOAL' || eventType == 'PENALTY_GOAL') _homeScore++;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submitResult() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceCard(context),
        title: const Text('SUBMIT FINAL RESULT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
        content: Text(
          'Final score: $_homeScore - $_awayScore\n\nThis cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUBMIT', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _statsApi.submitMatchResult(widget.matchId, _homeScore, _awayScore);
      _timer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Result submitted!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('LIVE MATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: _submitResult,
            child: const Text('SUBMIT', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScoreboard(),
          const SizedBox(height: 16),
          _buildEventButtons(),
          const SizedBox(height: 16),
          _buildScoreAdjust(),
          const Divider(color: Colors.white12, height: 32),
          Expanded(child: _buildEventFeed()),
        ],
      ),
    );
  }

  Widget _buildScoreboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  widget.homeTeamName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text('$_homeScore', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—', style: TextStyle(color: Colors.white38, fontSize: 32)),
                    ),
                    Text('$_awayScore', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  widget.awayTeamName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _toggleTimer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: _isRunning
                    ? Colors.redAccent.withValues(alpha: 0.15)
                    : PremiumTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isRunning
                      ? Colors.redAccent.withValues(alpha: 0.3)
                      : PremiumTheme.neonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isRunning ? Colors.redAccent : PremiumTheme.neonGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeDisplay,
                    style: TextStyle(
                      color: _isRunning ? Colors.redAccent : PremiumTheme.neonGreen,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventButtons() {
    if (_lineupLoading) {
      return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2));
    }
    final events = [
      {'type': 'GOAL', 'label': 'GOAL', 'icon': Icons.sports_soccer_rounded, 'color': PremiumTheme.neonGreen},
      {'type': 'YELLOW_CARD', 'label': 'YELLOW', 'icon': Icons.square_rounded, 'color': Colors.amber},
      {'type': 'RED_CARD', 'label': 'RED', 'icon': Icons.square_rounded, 'color': Colors.redAccent},
      {'type': 'ASSIST', 'label': 'ASSIST', 'icon': Icons.transfer_within_a_station_rounded, 'color': PremiumTheme.electricBlue},
      {'type': 'SAVE', 'label': 'SAVE', 'icon': Icons.front_hand_rounded, 'color': Colors.purpleAccent},
      {'type': 'PENALTY_GOAL', 'label': 'PENALTY', 'icon': Icons.sports_soccer_rounded, 'color': Colors.orangeAccent},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: events.map((e) {
          final color = e['color'] as Color;
          return GestureDetector(
            onTap: () => _showEventDialog(e['type'] as String, color, e['icon'] as IconData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(e['icon'] as IconData, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    e['label'] as String,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreAdjust() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildScoreButton(widget.homeTeamName, _homeScore,
              onAdd: () => setState(() => _homeScore++),
              onRemove: () => setState(() { if (_homeScore > 0) _homeScore--; }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildScoreButton(widget.awayTeamName, _awayScore,
              onAdd: () => setState(() => _awayScore++),
              onRemove: () => setState(() { if (_awayScore > 0) _awayScore--; }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton(String team, int score, {required VoidCallback onAdd, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: onRemove, icon: const Icon(Icons.remove_rounded, color: Colors.white54, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          Text(team.length > 8 ? '${team.substring(0, 8)}…' : team, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
          IconButton(onPressed: onAdd, icon: const Icon(Icons.add_rounded, color: PremiumTheme.neonGreen, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildEventFeed() {
    if (_events.isEmpty) {
      return Center(
        child: Text('No events yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, letterSpacing: 1)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _events.length,
      itemBuilder: (context, i) {
        final ev = _events[i];
        final type = ev['type'] as String;
        final minute = ev['minute'] as int;
        final player = ev['player'] as LineupPlayer?;

        final (icon, color) = _eventStyle(type);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player != null
                    ? '#${player.jerseyNumber ?? '?'} — ${type.replaceAll('_', ' ')}'
                    : type.replaceAll('_', ' '),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Text("$minute'", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _eventStyle(String type) {
    return switch (type) {
      'GOAL' => (Icons.sports_soccer_rounded, PremiumTheme.neonGreen),
      'PENALTY_GOAL' => (Icons.sports_soccer_rounded, Colors.orangeAccent),
      'YELLOW_CARD' => (Icons.square_rounded, Colors.amber),
      'RED_CARD' => (Icons.square_rounded, Colors.redAccent),
      'ASSIST' => (Icons.transfer_within_a_station_rounded, PremiumTheme.electricBlue),
      'SAVE' => (Icons.front_hand_rounded, Colors.purpleAccent),
      _ => (Icons.circle, Colors.white38),
    };
  }
}

class _PlayerPickerSheet extends StatelessWidget {
  final List<LineupPlayer> players;
  final String eventType;
  final Color color;
  final IconData icon;
  final int minute;
  final void Function(LineupPlayer) onSelect;

  const _PlayerPickerSheet({
    required this.players,
    required this.eventType,
    required this.color,
    required this.icon,
    required this.minute,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final starters = players.where((p) => p.isStarting).toList();
    final subs = players.where((p) => !p.isStarting).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                "${eventType.replaceAll('_', ' ')}  •  ${minute}'",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Select player', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 16),
          if (starters.isNotEmpty) ...[
            Text('STARTERS', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ..._buildPlayerTiles(context, starters, color),
          ],
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('SUBSTITUTES', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            ..._buildPlayerTiles(context, subs, color),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildPlayerTiles(BuildContext context, List<LineupPlayer> list, Color color) {
    return list.map((p) {
      final jersey = p.jerseyNumber?.toString() ?? '?';
      final position = p.position ?? '';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(jersey, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
        title: Text(
          position.isNotEmpty ? position : 'Player #$jersey',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onTap: () => onSelect(p),
      );
    }).toList();
  }
}
