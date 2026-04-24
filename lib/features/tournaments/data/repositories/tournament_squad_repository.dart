import '../../../../core/api/api_client.dart';
import '../models/tournament_squad_member.dart';

class TournamentSquadRepository {
  final ApiClient apiClient;

  TournamentSquadRepository(this.apiClient);

  Future<List<TournamentSquadMember>> getSquad(String tournamentTeamId) async {
    final response = await apiClient.get('/tournaments/teams/$tournamentTeamId/squad');
    final List<dynamic> data = response.data;
    return data.map((item) => TournamentSquadMember.fromJson(item)).toList();
  }

  Future<void> addToSquad(String tournamentTeamId, List<Map<String, dynamic>> players) async {
    await apiClient.post(
      '/tournaments/teams/$tournamentTeamId/squad',
      data: {'players': players},
    );
  }

  Future<void> removeFromSquad(String tournamentTeamId, String childProfileId) async {
    await apiClient.delete('/tournaments/teams/$tournamentTeamId/squad/$childProfileId');
  }
}
