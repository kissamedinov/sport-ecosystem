import 'package:flutter/material.dart';
import '../data/repositories/match_repository.dart';
import '../data/models/match.dart';

class MatchProvider extends ChangeNotifier {
  final MatchRepository _repository;
  List<MatchModel> _matches = [];
  bool _isLoading = false;
  String? _error;

  MatchProvider(this._repository);

  List<MatchModel> get matches => _matches;
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
