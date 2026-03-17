import 'package:flutter/material.dart';
import '../data/repositories/tournament_repository.dart';
import '../data/models/tournament.dart';
import '../data/models/tournament_match.dart';
import '../data/models/tournament_standing.dart';
import '../data/models/tournament_team_response.dart';

class TournamentProvider extends ChangeNotifier {
  final TournamentRepository _repository;
  
  List<Tournament> _tournaments = [];
  Tournament? _selectedTournament;
  List<Tournament> _seriesHistory = [];
  List<TournamentMatch> _matches = [];
  List<TournamentStanding> _standings = [];
  List<Map<String, dynamic>> _divisions = [];
  List<Map<String, dynamic>> _playerAwards = [];
  List<TournamentTeamResponse> _registeredTeams = [];
  
  bool _isLoading = false;
  String? _error;

  TournamentProvider(this._repository);

  List<Tournament> get tournaments => _tournaments;
  Tournament? get selectedTournament => _selectedTournament;
  List<Tournament> get seriesHistory => _seriesHistory;
  List<TournamentMatch> get matches => _matches;
  List<TournamentStanding> get standings => _standings;
  List<Map<String, dynamic>> get divisions => _divisions;
  List<Map<String, dynamic>> get playerAwards => _playerAwards;
  List<TournamentTeamResponse> get registeredTeams => _registeredTeams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchTournaments({String? season, int? year}) async {
    _setLoading(true);
    _error = null;
    try {
      _tournaments = await _repository.getTournaments(season: season, year: year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTournament(Map<String, dynamic> tournamentData) async {
    _setLoading(true);
    _error = null;
    try {
      final newTournament = await _repository.createTournament(tournamentData);
      _tournaments.insert(0, newTournament);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchTournamentDetails(String id) async {
    _setLoading(true);
    _error = null;
    _selectedTournament = null;
    _seriesHistory = [];
    _divisions = [];
    try {
      _selectedTournament = await _repository.getTournamentById(id);
      _divisions = await _repository.getDivisions(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTournamentMatches(String tournamentId) async {
    _setLoading(true);
    try {
      _matches = await _repository.getTournamentMatches(tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTournamentStandings(String tournamentId) async {
    _setLoading(true);
    try {
      _standings = await _repository.getTournamentStandings(tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerTeamToDivision(String divisionId, String teamId, String registrationData) async {
    _setLoading(true);
    try {
      await _repository.registerTeamToDivision(divisionId, teamId, registrationData);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchPlayerAwards(String playerId) async {
    _setLoading(true);
    try {
      _playerAwards = await _repository.getPlayerAwards(playerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMatchResult(String matchId, int homeScore, int awayScore) async {
    _setLoading(true);
    try {
      await _repository.updateMatchResult(matchId, homeScore, awayScore);
      if (_selectedTournament != null) {
        await fetchTournamentStandings(_selectedTournament!.id);
        await fetchTournamentMatches(_selectedTournament!.id);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> generateSchedule(String tournamentId) async {
    _setLoading(true);
    try {
      await _repository.generateSchedule(tournamentId);
      await fetchTournamentMatches(tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTournamentTeams(String tournamentId) async {
    _setLoading(true);
    try {
      _registeredTeams = await _repository.getTournamentTeams(tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
}
