import 'package:flutter/material.dart';
import '../data/repositories/academy_repository.dart';
import '../data/models/academy.dart';
import '../data/models/academy_team.dart';

class AcademyProvider extends ChangeNotifier {
  final AcademyRepository _repository;
  List<Academy> _academies = [];
  Academy? _myAcademy;
  List<AcademyTeam> _teams = [];
  List<AcademyPlayer> _players = [];
  List<TrainingSession> _sessions = [];
  bool _isLoading = false;
  String? _error;

  AcademyProvider(this._repository);

  List<AcademyTeamPlayer> _teamPlayers = [];

  List<Academy> get academies => _academies;
  Academy? get myAcademy => _myAcademy;
  List<AcademyTeam> get teams => _teams;
  List<AcademyPlayer> get players => _players;
  List<AcademyTeamPlayer> get teamPlayers => _teamPlayers;
  List<TrainingSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeamPlayers(String teamId) async {
    _setLoading(true);
    try {
      _teamPlayers = await _repository.getTeamPlayers(teamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPlayerToTeam(String teamId, String playerProfileId, {String? position, int? jerseyNumber}) async {
    _setLoading(true);
    try {
      await _repository.addPlayerToTeam(teamId, {
        'player_profile_id': playerProfileId,
        'position': position,
        'jersey_number': jerseyNumber,
      });
      await fetchTeamPlayers(teamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAcademies() async {
    _setLoading(true);
    _error = null;
    try {
      _academies = await _repository.getAcademies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyAcademy() async {
    _setLoading(true);
    _error = null;
    try {
      _myAcademy = await _repository.getMyAcademy();
      if (_myAcademy != null) {
        await Future.wait([
          fetchAcademyTeams(_myAcademy!.id),
          fetchAcademyPlayers(_myAcademy!.id),
          fetchTrainingSessions(_myAcademy!.id),
        ]);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAcademyTeams(String academyId) async {
    try {
      _teams = await _repository.getAcademyTeams(academyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> fetchAcademyPlayers(String academyId) async {
    try {
      _players = await _repository.getAcademyPlayers(academyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> fetchTrainingSessions(String academyId) async {
    try {
      _sessions = await _repository.getTrainingSessions(academyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> createTeam(String academyId, String name, String ageGroup, String coachId) async {
    _setLoading(true);
    try {
      await _repository.createAcademyTeam(academyId, {
        'name': name,
        'age_group': ageGroup,
        'coach_id': coachId,
      });
      await fetchAcademyTeams(academyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
