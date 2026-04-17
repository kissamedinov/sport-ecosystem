import 'package:flutter/material.dart';
import '../data/repositories/academy_repository.dart';
import '../data/models/academy.dart';
import '../data/models/academy_team.dart';
import '../data/models/crm_models.dart';

class AcademyProvider extends ChangeNotifier {
  final AcademyRepository _repository;
  
  Academy? _myAcademy;
  final List<Academy> _academies = [];
  List<AcademyTeam> _teams = [];
  List<AcademyPlayer> _players = [];
  List<TrainingSession> _sessions = [];
  List<AcademyTeamPlayer> _teamPlayers = [];
  List<TrainingSchedule> _schedules = [];
  List<AcademyBranch> _branches = [];
  AcademyBillingConfig? _billingConfig;
  BillingSummary? _currentBillingReport;
  
  bool _isLoading = false;
  String? _error;

  AcademyProvider(this._repository);

  Academy? get myAcademy => _myAcademy;
  List<Academy> get academies => _academies;
  List<AcademyTeam> get teams => _teams;
  List<AcademyPlayer> get players => _players;
  List<TrainingSession> get sessions => _sessions;
  List<AcademyTeamPlayer> get teamPlayers => _teamPlayers;
  List<TrainingSchedule> get schedules => _schedules;
  List<AcademyBranch> get branches => _branches;
  AcademyBillingConfig? get billingConfig => _billingConfig;
  BillingSummary? get currentBillingReport => _currentBillingReport;
  
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
        await fetchSchedules(_myAcademy!.id);
        await fetchBillingConfig(_myAcademy!.id);
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

  // New method for unified attendance lists
  List<AcademyCompositePlayer> _compositePlayers = [];
  List<AcademyCompositePlayer> get compositePlayers => _compositePlayers;

  Future<void> fetchCompositePlayers(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _compositePlayers = await _repository.getCompositeTrainingPlayers(sessionId);
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

  // --- CRM State Management ---

  Future<void> fetchSchedules(String academyId, {String? teamId}) async {
    try {
      await fetchBranches(academyId); // Always refresh branches with schedules
      _schedules = await _repository.getAcademySchedules(academyId, teamId: teamId);
      _sessions = await _repository.getTrainingSessions(academyId, teamId: teamId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> generateSessions(String academyId) async {
    try {
      final now = DateTime.now();
      final oneMonthLater = now.add(const Duration(days: 30));
      await _repository.generateSessions(academyId, now, oneMonthLater);
      await fetchSchedules(academyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createSchedule(String academyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (data.containsKey('schedules')) {
        await _repository.createAcademySchedulesBatch(academyId, (data['schedules'] as List).cast<Map<String, dynamic>>());
      } else {
        await _repository.createAcademySchedule(academyId, data);
      }
      await fetchSchedules(academyId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBranches(String academyId) async {
    try {
      _branches = await _repository.getAcademyBranches(academyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> createBranch(String academyId, String name, String address, String? description) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createAcademyBranch(academyId, {
        'name': name,
        'address': address,
        'description': description,
      });
      await fetchBranches(academyId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> triggerGenerateSessions(String academyId, DateTime start, DateTime end) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.generateSessions(academyId, start, end);
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

  Future<bool> reassignPlayer(String playerProfileId, String targetTeamId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.reassignPlayerTeam(playerProfileId, targetTeamId);
      if (_myAcademy != null) {
        await fetchAcademyPlayers(_myAcademy!.id);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBillingConfig(String academyId) async {
    try {
      _billingConfig = await _repository.getBillingConfig(academyId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> saveBillingConfig(String academyId, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      _billingConfig = await _repository.updateBillingConfig(academyId, data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBillingReport(String academyId, String playerId, int month, int year) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentBillingReport = await _repository.getPlayerBillingReport(academyId, playerId, month, year);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
