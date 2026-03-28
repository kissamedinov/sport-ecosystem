import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/tournament.dart';
import '../../data/models/tournament_match.dart';
import '../../data/models/tournament_standing.dart';
import '../../data/models/tournament_team_response.dart';
import 'match_lineup_screen.dart';
import 'match_report_screen.dart';
import 'tournament_squad_screen.dart';
import 'tournament_leaderboard_screen.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailsPage({super.key, required this.tournamentId});

  @override
  State<TournamentDetailsPage> createState() => _TournamentDetailsPageState();
}

class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool get _isOrganizer {
    final user = context.read<AuthProvider>().user;
    return user?.roles?.contains('tournament_organizer') == true ||
        user?.roles?.contains('admin') == true;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TournamentProvider>();
      provider.fetchTournamentDetails(widget.tournamentId);
      provider.fetchTournamentMatches(widget.tournamentId);
      provider.fetchTournamentStandings(widget.tournamentId);
      provider.fetchTournamentTeams(widget.tournamentId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TOURNAMENT'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'INFO'),
            Tab(text: 'MATCHES'),
            Tab(text: 'STANDINGS'),
          ],
          indicatorColor: Colors.orangeAccent,
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedTournament == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.selectedTournament == null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final tournament = provider.selectedTournament;
          if (tournament == null) {
            return const Center(child: Text('Tournament not found'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(tournament, provider),
              _buildMatchesTab(provider.matches, provider),
              _buildStandingsTab(provider.standings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTab(Tournament tournament, TournamentProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tournament),
          const SizedBox(height: 24),
          if (provider.divisions.isNotEmpty) ...[
            const Text('Age Divisions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...provider.divisions.map((d) => _buildDivisionCard(d, provider)),
            const SizedBox(height: 24),
          ],
          _buildInfoSection(tournament),
          const SizedBox(height: 24),
          _buildScheduleSettings(tournament),
        ],
      ),
    );
  }
  Widget _buildDivisionCard(Map<String, dynamic> division, TournamentProvider provider) {
    final birthYear = division['birth_year'];
    final name = division['name'];
    
    // Check if any of user's teams are in this division
    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    
    TournamentTeamResponse? myRegisteredTeam;
    try {
      myRegisteredTeam = provider.registeredTeams.firstWhere(
        (rt) => rt.id == division['id'] && myTeamIds.contains(rt.teamId)
      );
    } catch (_) {
      // Not found in this specific division, check by team ID in general for this tournament
      try {
        myRegisteredTeam = provider.registeredTeams.firstWhere(
          (rt) => myTeamIds.contains(rt.teamId)
        );
      } catch (_) {}
    }

    final registeredTeam = myRegisteredTeam;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Birth Year Requirement: $birthYear'),
        trailing: registeredTeam != null
          ? ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentSquadScreen(
                      tournamentTeamId: registeredTeam.id,
                      teamId: registeredTeam.teamId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('MANAGE SQUAD'),
            )
          : ElevatedButton(
              onPressed: () => _showRegisterTeamDialog(context, division['id'], birthYear),
              child: const Text('REGISTER'),
            ),
      ),
    );
  }

  void _showRegisterTeamDialog(BuildContext context, String divisionId, int requiredBirthYear) {
    final teamProvider = context.read<TeamProvider>();
    final tournamentProvider = context.read<TournamentProvider>();

    teamProvider.fetchMyTeams();

    showDialog(
      context: context,
      builder: (context) => Consumer<TeamProvider>(
        builder: (context, tp, _) {
          return AlertDialog(
            title: const Text('Register for Division'),
            content: tp.isLoading 
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : tp.myTeams.isEmpty
                ? const Text('No teams found.')
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tp.myTeams.length,
                      itemBuilder: (context, index) {
                        final team = tp.myTeams[index];
                        final isEligible = team.birthYear == requiredBirthYear;
                        
                        return ListTile(
                          title: Text(team.name),
                          subtitle: Text('Team Birth Year: ${team.birthYear ?? 'Unknown'}'),
                          trailing: isEligible 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.error_outline, color: Colors.red),
                          enabled: isEligible,
                          onTap: () async {
                            final success = await tournamentProvider.registerTeamToDivision(
                              divisionId, 
                              team.id, 
                              '{"source": "mobile_app"}'
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success 
                                    ? 'Registration submitted!' 
                                    : 'Failed: ${tournamentProvider.error}'),
                                  backgroundColor: success ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(Tournament t) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, size: 48, color: Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(t.location, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${t.startDate} - ${t.endDate}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Tournament t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tournament Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildInfoTile(Icons.format_list_bulleted, 'Format', t.format),
              _buildInfoTile(Icons.terrain, 'Surface', t.surfaceType ?? 'Grass'),
              _buildInfoTile(Icons.groups, 'Age Category', t.ageCategory),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleSettings(Tournament t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildInfoTile(Icons.timer, 'Match Duration', '${t.matchHalfDuration}m per half'),
              _buildInfoTile(Icons.coffee, 'Break Duration', '${t.breakBetweenMatches}m between matches'),
              _buildInfoTile(Icons.sports_soccer, 'Fields Available', '${t.numFields}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab(List<TournamentMatch> matches, TournamentProvider provider) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches scheduled yet'));
    }

    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];

        // Find if a coach's registered team plays in this match
        TournamentTeamResponse? myTournamentTeam;
        try {
          myTournamentTeam = provider.registeredTeams.firstWhere(
            (rt) =>
                myTeamIds.contains(rt.teamId) &&
                (rt.teamId == match.homeTeamId || rt.teamId == match.awayTeamId),
          );
        } catch (_) {}

        final memberTeam = myTournamentTeam;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  match.startTime != null
                      ? match.startTime.toString().substring(0, 16)
                      : 'TBD',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Text('Home Team',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('${match.homeScore} - ${match.awayScore}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text('Away Team',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                        if (memberTeam != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchLineupScreen(
                              matchId: match.id,
                              tournamentTeamId: memberTeam.id,
                              teamId: memberTeam.teamId,
                              isHomeTeam:
                                  memberTeam.teamId == match.homeTeamId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.sports_soccer, size: 16),
                      label: const Text('SET LINEUP'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orangeAccent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchReportScreen(
                              matchId: match.id,
                              tournamentId: widget.tournamentId,
                              myTournamentTeamId: memberTeam.id,
                              myTeamId: memberTeam.teamId,
                              isHomeTeam:
                                  memberTeam.teamId == match.homeTeamId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart, size: 16),
                      label: const Text('PLAYER STATS'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.lightBlueAccent),
                    ),
                  ),
                ] else if (_isOrganizer) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchReportScreen(
                              matchId: match.id,
                              tournamentId: widget.tournamentId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.scoreboard, size: 16),
                      label: const Text('REPORT SCORE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStandingsTab(List<TournamentStanding> standings) {
    if (standings.isEmpty) {
      return const Center(child: Text('No standings data available'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentLeaderboardScreen(tournamentId: widget.tournamentId),
                  ),
                );
              },
              icon: const Icon(Icons.leaderboard),
              label: const Text('VIEW ALL-TIME TOP SCORERS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('MP')),
                DataColumn(label: Text('PTS')),
              ],
              rows: standings.map((s) => DataRow(
                cells: [
                  DataCell(Text(s.teamName ?? 'Team ${s.teamId.substring(0, 4)}')),
                  DataCell(Text(s.played.toString())),
                  DataCell(Text(s.points.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.orangeAccent, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
