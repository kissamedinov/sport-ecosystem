import '../../../../core/api/api_client.dart';
import '../models/club_dashboard.dart';
import '../models/career_record.dart';
import '../models/club_request.dart';
import '../models/invitation.dart';

class ClubRepository {
  final ApiClient _apiClient;

  ClubRepository(this._apiClient);

  Future<ClubDashboard> getClubDashboard(String clubId) async {
    final response = await _apiClient.get('/clubs/$clubId/full-dashboard');
    return ClubDashboard.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getCoachDashboard() async {
    final response = await _apiClient.get('/clubs/coach/dashboard');
    return response.data;
  }

  Future<void> submitClubRequest(Map<String, dynamic> requestData) async {
    await _apiClient.post('/clubs/requests', data: requestData);
  }

  Future<List<ClubRequest>> getAllClubRequests() async {
    final response = await _apiClient.get('/clubs/admin/requests');
    return (response.data as List).map((e) => ClubRequest.fromJson(e)).toList();
  }

  Future<void> approveClubRequest(String requestId) async {
    await _apiClient.post('/clubs/admin/requests/$requestId/approve');
  }

  Future<void> rejectClubRequest(String requestId) async {
    await _apiClient.post('/clubs/admin/requests/$requestId/reject');
  }

  Future<ClubDashboard> getMyClubDashboard() async {
    final response = await _apiClient.get('/clubs/dashboard');
    return ClubDashboard.fromJson(response.data);
  }

  Future<void> sendInvitation(Map<String, dynamic> invitationData) async {
    await _apiClient.post('/clubs/invitations', data: invitationData);
  }

  Future<void> approveInvitation(String invitationId) async {
    await _apiClient.post('/clubs/invitations/$invitationId/approve');
  }

  Future<List<Invitation>> getMyInvitations() async {
    final response = await _apiClient.get('/clubs/invitations/my');
    return (response.data as List).map((e) => Invitation.fromJson(e)).toList();
  }

  Future<void> acceptInvitation(String invitationId) async {
    await _apiClient.post('/clubs/invitations/$invitationId/accept');
  }

  Future<void> declineInvitation(String invitationId) async {
    await _apiClient.post('/clubs/invitations/$invitationId/decline');
  }

  Future<void> createChildProfile(Map<String, dynamic> profileData) async {
    await _apiClient.post('/clubs/child-profiles', data: profileData);
  }

  Future<PlayerCareer> getPlayerCareerHistory(String profileId) async {
    final response = await _apiClient.get('/clubs/players/$profileId/career');
    return PlayerCareer.fromJson(response.data);
  }

  Future<void> createAcademyInClub(String clubId, Map<String, dynamic> academyData) async {
    await _apiClient.post('/clubs/$clubId/academies', data: academyData);
  }

  Future<void> createTeamInAcademy(String academyId, Map<String, dynamic> teamData) async {
    await _apiClient.post('/clubs/academies/$academyId/teams', data: teamData);
  }

  Future<void> addPlayerToTeam(String teamId, Map<String, dynamic> playerData) async {
    await _apiClient.post('/clubs/teams/$teamId/players', data: playerData);
  }

  Future<void> addClubStaff(String clubId, Map<String, dynamic> staffData) async {
    await _apiClient.post('/clubs/$clubId/staff', data: staffData);
  }
}
