import 'package:flutter/material.dart';
import '../data/models/tournament_squad_member.dart';
import '../data/repositories/tournament_squad_repository.dart';
import '../data/repositories/tournament_repository.dart';

class TournamentSquadProvider extends ChangeNotifier {
  final TournamentSquadRepository _squadRepository;
  final TournamentRepository _tournamentRepository;

  List<TournamentSquadMember> _squad = [];
  bool _isLoading = false;
  String? _error;

  TournamentSquadProvider(this._squadRepository, this._tournamentRepository);

  List<TournamentSquadMember> get squad => _squad;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSquad(String tournamentTeamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _squad = await _squadRepository.getSquad(tournamentTeamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToSquad(String tournamentTeamId, List<Map<String, dynamic>> players) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _squadRepository.addToSquad(tournamentTeamId, players);
      await fetchSquad(tournamentTeamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromSquad(String tournamentTeamId, String childProfileId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _squadRepository.removeFromSquad(tournamentTeamId, childProfileId);
      _squad.removeWhere((m) => m.childProfileId == childProfileId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitLineup(String matchId, String teamId, List<Map<String, dynamic>> players) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _tournamentRepository.submitMatchSheet({
        'match_id': matchId,
        'team_id': teamId,
        'players': players,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
