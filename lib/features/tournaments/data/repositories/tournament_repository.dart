import '../../../../core/api/api_client.dart';
import '../models/tournament.dart';
import '../models/tournament_match.dart';
import '../models/tournament_standing.dart';
import '../models/tournament_team_response.dart';

class TournamentRepository {
  final ApiClient _apiClient;

  TournamentRepository(this._apiClient);

  Future<List<Tournament>> getTournaments({String? season, int? year, int page = 1, int limit = 10}) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'limit': limit,
    };
    if (season != null) queryParams['season'] = season;
    if (year != null) queryParams['year'] = year.toString();

    final response = await _apiClient.get('/tournaments', queryParameters: queryParams);
    
    final List<dynamic> data = response.data;
    return data.map((json) => Tournament.fromJson(json)).toList();
  }

  Future<Tournament> createTournament(Map<String, dynamic> tournamentData) async {
    final response = await _apiClient.post('/tournaments', data: tournamentData);
    return Tournament.fromJson(response.data);
  }

  Future<Tournament> getTournamentById(String id) async {
    final response = await _apiClient.get('/tournaments/$id');
    return Tournament.fromJson(response.data);
  }

  Future<List<Map<String, dynamic>>> getDivisions(String editionId) async {
    final response = await _apiClient.get('/tournaments/$editionId/divisions');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<TournamentTeamResponse> registerTeamToDivision(String divisionId, String teamId, String registrationData) async {
    final response = await _apiClient.post(
      '/tournaments/divisions/$divisionId/register-team', 
      queryParameters: {'team_id': teamId},
      data: registrationData,
    );
    return TournamentTeamResponse.fromJson(response.data);
  }

  Future<List<Map<String, dynamic>>> getPlayerAwards(String playerId) async {
    final response = await _apiClient.get('/tournaments/player/$playerId/awards');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> assignAward(Map<String, dynamic> awardData) async {
    final response = await _apiClient.post('/tournaments/awards', data: awardData);
    return response.data;
  }

  Future<List<TournamentMatch>> getTournamentMatches(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/matches');
    final List<dynamic> data = response.data;
    return data.map((json) => TournamentMatch.fromJson(json)).toList();
  }

  Future<List<TournamentStanding>> getTournamentStandings(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/standings');
    final List<dynamic> data = response.data;
    return data.map((json) => TournamentStanding.fromJson(json)).toList();
  }

  Future<TournamentMatch> updateMatchResult(String matchId, int homeScore, int awayScore) async {
    final response = await _apiClient.patch('/tournaments/matches/$matchId/result', queryParameters: {
      'home_score': homeScore,
      'away_score': awayScore,
    });
    return TournamentMatch.fromJson(response.data);
  }

  Future<void> generateSchedule(String tournamentId) async {
    await _apiClient.post('/tournaments/$tournamentId/generate-schedule');
  }

  Future<void> submitMatchSheet(Map<String, dynamic> sheetData) async {
    await _apiClient.post('/tournaments/match-sheets', data: sheetData);
  }

  Future<List<TournamentTeamResponse>> getTournamentTeams(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/teams');
    final List<dynamic> data = response.data;
    return data.map((json) => TournamentTeamResponse.fromJson(json)).toList();
  }
}
