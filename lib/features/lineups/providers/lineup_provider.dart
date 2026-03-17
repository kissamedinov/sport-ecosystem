import 'package:flutter/material.dart';
import '../models/lineup.dart';

class LineupProvider extends ChangeNotifier {
  final List<MatchLineup> _lineups = [];
  bool _isLoading = false;

  List<MatchLineup> get lineups => _lineups;
  bool get isLoading => _isLoading;

  Future<void> submitLineup(String matchId, String teamId, List<LineupPlayer> players) async {
    _isLoading = true;
    notifyListeners();

    // Mock delay
    await Future.delayed(const Duration(seconds: 1));

    final newLineup = MatchLineup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: matchId,
      teamId: teamId,
      coachId: 'current_coach_id',
      createdAt: DateTime.now(),
      players: players,
    );

    _lineups.add(newLineup);
    _isLoading = false;
    notifyListeners();
  }

  MatchLineup? getLineupForMatch(String matchId, String teamId) {
    try {
      return _lineups.firstWhere((l) => l.matchId == matchId && l.teamId == teamId);
    } catch (_) {
      return null;
    }
  }
}
