import 'package:flutter/material.dart';
import '../data/repositories/team_repository.dart';
import '../data/models/team.dart';

class TeamProvider extends ChangeNotifier {
  final TeamRepository _repository;
  List<Team> _teams = [];
  List<Team> _myTeams = [];
  List<Team> _rankings = [];
  bool _isLoading = false;
  String? _error;

  TeamProvider(this._repository);

  List<Team> get teams => _teams;
  List<Team> get myTeams => _myTeams;
  List<Team> get rankings => _rankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTeams() async {
    _setLoading(true);
    _error = null;
    try {
      _teams = await _repository.getTeams();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTeamRankings() async {
    _setLoading(true);
    _error = null;
    try {
      _rankings = await _repository.getTeamRankings();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMyTeams() async {
    _setLoading(true);
    _error = null;
    try {
      _myTeams = await _repository.getMyTeams();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<Team?> fetchTeamById(String id) async {
    _setLoading(true);
    _error = null;
    try {
      final team = await _repository.getTeamById(id);
      return team;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
