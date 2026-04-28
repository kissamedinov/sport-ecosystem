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
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

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
    return user?.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
        user?.roles?.contains('ADMIN') == true;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isOrganizer ? 4 : 3, vsync: this);
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
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TOURNAMENT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: Colors.white38,
          isScrollable: _isOrganizer,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: [
            const Tab(text: 'INFO'),
            const Tab(text: 'MATCHES'),
            const Tab(text: 'STANDINGS'),
            if (_isOrganizer) const Tab(text: 'REQUESTS'),
          ],
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedTournament == null) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null && provider.selectedTournament == null) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white70)));
          }

          final tournament = provider.selectedTournament;
          if (tournament == null) {
            return const Center(child: Text('Tournament not found', style: TextStyle(color: Colors.white38)));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(tournament, provider),
              _buildMatchesTab(provider.matches, provider),
              _buildStandingsTab(provider.standings),
              if (_isOrganizer) _buildRequestsTab(provider.registeredTeams, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTab(Tournament tournament, TournamentProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(tournament),
          const SizedBox(height: 24),
          if (provider.divisions.isNotEmpty) ...[
            _buildSectionTitle('AGE DIVISIONS', Icons.groups),
            const SizedBox(height: 12),
            ...provider.divisions.map((d) => _buildDivisionCard(d, provider)),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('CONFIGURATION', Icons.settings),
          _buildInfoGrid(tournament),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(Tournament t) {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.emoji_events, size: 40, color: PremiumTheme.neonGreen),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.name.toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(t.location, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text('${t.startDate} - ${t.endDate}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PremiumTheme.neonGreen),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDivisionCard(Map<String, dynamic> division, TournamentProvider provider) {
    final birthYear = division['birth_year'];
    final name = division['name'];
    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    
    TournamentTeamResponse? myRegisteredTeam;
    try {
      myRegisteredTeam = provider.registeredTeams.firstWhere(
        (rt) => rt.id == division['id'] && myTeamIds.contains(rt.teamId)
      );
    } catch (_) {
      try {
        myRegisteredTeam = provider.registeredTeams.firstWhere((rt) => myTeamIds.contains(rt.teamId));
      } catch (_) {}
    }

    final registeredTeam = myRegisteredTeam;
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text('Requirement: Born $birthYear', style: const TextStyle(fontSize: 12, color: Colors.white38)),
              ],
            ),
          ),
          if (registeredTeam != null)
            SizedBox(
              height: 36,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
                  foregroundColor: PremiumTheme.neonGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('MANAGE SQUAD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () => _showRegisterTeamDialog(context, division['id'], birthYear),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('REGISTER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Tournament t) {
    return PremiumCard(
      child: Column(
        children: [
          _buildInfoRow(Icons.format_list_bulleted, 'Format', t.format),
          const Divider(color: Colors.white10),
          _buildInfoRow(Icons.terrain, 'Surface', t.surfaceType ?? 'Natural Grass'),
          const Divider(color: Colors.white10),
          _buildInfoRow(Icons.timer, 'Match Time', '${t.matchHalfDuration}m halves'),
          const Divider(color: Colors.white10),
          _buildInfoRow(Icons.coffee, 'Break', '${t.breakBetweenMatches}m rest'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: PremiumTheme.neonGreen),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(List<TournamentMatch> matches, TournamentProvider provider) {
    if (matches.isEmpty) {
      return const Center(child: Text('No matches scheduled yet', style: TextStyle(color: Colors.white38)));
    }

    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        TournamentTeamResponse? myTournamentTeam;
        try {
          myTournamentTeam = provider.registeredTeams.firstWhere(
            (rt) => myTeamIds.contains(rt.teamId) && (rt.teamId == match.homeTeamId || rt.teamId == match.awayTeamId),
          );
        } catch (_) {}

        return _buildMatchItem(match, myTournamentTeam);
      },
    );
  }

  Widget _buildMatchItem(TournamentMatch match, TournamentTeamResponse? memberTeam) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.matchDate != null ? match.matchDate.toString().substring(0, 16) : 'TBD',
                style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              if (match.status == 'finished')
                const Text('FINISHED', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('HOME TEAM', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text('AWAY TEAM', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (memberTeam != null || _isOrganizer) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              children: [
                if (memberTeam != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchLineupScreen(
                              matchId: match.id,
                              tournamentTeamId: memberTeam.id,
                              teamId: memberTeam.teamId,
                              isHomeTeam: memberTeam.teamId == match.homeTeamId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('LINEUP', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchReportScreen(
                              matchId: match.id,
                              tournamentId: widget.tournamentId,
                              myTournamentTeamId: memberTeam.id,
                              myTeamId: memberTeam.teamId,
                              isHomeTeam: memberTeam.teamId == match.homeTeamId,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('STATS', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
                if (_isOrganizer && memberTeam == null)
                  Expanded(
                    child: PremiumButton(
                      text: 'REPORT SCORE',
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
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingsTab(List<TournamentStanding> standings) {
    if (standings.isEmpty) {
      return const Center(child: Text('No standings data available', style: TextStyle(color: Colors.white38)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PremiumButton(
            text: 'VIEW TOP SCORERS',
            icon: Icons.leaderboard,
            color: PremiumTheme.electricBlue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentLeaderboardScreen(tournamentId: widget.tournamentId),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('LEADERBOARD', Icons.table_chart),
          PremiumCard(
            padding: EdgeInsets.zero,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 40,
              columns: const [
                DataColumn(label: Text('TEAM', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('MP', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('PTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
              rows: standings.map((s) => DataRow(
                cells: [
                  DataCell(Text(s.teamName ?? 'Team', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataCell(Text(s.played.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  DataCell(Text(s.points.toString(), style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 14))),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(List<TournamentTeamResponse> registrations, TournamentProvider provider) {
    final pending = registrations.where((r) => r.status == 'PENDING').toList();

    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.white10),
            SizedBox(height: 16),
            Text('No pending requests', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final reg = pending[index];
        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: PremiumTheme.neonGreen, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reg.team.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(reg.team.academyName ?? 'Club Team', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'REJECTED');
                  if (context.mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error rejecting team')));
                  }
                },
                icon: const Icon(Icons.cancel_outlined, color: PremiumTheme.danger, size: 20),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: () async {
                  final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'APPROVED');
                  if (context.mounted && !success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error approving team')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('APPROVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRegisterTeamDialog(BuildContext context, String divisionId, int requiredBirthYear) {
    final teamProvider = context.read<TeamProvider>();
    teamProvider.fetchMyTeams();

    showDialog(
      context: context,
      builder: (context) => Consumer<TeamProvider>(
        builder: (context, tp, _) {
          return AlertDialog(
            backgroundColor: PremiumTheme.surfaceCard(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('REGISTER TEAM', style: TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)),
            content: tp.isLoading 
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)))
              : tp.myTeams.isEmpty
                ? const Text('No teams found.', style: TextStyle(color: Colors.white38))
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tp.myTeams.length,
                      itemBuilder: (context, index) {
                        final team = tp.myTeams[index];
                        final isEligible = team.birthYear == requiredBirthYear;
                        return ListTile(
                          title: Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Birth Year: ${team.birthYear ?? '?'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: isEligible 
                            ? const Icon(Icons.check_circle, color: PremiumTheme.neonGreen)
                            : const Icon(Icons.error_outline, color: PremiumTheme.danger),
                          onTap: isEligible ? () async {
                            final success = await context.read<TournamentProvider>().registerTeamToDivision(divisionId, team.id, '{"source": "mobile_app"}');
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success ? 'Registration submitted!' : 'Error'),
                                backgroundColor: success ? PremiumTheme.neonGreen : PremiumTheme.danger,
                              ));
                            }
                          } : null,
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            ],
          );
        },
      ),
    );
  }
}
