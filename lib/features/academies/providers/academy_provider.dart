import 'package:flutter/material.dart';
import '../data/repositories/academy_repository.dart';
import '../data/models/academy.dart';
import '../data/models/academy_team.dart' hide AcademyPlayer, TrainingSession;

class AcademyProvider extends ChangeNotifier {
  final AcademyRepository _repository;
  
  Academy? _myAcademy;
  final List<Academy> _academies = [];
  List<AcademyTeam> _teams = [];
  List<AcademyPlayer> _players = [];
  List<TrainingSession> _sessions = [];
  List<AcademyTeamPlayer> _teamPlayers = [];
  bool _isLoading = false;
  String? _error;

  AcademyProvider(this._repository);

  Academy? get myAcademy => _myAcademy;
  List<Academy> get academies => _academies;
  List<AcademyTeam> get teams => _teams;
  List<AcademyPlayer> get players => _players;
  List<TrainingSession> get sessions => _sessions;
  List<AcademyTeamPlayer> get teamPlayers => _teamPlayers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyAcademy() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _myAcademy = await _repository.getMyAcademy();
      if (_myAcademy != null) {
        await fetchAcademyTeams(_myAcademy!.id);
        await fetchAcademyPlayers(_myAcademy!.id);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<void> fetchSessions(String academyId, {String? teamId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _sessions = await _repository.getTrainingSessions(academyId, teamId: teamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeamPlayers(String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _teamPlayers = await _repository.getTeamPlayers(teamId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> recordAttendance(String sessionId, Map<String, String> attendance) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.recordTrainingAttendance({
        'session_id': sessionId,
        'attendance': attendance,
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSession(String academyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createTrainingSession(academyId, data);
      await fetchSessions(academyId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTeam(String academyId, String name, String ageGroup, String level) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createAcademyTeam(academyId, {
        'name': name,
        'age_group': ageGroup,
        'level': level,
      });
      await fetchAcademyTeams(academyId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPlayerToTeam(String teamId, String playerName, String position, String jerseyNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addPlayerToTeam(teamId, {
        'full_name': playerName,
        'position': position,
        'jersey_number': jerseyNumber,
      });
      await fetchTeamPlayers(teamId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinAcademyForPlayer(String academyId, String playerProfileId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.addPlayerToAcademy(academyId, {
        'player_profile_id': playerProfileId,
        'status': 'ACTIVE',
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
