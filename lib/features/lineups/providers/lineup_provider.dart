import 'package:flutter/material.dart';
import '../models/lineup.dart';
import '../repositories/lineup_repository.dart';

class LineupProvider extends ChangeNotifier {
  final LineupRepository _repository = LineupRepository();
  final Map<String, MatchLineup> _lineupsByTeam = {};
  bool _isLoading = false;
  String? _error;

  Map<String, MatchLineup> get lineupsByTeam => _lineupsByTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeamLineup(String matchId, String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final lineup = await _repository.fetchTeamLineup(matchId, teamId);
      if (lineup != null) {
        _lineupsByTeam['$matchId-$teamId'] = lineup;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitLineup(String matchId, MatchLineup lineupRequest) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.submitLineup(matchId, lineupRequest);
      _lineupsByTeam['$matchId-${lineupRequest.teamId}'] = lineupRequest;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  MatchLineup? getLineupForMatch(String matchId, String teamId) {
    return _lineupsByTeam['$matchId-$teamId'];
  }
}
