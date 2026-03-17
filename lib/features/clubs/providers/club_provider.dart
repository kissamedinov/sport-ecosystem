import 'package:flutter/material.dart';
import '../data/repositories/club_repository.dart';
import '../data/models/club_dashboard.dart';
import '../data/models/career_record.dart';
import '../data/models/club_request.dart';
import '../data/models/invitation.dart';

class ClubProvider extends ChangeNotifier {
  final ClubRepository _repository;
  ClubDashboard? _dashboard;
  Map<String, dynamic>? _coachDashboard;
  PlayerCareer? _playerCareer;
  List<ClubRequest> _clubRequests = [];
  List<Invitation> _myInvitations = [];
  bool _isLoading = false;
  String? _error;

  ClubProvider(this._repository);

  ClubDashboard? get dashboard => _dashboard;
  Map<String, dynamic>? get coachDashboard => _coachDashboard;
  PlayerCareer? get playerCareer => _playerCareer;
  List<ClubRequest> get clubRequests => _clubRequests;
  List<Invitation> get myInvitations => _myInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> submitClubRequest(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _repository.submitClubRequest(data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllClubRequests() async {
    _setLoading(true);
    try {
      _clubRequests = await _repository.getAllClubRequests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveClubRequest(String id) async {
    _setLoading(true);
    try {
      await _repository.approveClubRequest(id);
      await fetchAllClubRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchClubDashboard([String? clubId]) async {
    _setLoading(true);
    _error = null;
    try {
      if (clubId != null) {
        _dashboard = await _repository.getClubDashboard(clubId);
      } else {
        _dashboard = await _repository.getMyClubDashboard();
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('404')) {
        _dashboard = null;
        _error = null;
      } else {
        _error = errorStr;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchCoachDashboard() async {
    _setLoading(true);
    _error = null;
    try {
      _coachDashboard = await _repository.getCoachDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyInvitations() async {
    _setLoading(true);
    try {
      _myInvitations = await _repository.getMyInvitations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendInvitation(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _repository.sendInvitation(data);
      await fetchClubDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveInvitation(String id) async {
    _setLoading(true);
    try {
      await _repository.approveInvitation(id);
      await fetchClubDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> acceptInvitation(String id) async {
    _setLoading(true);
    try {
      await _repository.acceptInvitation(id);
      await fetchMyInvitations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> declineInvitation(String id) async {
    _setLoading(true);
    try {
      await _repository.declineInvitation(id);
      await fetchMyInvitations();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createChildProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _repository.createChildProfile(data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectClubRequest(String requestId) async {
    _setLoading(true);
    try {
      await _repository.rejectClubRequest(requestId);
      await fetchAllClubRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createTeam(String academyId, String name, int birthYear, String coachId) async {
    _setLoading(true);
    try {
      await _repository.createTeamInAcademy(academyId, {
        'name': name,
        'birth_year': birthYear,
        'coach_id': coachId,
      });
      if (_dashboard != null) {
        await fetchClubDashboard(_dashboard!.club.id.toString());
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAcademy(String clubId, String name, String city, String address) async {
    _setLoading(true);
    try {
      await _repository.createAcademyInClub(clubId, {
        'name': name,
        'city': city,
        'address': address,
      });
      await fetchClubDashboard(clubId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addPlayerToTeam(String teamId, String playerUserId, int? jerseyNumber) async {
    _setLoading(true);
    try {
      await _repository.addPlayerToTeam(teamId, {
        'invited_user_id': playerUserId,
        'team_id': teamId,
        'jersey_number': jerseyNumber,
        'role': 'PLAYER'
      });
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchPlayerCareer(String profileId) async {
    _setLoading(true);
    _error = null;
    try {
      _playerCareer = await _repository.getPlayerCareerHistory(profileId);
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
