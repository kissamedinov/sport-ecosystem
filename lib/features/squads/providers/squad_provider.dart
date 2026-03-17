import 'package:flutter/material.dart';
import '../models/squad.dart';

class SquadProvider extends ChangeNotifier {
  final List<TournamentSquad> _squads = [];
  bool _isLoading = false;

  List<TournamentSquad> get squads => _squads;
  bool get isLoading => _isLoading;

  Future<void> buildSquad(String tournamentId, String teamId, List<String> playerIds) async {
    _isLoading = true;
    notifyListeners();

    // Mock delay
    await Future.delayed(const Duration(seconds: 1));

    final newSquad = TournamentSquad(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tournamentId: tournamentId,
      teamId: teamId,
      coachId: 'current_coach_id',
      createdAt: DateTime.now(),
      playerIds: playerIds,
    );

    _squads.add(newSquad);
    _isLoading = false;
    notifyListeners();
  }

  TournamentSquad? getSquadForTournament(String tournamentId, String teamId) {
    try {
      return _squads.firstWhere((s) => s.tournamentId == tournamentId && s.teamId == teamId);
    } catch (_) {
      return null;
    }
  }
}
