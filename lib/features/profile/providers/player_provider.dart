import 'package:flutter/material.dart';
import '../data/repositories/player_repository.dart';
import '../data/models/player.dart';

class PlayerProvider extends ChangeNotifier {
  final PlayerRepository _repository;
  List<Player> _players = [];
  bool _isLoading = false;
  String? _error;

  PlayerProvider(this._repository);

  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlayers() async {
    _setLoading(true);
    _error = null;
    try {
      _players = await _repository.getPlayers();
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
