import 'package:flutter/material.dart';
import '../data/repositories/tournament_repository.dart';
import '../data/models/tournament.dart';
import '../data/models/tournament_match.dart';
import '../data/models/tournament_standing.dart';
import '../data/models/tournament_team_response.dart';
import '../data/models/tournament_series.dart';

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
  List<TournamentSeries> _seriesList = [];
  TournamentSeriesDetail? _selectedSeriesDetail;
  
  bool _isLoading = false;
  String? _error;
  String? _aiReport;

  TournamentProvider(this._repository);
  TournamentRepository get repository => _repository;

  List<Tournament> get tournaments => _tournaments;
  Tournament? get selectedTournament => _selectedTournament;
  List<Tournament> get seriesHistory => _seriesHistory;
  List<TournamentMatch> get matches => _matches;
  List<TournamentStanding> get standings => _standings;
  List<Map<String, dynamic>> get divisions => _divisions;
  List<Map<String, dynamic>> get playerAwards => _playerAwards;
  List<TournamentTeamResponse> get registeredTeams => _registeredTeams;
  List<TournamentSeries> get seriesList => _seriesList;
  TournamentSeriesDetail? get selectedSeriesDetail => _selectedSeriesDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get aiReport => _aiReport;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchTournaments({String? season, int? year, String? city, bool mine = false}) async {
    _setLoading(true);
    _error = null;
    try {
      _tournaments = await _repository.getTournaments(season: season, year: year, city: city, mine: mine);
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

  Future<bool> updateTournament(String id, Map<String, dynamic> tournamentData) async {
    _setLoading(true);
    _error = null;
    try {
      final updatedTournament = await _repository.updateTournament(id, tournamentData);
      final index = _tournaments.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tournaments[index] = updatedTournament;
      }
      if (_selectedTournament?.id == id) {
        _selectedTournament = updatedTournament;
      }
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

  Future<bool> createDivision(String tournamentId, Map<String, dynamic> divisionData) async {
    _setLoading(true);
    try {
      final dataWithId = {
        ...divisionData,
        'tournament_edition_id': tournamentId,
      };
      await _repository.createDivision(dataWithId);
      await fetchTournamentDetails(tournamentId); // Refresh divisions
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateDivision(String tournamentId, String divisionId, Map<String, dynamic> divisionData) async {
    _setLoading(true);
    try {
      await _repository.updateDivision(divisionId, divisionData);
      await fetchTournamentDetails(tournamentId); // Refresh divisions
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDivision(String tournamentId, String divisionId) async {
    _setLoading(true);
    try {
      await _repository.deleteDivision(divisionId);
      await fetchTournamentDetails(tournamentId); // Refresh divisions
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
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

  Future<bool> updateMatchResult(String matchId, int homeScore, int awayScore, {int? homePenaltyScore, int? awayPenaltyScore}) async {
    _setLoading(true);
    try {
      await _repository.updateMatchResult(
        matchId, 
        homeScore, 
        awayScore, 
        homePenaltyScore: homePenaltyScore, 
        awayPenaltyScore: awayPenaltyScore
      );
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
    _aiReport = null;
    try {
      final result = await _repository.generateSchedule(tournamentId);
      _aiReport = result['ai_report'];
      await fetchTournamentMatches(tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> finalizeSchedule(String tournamentId) async {
    _setLoading(true);
    try {
      await _repository.finalizeSchedule(tournamentId);
      await fetchTournamentMatches(tournamentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> swapTeams(String tournamentId, String teamAId, String teamBId) async {
    _setLoading(true);
    try {
      await _repository.swapTeams(tournamentId, teamAId, teamBId);
      await fetchTournamentMatches(tournamentId);
      await fetchTournamentStandings(tournamentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> drawGroups(String tournamentId, int numGroups, Map<String, List<String>> assignments) async {
    _setLoading(true);
    try {
      await _repository.drawGroups(tournamentId, numGroups, assignments);
      await fetchTournamentStandings(tournamentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
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

  Future<bool> updateTeamStatus(String tournamentId, String teamId, String? status, {String? registrationData}) async {
    _setLoading(true);
    try {
      await _repository.updateTournamentTeamStatus(tournamentId, teamId, status, registrationData: registrationData);
      await fetchTournamentTeams(tournamentId);
      await fetchTournamentStandings(tournamentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMatchDetails(String tournamentId, String matchId, Map<String, dynamic> details) async {
    _setLoading(true);
    try {
      await _repository.updateMatchDetails(matchId, details);
      await fetchTournamentMatches(tournamentId);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchTournamentSeries() async {
    _setLoading(true);
    _error = null;
    try {
      _seriesList = await _repository.getTournamentSeries();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTournamentSeriesDetail(String seriesId) async {
    _setLoading(true);
    _error = null;
    _selectedSeriesDetail = null;
    try {
      _selectedSeriesDetail = await _repository.getTournamentSeriesDetail(seriesId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTournamentSeries({
    required String name,
    required String city,
    String? description,
    String? logoUrl,
    required String organizerId,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.createTournamentSeries({
        'name': name,
        'city': city,
        'description': description,
        'logo_url': logoUrl,
        'organizer_id': organizerId,
      });
      await fetchTournamentSeries();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateTournamentSeries({
    required String id,
    String? name,
    String? city,
    String? description,
    String? logoUrl,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _repository.updateTournamentSeries(id, {
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (description != null) 'description': description,
        if (logoUrl != null) 'logo_url': logoUrl,
      });
      if (_selectedSeriesDetail != null && _selectedSeriesDetail!.id == id) {
        await fetchTournamentSeriesDetail(id);
      }
      await fetchTournamentSeries();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
