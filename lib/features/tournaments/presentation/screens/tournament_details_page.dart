import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import './assign_match_details_screen.dart';
import '../../providers/tournament_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../data/models/tournament.dart';
import '../../data/models/tournament_match.dart';
import '../../data/models/tournament_standing.dart';
import '../../data/models/tournament_team_response.dart';
import 'match_lineup_screen.dart';
import 'match_report_screen.dart';
import 'tournament_squad_screen.dart';
import 'tournament_leaderboard_screen.dart';
import 'create_tournament_screen.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentDetailsPage extends StatefulWidget {
  final String tournamentId;
  final bool autoRegister;

  const TournamentDetailsPage({
    super.key, 
    required this.tournamentId, 
    this.autoRegister = false,
  });

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
    _tabController = TabController(length: _isOrganizer ? 5 : 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TournamentProvider>();
      await provider.fetchTournamentDetails(widget.tournamentId);
      provider.fetchTournamentMatches(widget.tournamentId);
      provider.fetchTournamentStandings(widget.tournamentId);
      provider.fetchTournamentTeams(widget.tournamentId);

      if (widget.autoRegister && mounted) {
        final divisions = provider.divisions;
        if (divisions.isNotEmpty) {
          final int? birthYear = int.tryParse(divisions.first['birth_year']?.toString() ?? "");
          _showRegisterTeamDialog(context, divisions.first, birthYear ?? 0);
        } else {
          // Fallback to tournament level registration if no divisions
          final tournament = provider.selectedTournament;
          if (tournament != null) {
             final int? birthYear = int.tryParse(tournament.ageCategory);
             _showRegisterTeamDialog(context, {
               'id': tournament.id,
               'name': 'Standard Category',
               'birth_year': tournament.ageCategory,
             }, birthYear ?? 0);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TOURNAMENT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14)),
        actions: [
          if (_isOrganizer)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: PremiumTheme.neonGreen),
              onPressed: () {
                final tournament = context.read<TournamentProvider>().selectedTournament;
                if (tournament != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateTournamentScreen(initialTournament: tournament),
                    ),
                  );
                }
              },
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: cs.onSurfaceVariant,
          isScrollable: _isOrganizer,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: [
            const Tab(text: 'INFO'),
            const Tab(text: 'MATCHES'),
            const Tab(text: 'STANDINGS'),
            const Tab(text: 'CONTACT'),
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
            return Center(child: Text('Error: ${provider.error}', style: TextStyle(color: cs.onSurfaceVariant)));
          }

          final tournament = provider.selectedTournament;
          if (tournament == null) {
            return Center(child: Text('Tournament not found', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(tournament, provider),
              _buildMatchesTab(provider.matches, provider),
              _buildStandingsTab(provider.standings),
              _buildContactTab(tournament),
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
          ] else ...[
            _buildSectionTitle('REGISTRATION', Icons.app_registration),
            const SizedBox(height: 12),
            _buildDivisionCard({
              'id': tournament.id,
              'name': 'Standard Category',
              'birth_year': tournament.ageCategory,
              'format': tournament.format,
              'entry_fee': 0,
            }, provider),
            const SizedBox(height: 24),
          ],
          _buildSectionTitle('CONFIGURATION', Icons.settings),
          _buildInfoGrid(tournament),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(Tournament t) {
    final cs = Theme.of(context).colorScheme;
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
            child: t.logoUrl != null && t.logoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(t.logoUrl!, fit: BoxFit.cover),
                )
              : const Icon(Icons.emoji_events, size: 40, color: PremiumTheme.neonGreen),
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
                    Icon(Icons.location_on, size: 14, color: cs.onSurface.withValues(alpha: 0.55)),
                    const SizedBox(width: 4),
                    Text(t.location, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: cs.onSurface.withValues(alpha: 0.55)),
                    const SizedBox(width: 4),
                    Text('${t.startDate} - ${t.endDate}',
                        style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (t.registrationClose != null && t.status == 'upcoming')
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: PremiumTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PremiumTheme.danger.withValues(alpha: 0.2)),
                  ),
                  child: const Text('DEADLINE', style: TextStyle(color: PremiumTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(t.registrationClose!.split('T').first, style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch contact application')),
        );
      }
    }
  }

  Widget _buildContactTab(Tournament t) {
    final cs = Theme.of(context).colorScheme;
    final hasWhatsapp = t.whatsapp != null && t.whatsapp!.trim().isNotEmpty;
    final hasPhone = t.phone != null && t.phone!.trim().isNotEmpty;
    final hasInstagram = t.instagram != null && t.instagram!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ORGANIZER CONTACTS', Icons.contact_support),
          PremiumCard(
            child: Column(
              children: [
                if (hasWhatsapp)
                  _buildContactItem(
                    Icons.message,
                    'WhatsApp',
                    t.whatsapp!,
                    onTap: () {
                      final cleanPhone = t.whatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
                      _launchURL('https://wa.me/$cleanPhone');
                    },
                  ),
                if (hasWhatsapp && (hasPhone || hasInstagram)) Divider(color: cs.onSurface.withValues(alpha: 0.08)),
                if (hasPhone)
                  _buildContactItem(
                    Icons.phone,
                    'Phone Number',
                    t.phone!,
                    onTap: () => _launchURL('tel:${t.phone}'),
                  ),
                if (hasPhone && hasInstagram) Divider(color: cs.onSurface.withValues(alpha: 0.08)),
                if (hasInstagram)
                  _buildContactItem(
                    Icons.camera_alt_outlined,
                    'Instagram',
                    '@${t.instagram!.replaceAll('@', '')}',
                    onTap: () {
                      final handle = t.instagram!.replaceAll('@', '');
                      _launchURL('https://instagram.com/$handle');
                    },
                  ),
                if (!hasWhatsapp && !hasPhone && !hasInstagram)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No contact information provided', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('LOCATION', Icons.map),
          PremiumCard(
            child: Row(
              children: [
                const Icon(Icons.location_on, color: PremiumTheme.neonGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t.location, style: TextStyle(color: cs.onSurface)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value, {required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: PremiumTheme.neonGreen, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PremiumTheme.neonGreen),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDivisionCard(Map<String, dynamic> division, TournamentProvider provider) {
    final rawBirthYear = division['birth_year'] ?? 'N/A';
    final int birthYear = rawBirthYear is int ? rawBirthYear : int.tryParse(rawBirthYear.toString()) ?? 0;
    final name = division['name'] ?? 'Division $birthYear';
    final format = division['format'] ?? 'Standard';
    final entryFee = division['entry_fee'] ?? 0;
    
    final user = context.read<AuthProvider>().user;
    final canSeeFee = user?.roles?.any((r) => 
      ['COACH', 'TEAM_OWNER', 'TOURNAMENT_ORGANIZER', 'ADMIN'].contains(r)) == true;

    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    
    TournamentTeamResponse? myRegisteredTeam;
    try {
      myRegisteredTeam = provider.registeredTeams.firstWhere(
        (rt) => rt.divisionId == division['id'] && myTeamIds.contains(rt.teamId)
      );
    } catch (_) {}

    final registeredTeam = myRegisteredTeam;
    final cs = Theme.of(context).colorScheme;
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(
                  'Format: ${format ?? 'Standard'} • Requirement: Born $birthYear${canSeeFee ? ' • Fee: ${entryFee ?? 0} ₸' : ''}',
                  style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))
                ),
              ],
            ),
          ),
          if (registeredTeam != null)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: registeredTeam.status == 'APPROVED' ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentSquadScreen(
                        tournamentTeamId: registeredTeam.id,
                        teamId: registeredTeam.teamId,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: registeredTeam.status == 'APPROVED'
                    ? PremiumTheme.neonGreen.withValues(alpha: 0.2)
                    : cs.onSurface.withValues(alpha: 0.05),
                  foregroundColor: registeredTeam.status == 'APPROVED'
                    ? PremiumTheme.neonGreen
                    : cs.onSurface.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  registeredTeam.status == 'APPROVED' ? 'MANAGE SQUAD' : 'PENDING...',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () => _showRegisterTeamDialog(context, division, birthYear),
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
    final cs = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        children: [
          _buildInfoRow(Icons.format_list_bulleted, 'Format', t.format),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.terrain, 'Surface', t.surfaceType ?? 'Natural Grass'),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.timer, 'Match Time', '${t.matchHalfDuration}m halves'),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.coffee, 'Break', '${t.breakBetweenMatches}m rest'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: PremiumTheme.neonGreen),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(List<TournamentMatch> matches, TournamentProvider provider) {
    final isOrganizer = _isOrganizer;
    final hasDraft = matches.any((m) => m.status == 'DRAFT');
    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();

    return Column(
      children: [
        if (isOrganizer && (matches.isEmpty || hasDraft))
          _buildOrganizerSchedulingPanel(matches, provider),

        if (matches.isEmpty)
          Expanded(
            child: Center(
              child: Text('No matches scheduled yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
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
            ),
          ),
      ],
    );
  }

  Widget _buildOrganizerSchedulingPanel(List<TournamentMatch> matches, TournamentProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final bool hasMatches = matches.isNotEmpty;
    final bool isDraft = matches.any((m) => m.status == 'DRAFT');

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.neonGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: PremiumTheme.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                !hasMatches ? 'AI SCHEDULER' : 'AI DRAFT REVIEW',
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
              ),
              const Spacer(),
              if (isDraft)
                TextButton(
                  onPressed: () => _showAIDetails(provider.aiReport ?? 'AI analyzed team balance and field availability.'),
                  child: Text('VIEW REPORT', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, decoration: TextDecoration.underline)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !hasMatches
                ? 'Ready to generate the tournament schedule using AI optimization?'
                : 'The schedule is currently in DRAFT mode. Review it and finalize to make it public.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (!hasMatches)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => provider.generateSchedule(widget.tournamentId),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('GENERATE WITH AI'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                )
              else if (isDraft) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.generateSchedule(widget.tournamentId),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('RE-GENERATE'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                      side: BorderSide(color: cs.onSurface.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final success = await provider.finalizeSchedule(widget.tournamentId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Schedule finalized and published!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('FINALIZE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showSwapDialog(TournamentStanding teamToSwap) {
    final provider = context.read<TournamentProvider>();
    final otherTeams = provider.standings.where((s) => s.teamId != teamToSwap.teamId).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceBase(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: PremiumTheme.neonGreen),
                  const SizedBox(width: 12),
                  Text('SWAP ${teamToSwap.teamName?.toUpperCase()} WITH...', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: otherTeams.length,
                itemBuilder: (context, index) {
                  final team = otherTeams[index];
                  return ListTile(
                    leading: Icon(Icons.group, color: cs.onSurface.withValues(alpha: 0.4)),
                    title: Text(team.teamName ?? 'Team', style: TextStyle(color: cs.onSurface, fontSize: 14)),
                    subtitle: Text('Current: Group ${team.groupId?.toString().split("-").last.toUpperCase() ?? "A"}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await provider.swapTeams(widget.tournamentId, teamToSwap.teamId, team.teamId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Teams swapped and matches updated!')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showAIDetails(String report) {
    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: PremiumTheme.surfaceBase(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: PremiumTheme.neonGreen),
              const SizedBox(width: 12),
              Text('AI Logic Report', style: TextStyle(color: cs.onSurface, fontSize: 16)),
            ],
          ),
          content: Text(report, style: TextStyle(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: PremiumTheme.neonGreen)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMatchItem(TournamentMatch match, TournamentTeamResponse? memberTeam) {
    final cs = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                match.matchDate != null ? match.matchDate.toString().substring(0, 16) : 'TBD',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              if (match.status == 'finished')
                const Text('FINISHED', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold))
              else if (match.status == 'DRAFT')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Text('AI DRAFT', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                )
              else if (match.matchDate != null) ...[
                if (match.matchDate!.difference(DateTime.now()).inHours < 2)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PremiumTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LINEUP DEADLINE', style: TextStyle(color: PremiumTheme.danger, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (match.fieldName != null) ...[
            Row(
              children: [
                Icon(Icons.stadium, size: 12, color: cs.onSurface.withValues(alpha: 0.2)),
                const SizedBox(width: 6),
                Text(
                  match.fieldName!.toUpperCase(),
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (match.homeTeamName ?? 'HOME TEAM').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: memberTeam?.teamId == match.homeTeamId ? PremiumTheme.neonGreen : cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      )
                    ),
                    const SizedBox(height: 4),
                    Text('HOME', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: memberTeam != null ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: memberTeam != null ? Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)) : null,
                ),
                child: Text(
                  '${match.homeScore} - ${match.awayScore}',
                  style: TextStyle(
                    color: memberTeam != null ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
                    fontSize: 22,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      (match.awayTeamName ?? 'AWAY TEAM').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: memberTeam?.teamId == match.awayTeamId ? PremiumTheme.neonGreen : cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      )
                    ),
                    const SizedBox(height: 4),
                    Text('AWAY', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.2), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          if (memberTeam != null || _isOrganizer) ...[
            const SizedBox(height: 16),
            Divider(color: cs.onSurface.withValues(alpha: 0.08)),
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
                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('LINEUP', style: TextStyle(color: cs.onSurface, fontSize: 11)),
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
                        side: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('STATS', style: TextStyle(color: cs.onSurface, fontSize: 11)),
                    ),
                  ),
                ],
                if (_isOrganizer) ...[
                  if (memberTeam != null) const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AssignMatchDetailsScreen(
                                    match: match,
                                    tournamentId: widget.tournamentId,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: PremiumTheme.electricBlue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('MANAGE', style: TextStyle(color: PremiumTheme.electricBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: PremiumTheme.neonGreen,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: const Text('SCORE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandingsTab(List<TournamentStanding> standings) {
    final provider = context.read<TournamentProvider>();
    final tournament = provider.selectedTournament;
    final isGroupStage = tournament?.format == 'GROUP_STAGE';
    final cs = Theme.of(context).colorScheme;

    if (standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: cs.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('No standings data available', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    if (isGroupStage) {
      // Group standings by group_id
      final groupedStandings = <String?, List<TournamentStanding>>{};
      for (var s in standings) {
        groupedStandings.putIfAbsent(s.groupId, () => []).add(s);
      }

      return ListView(
        padding: const EdgeInsets.all(20),
        children: groupedStandings.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('GROUP ${entry.key?.toString().split("-").last.toUpperCase() ?? "A"}', Icons.grid_view),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
                child: Column(
                  children: [
                    _buildStandingsHeader(),
                    Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
                    ...entry.value.asMap().entries.map((item) {
                      return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                    }),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildActionCard(
            'GOLDEN BOOT RACE',
            'View top goal scorers of the tournament',
            Icons.military_tech,
            PremiumTheme.neonGreen,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentLeaderboardScreen(tournamentId: widget.tournamentId),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          _buildSectionTitle('LEADERBOARD', Icons.table_chart),
          Container(
            decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
            child: Column(
              children: [
                _buildStandingsHeader(),
                Divider(color: cs.onSurface.withValues(alpha: 0.08), height: 1),
                ...standings.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  return _buildStandingsRow(index + 1, s);
                }),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStandingsHeader() {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('#', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(child: Text('TEAM', style: headerStyle)),
          SizedBox(width: 30, child: Text('MP', textAlign: TextAlign.center, style: headerStyle)),
          SizedBox(width: 30, child: Text('GD', textAlign: TextAlign.center, style: headerStyle)),
          SizedBox(width: 40, child: Text('PTS', textAlign: TextAlign.center, style: headerStyle)),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(int rank, TournamentStanding s, {bool canSwap = false}) {
    final cs = Theme.of(context).colorScheme;
    final isTop3 = rank <= 3;
    final teamName = s.teamName ?? 'Team';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3 ? PremiumTheme.neonGreen.withValues(alpha: 0.03) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: isTop3 ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.4),
                fontWeight: isTop3 ? FontWeight.w900 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                teamName[0].toUpperCase(),
                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              teamName.toUpperCase(),
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canSwap)
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: PremiumTheme.neonGreen, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => _showSwapDialog(s),
            ),
          SizedBox(
            width: 30,
            child: Text(
              s.played.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              (s.goalsFor - s.goalsAgainst).toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              s.points.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isTop3 ? PremiumTheme.neonGreen : cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(List<TournamentTeamResponse> registrations, TournamentProvider provider) {
    final pending = registrations.where((r) => r.status == 'PENDING').toList();
    final cs = Theme.of(context).colorScheme;

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: cs.onSurface.withValues(alpha: 0.08)),
            const SizedBox(height: 16),
            Text('No pending requests', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
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
                    Text(reg.team.name, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(reg.team.academyName ?? 'Club Team', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
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

  void _showRegisterTeamDialog(BuildContext context, Map<String, dynamic> division, int requiredBirthYear) {
    final teamProvider = context.read<TeamProvider>();
    teamProvider.fetchMyTeams();

    final divisionId = division['id'];
    final divisionName = division['name'] ?? 'Division';
    final format = division['format'] ?? 'Standard';
    final entryFee = division['entry_fee'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.all(24),
        child: Consumer<TeamProvider>(
          builder: (context, tp, _) {
            final cs = Theme.of(context).colorScheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in, color: PremiumTheme.neonGreen, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'APPLY FOR DIVISION',
                            style: TextStyle(fontSize: 12, color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          Text(
                            divisionName.toUpperCase(),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildMiniInfo(Icons.grid_view, 'FORMAT', format),
                      Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMiniInfo(Icons.child_care, 'BIRTH YEAR', requiredBirthYear.toString()),
                      Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMiniInfo(Icons.payments_outlined, 'FEE', '$entryFee ₸'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'SELECT YOUR TEAM',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                if (tp.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)))
                else if (tp.myTeams.isEmpty)
                  Expanded(child: Center(child: Text('No teams found in your profile.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: tp.myTeams.length,
                      itemBuilder: (context, index) {
                        final team = tp.myTeams[index];
                        final isEligible = team.birthYear == requiredBirthYear;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: isEligible ? () async {
                              final success = await context.read<TournamentProvider>().registerTeamToDivision(divisionId, team.id, '{"source": "mobile_app"}');
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(success ? 'Registration request sent!' : 'Error submitting registration'),
                                  backgroundColor: success ? PremiumTheme.neonGreen : PremiumTheme.danger,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ));
                              }
                            } : null,
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isEligible ? cs.onSurface.withValues(alpha: 0.02) : Colors.black12,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isEligible
                                    ? PremiumTheme.neonGreen.withValues(alpha: 0.2)
                                    : cs.onSurface.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isEligible ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.shield,
                                      color: isEligible ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.2),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          team.name.toUpperCase(),
                                          style: TextStyle(
                                            color: isEligible ? cs.onSurface : cs.onSurface.withValues(alpha: 0.4),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Birth Year: ${team.birthYear ?? "N/A"}',
                                          style: TextStyle(
                                            color: isEligible ? PremiumTheme.neonGreen.withValues(alpha: 0.5) : cs.onSurface.withValues(alpha: 0.08),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isEligible)
                                    const Icon(Icons.arrow_forward_ios, color: PremiumTheme.neonGreen, size: 14)
                                  else
                                    Icon(Icons.lock_outline, color: cs.onSurface.withValues(alpha: 0.08), size: 16),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CANCEL', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: PremiumTheme.neonGreen),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
