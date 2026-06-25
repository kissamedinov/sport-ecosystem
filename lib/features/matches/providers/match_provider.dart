import 'package:flutter/material.dart';
import '../data/repositories/match_repository.dart';
import '../data/models/match.dart';
import '../data/models/match_event.dart';

class MatchProvider extends ChangeNotifier {
  final MatchRepository _repository;
  List<MatchModel> _matches = [];
  List<MatchEvent> _currentMatchEvents = [];
  Map<String, dynamic>? _currentMatchSheet;
  bool _isLoading = false;
  String? _error;

  MatchProvider(this._repository);

  List<MatchModel> get matches => _matches;
  List<MatchEvent> get currentMatchEvents => _currentMatchEvents;
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

  Future<void> fetchMatchEvents(String matchId) async {
    _setLoading(true);
    _error = null;
    try {
      final List<dynamic> data = await _repository.getMatchEvents(matchId);
      _currentMatchEvents = data.map((json) => MatchEvent.fromJson(json)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addMatchEvent(String matchId, Map<String, dynamic> eventData) async {
    _setLoading(true);
    try {
      await _repository.createMatchEvent(matchId, eventData);
      await fetchMatchEvents(matchId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteMatchEvent(String matchId, String eventId) async {
    _setLoading(true);
    try {
      await _repository.deleteMatchEvent(eventId);
      await fetchMatchEvents(matchId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMatchStatus(String matchId, String status) async {
    _setLoading(true);
    try {
      await _repository.updateMatchStatus(matchId, status);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
