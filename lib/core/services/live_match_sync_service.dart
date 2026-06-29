import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/stats_api_service.dart';

class LiveMatchState {
  final String id;
  final String status;
  final int homeScore;
  final int awayScore;
  final int elapsedSeconds;
  final bool isTimerRunning;
  final String? timerUpdatedAt;
  final List<dynamic> events;

  LiveMatchState({
    required this.id,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.elapsedSeconds,
    required this.isTimerRunning,
    this.timerUpdatedAt,
    required this.events,
  });

  factory LiveMatchState.fromJson(Map<String, dynamic> json) {
    return LiveMatchState(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'SCHEDULED',
      homeScore: json['home_score'] as int? ?? 0,
      awayScore: json['away_score'] as int? ?? 0,
      elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
      isTimerRunning: json['is_timer_running'] as bool? ?? false,
      timerUpdatedAt: json['timer_updated_at'] as String?,
      events: (json['events'] as List<dynamic>?) ?? [],
    );
  }

  String get timeDisplay {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  int get currentMinute => (elapsedSeconds ~/ 60) + 1;
}

class LiveMatchSyncService extends ChangeNotifier {
  final StatsApiService _statsApi = StatsApiService();
  Timer? _pollingTimer;
  String? _activeMatchId;
  LiveMatchState? _currentState;

  LiveMatchState? get currentState => _currentState;

  void subscribeToMatch(String matchId) {
    if (_activeMatchId == matchId && _pollingTimer != null) return;
    _activeMatchId = matchId;
    _fetchState();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchState();
    });
  }

  void unsubscribe() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _activeMatchId = null;
    _currentState = null;
    notifyListeners();
  }

  Future<void> _fetchState() async {
    if (_activeMatchId == null) return;
    try {
      final json = await _statsApi.getMatchLiveState(_activeMatchId!);
      _currentState = LiveMatchState.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching live match state: $e");
    }
  }

  Future<void> updateTimer({required bool isRunning}) async {
    if (_activeMatchId == null) return;
    try {
      final json = await _statsApi.updateMatchLiveState(_activeMatchId!, {
        'is_timer_running': isRunning,
        'status': 'LIVE',
      });
      _currentState = LiveMatchState.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating timer: $e");
    }
  }

  Future<void> updateScore({int? homeScore, int? awayScore}) async {
    if (_activeMatchId == null) return;
    try {
      final json = await _statsApi.updateMatchLiveState(_activeMatchId!, {
        if (homeScore != null) 'home_score': homeScore,
        if (awayScore != null) 'away_score': awayScore,
      });
      _currentState = LiveMatchState.fromJson(json);
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating score: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
