import 'package:flutter/material.dart';
import '../data/repositories/match_repository.dart';
import '../data/models/match.dart';

class MatchProvider extends ChangeNotifier {
  final MatchRepository _repository;
  List<MatchModel> _matches = [];
  Map<String, dynamic>? _currentMatchSheet;
  bool _isLoading = false;
  String? _error;

  MatchProvider(this._repository);

  List<MatchModel> get matches => _matches;
  Map<String, dynamic>? get currentMatchSheet => _currentMatchSheet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMatches({String? tournamentId}) async {
    _setLoading(true);
    _error = null;
    try {
      _matches = await _repository.getMatches(tournamentId: tournamentId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMatchSheet(String matchId) async {
    _setLoading(true);
    _error = null;
    try {
      _currentMatchSheet = await _repository.getMatchSheet(matchId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitMatchSheet(String matchId, Map<String, dynamic> sheetData) async {
    _setLoading(true);
    try {
      await _repository.submitMatchSheet(matchId, sheetData);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignAward(String tournamentId, Map<String, dynamic> awardData) async {
    _setLoading(true);
    try {
      await _repository.assignTournamentAward(tournamentId, awardData);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitResult(String matchId, Map<String, dynamic> resultData) async {
    _setLoading(true);
    try {
      await _repository.submitResult(matchId, resultData);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addMatchEvent(String matchId, Map<String, dynamic> eventData) async {
    _setLoading(true);
    try {
      await _repository.createMatchEvent(matchId, eventData);
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
