import '../../features/matches/data/models/match_event.dart';
import '../../features/matches/data/models/match_award.dart';
import '../../features/player_stats/data/models/player_stats.dart';
import '../../features/tournaments/data/models/top_scorer.dart';
import 'api_client.dart';

class StatsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<MatchEvent>> getMatchEvents(String matchId) async {
    final response = await _apiClient.get('/matches/$matchId/events');
    return (response.data as List).map((e) => MatchEvent.fromJson(e)).toList();
  }

  Future<List<MatchAward>> getMatchAwards(String matchId) async {
    final response = await _apiClient.get('/matches/$matchId/awards');
    return (response.data as List).map((e) => MatchAward.fromJson(e)).toList();
  }

  Future<PlayerStats> getPlayerStats(String playerId) async {
    final response = await _apiClient.get('/players/$playerId/stats');
    return PlayerStats.fromJson(response.data);
  }

  Future<List<TopScorer>> getTopScorers(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/top-scorers');
    return (response.data as List).map((e) => TopScorer.fromJson(e)).toList();
  }
}
