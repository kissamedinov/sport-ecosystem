import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
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
import '../widgets/tournament_bracket_widget.dart';
import '../widgets/shareable_schedule_dialog.dart';
import 'match_center_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
  static final Map<String, String> _groupLettersMap = {};
  late TabController _tabController;
  bool _showBracketView = true;
  String? _selectedStandingsDivisionId;

  bool get _isOrganizer {
    final user = context.read<AuthProvider>().user;
    return user?.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
        user?.roles?.contains('ADMIN') == true;
  }

  void _shareTournamentSchedule(BuildContext context, List<TournamentMatch> matches, Tournament? tournament) {
    if (tournament == null) return;
    showDialog(
      context: context,
      builder: (context) => ShareableScheduleDialog(
        matches: matches,
        tournament: tournament,
      ),
    );
  }

  void _showTimePreferenceDialog(BuildContext context, TournamentProvider provider, TournamentTeamResponse reg) {
    String? currentPref;
    if (reg.registrationData != null && reg.registrationData!.isNotEmpty) {
      try {
        final decoded = jsonDecode(reg.registrationData!);
        if (decoded is Map) {
          currentPref = decoded['time_pref'];
        }
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: PremiumTheme.surfaceBase(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
              ),
              title: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: PremiumTheme.neonGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'tournament.time_pref_title'.tr(namedArgs: {'team': reg.team.name}),
                      style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String?>(
                    value: null,
                    groupValue: currentPref,
                    title: Text('tournament.no_restrictions'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    activeColor: PremiumTheme.neonGreen,
                    onChanged: (val) => setDialogState(() => currentPref = val),
                  ),
                  RadioListTile<String?>(
                    value: 'morning',
                    groupValue: currentPref,
                    title: Text('tournament.morning_only'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    activeColor: PremiumTheme.neonGreen,
                    onChanged: (val) => setDialogState(() => currentPref = val),
                  ),
                  RadioListTile<String?>(
                    value: 'afternoon',
                    groupValue: currentPref,
                    title: Text('tournament.afternoon_only'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    activeColor: PremiumTheme.neonGreen,
                    onChanged: (val) => setDialogState(() => currentPref = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    
                    Map<String, dynamic> dataMap = {};
                    if (reg.registrationData != null && reg.registrationData!.isNotEmpty) {
                      try {
                        final decoded = jsonDecode(reg.registrationData!);
                        if (decoded is Map) {
                          dataMap = Map<String, dynamic>.from(decoded);
                        }
                      } catch (_) {}
                    }
                    
                    if (currentPref == null) {
                      dataMap.remove('time_pref');
                    } else {
                      dataMap['time_pref'] = currentPref;
                    }
                    
                    final jsonStr = jsonEncode(dataMap);
                    
                    final success = await provider.updateTeamStatus(
                      widget.tournamentId, 
                      reg.teamId, 
                      null, // do not change status
                      registrationData: jsonStr,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'tournament.pref_saved'.tr() : 'tournament.pref_save_failed'.tr()),
                          backgroundColor: success ? const Color(0xFF00E676) : Colors.redAccent,
                        ),
                      );
                    }
                  },
                  child: Text('common.save'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
        backgroundColor: PremiumTheme.surfaceCard(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'tournament.tournament_label'.tr().toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
        ),
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
          indicatorColor: PremiumTheme.accent(context),
          labelColor: PremiumTheme.accent(context),
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
          tabs: [
            Tab(text: 'tournament.info_tab'.tr().toUpperCase()),
            Tab(text: 'tournament.matches_tab'.tr().toUpperCase()),
            Tab(text: 'tournament.standings_tab'.tr().toUpperCase()),
            Tab(text: 'tournament.contact_tab'.tr().toUpperCase()),
            if (_isOrganizer) Tab(text: 'tournament.requests_tab'.tr().toUpperCase()),
          ],
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedTournament == null) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null && provider.selectedTournament == null) {
            return Center(child: Text('tournament.error_message'.tr(namedArgs: {'error': provider.error ?? ''}), style: TextStyle(color: cs.onSurfaceVariant)));
          }

          final tournament = provider.selectedTournament;
          if (tournament == null) {
            return Center(child: Text('tournament.tournament_not_found'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))));
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
            _buildSectionTitle('tournament.age_divisions'.tr(), Icons.groups),
            const SizedBox(height: 12),
            ...provider.divisions.map((d) => _buildDivisionCard(d, provider)),
            const SizedBox(height: 24),
          ] else ...[
            _buildSectionTitle('tournament.registration_tab'.tr(), Icons.app_registration),
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
          _buildSectionTitle('tournament.configuration'.tr(), Icons.settings),
          _buildInfoGrid(tournament),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(Tournament t) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: PremiumTheme.accent(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PremiumTheme.accent(context).withValues(alpha: 0.2)),
            ),
            child: t.logoUrl != null && t.logoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(t.logoUrl!, fit: BoxFit.cover),
                )
              : Icon(Icons.emoji_events, size: 40, color: PremiumTheme.accent(context)),
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
                  child: Text('tournament.deadline'.tr(), style: const TextStyle(color: PremiumTheme.danger, fontSize: 10, fontWeight: FontWeight.bold)),
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
          SnackBar(content: Text('tournament.could_not_launch'.tr())),
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
          _buildSectionTitle('tournament.organizer_contacts_section'.tr(), Icons.contact_support),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
            ),
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
                    child: Center(child: Text('tournament.no_contact_info'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('tournament.location_section'.tr(), Icons.map),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: PremiumTheme.accent(context)),
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
                color: PremiumTheme.accent(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: PremiumTheme.accent(context), size: 20),
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
          Icon(icon, size: 14, color: PremiumTheme.accent(context)),
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

    final bool canManageSquad = user?.roles?.any((r) =>
      ['COACH', 'TEAM_OWNER', 'TOURNAMENT_ORGANIZER', 'ADMIN', 'CLUB_OWNER', 'CLUB_MANAGER'].contains(r)) == true;

    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    
    TournamentTeamResponse? myRegisteredTeam;
    try {
      myRegisteredTeam = provider.registeredTeams.firstWhere(
        (rt) => rt.divisionId == division['id'] && myTeamIds.contains(rt.teamId)
      );
    } catch (_) {}

    final registeredTeam = myRegisteredTeam;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                Text(
                  canSeeFee
                      ? 'tournament.requirement_born_fee'.tr(namedArgs: {
                          'format': format ?? 'Standard',
                          'year': birthYear.toString(),
                          'fee': (entryFee ?? 0).toString(),
                        })
                      : 'tournament.requirement_born'.tr(namedArgs: {
                          'format': format ?? 'Standard',
                          'year': birthYear.toString(),
                        }),
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
                        readOnly: !canManageSquad,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: registeredTeam.status == 'APPROVED'
                    ? PremiumTheme.accent(context)
                    : cs.onSurface.withValues(alpha: 0.05),
                  foregroundColor: registeredTeam.status == 'APPROVED'
                    ? Colors.black
                    : cs.onSurface.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  registeredTeam.status == 'APPROVED'
                    ? (canManageSquad ? 'tournament.manage_squad_btn'.tr() : 'tournament.view_squad_btn'.tr())
                    : 'tournament.pending_btn'.tr(),
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
                  backgroundColor: PremiumTheme.accent(context),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('tournament.register_btn'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Tournament t) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.format_list_bulleted, 'tournament.format_row'.tr(), t.format),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.terrain, 'tournament.surface_row'.tr(), t.surfaceType ?? 'tournament.natural_grass'.tr()),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.timer, 'tournament.match_time_row'.tr(), 'tournament.halves_suffix'.tr(namedArgs: {'min': t.matchHalfDuration.toString()})),
          Divider(color: cs.onSurface.withValues(alpha: 0.08)),
          _buildInfoRow(Icons.coffee, 'tournament.break_row'.tr(), 'tournament.rest_suffix'.tr(namedArgs: {'min': t.breakBetweenMatches.toString()})),
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
          Icon(icon, size: 16, color: PremiumTheme.accent(context)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, List<TournamentMatch> matches, Tournament? tournament, {bool isFullWidth = false}) {
    final button = ElevatedButton.icon(
      onPressed: () => _shareTournamentSchedule(context, matches, tournament),
      icon: const Icon(Icons.share_rounded, size: 14),
      label: Text('tournament.share_schedule'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: PremiumTheme.neonGreen,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }

  Widget _buildMatchesTab(List<TournamentMatch> matches, TournamentProvider provider) {
    final isOrganizer = _isOrganizer;
    final hasDraft = matches.any((m) => m.status == 'DRAFT');
    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    final tournament = provider.selectedTournament;
    final isKnockout = tournament?.format == 'KNOCKOUT' || tournament?.format == 'GROUP_STAGE';

    return Column(
      children: [
        if (isOrganizer && (matches.isEmpty || hasDraft))
          _buildOrganizerSchedulingPanel(matches, provider),

        if (matches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isKnockout)
                      Row(
                        children: [
                          _buildViewTabButton('tournament.playoff_bracket'.tr(), _showBracketView, () {
                            setState(() => _showBracketView = true);
                          }),
                          const SizedBox(width: 12),
                          _buildViewTabButton('tournament.match_list'.tr(), !_showBracketView, () {
                            setState(() => _showBracketView = false);
                          }),
                        ],
                      ),
                    if (!isKnockout) const Spacer(),
                    if (isOrganizer && !isKnockout)
                      _buildShareButton(context, matches, tournament),
                  ],
                ),
                if (isOrganizer && isKnockout) ...[
                  const SizedBox(height: 12),
                  _buildShareButton(context, matches, tournament, isFullWidth: true),
                ],
              ],
            ),
          ),
        ],

        if (matches.isEmpty)
          Expanded(
            child: Center(
              child: Text('tournament.no_matches_scheduled'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
            ),
          )
        else if (isKnockout && _showBracketView)
          Expanded(
            child: TournamentBracketWidget(
              matches: matches.where((m) => m.groupId == null).toList(),
              tournamentId: widget.tournamentId,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
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

  Widget _buildViewTabButton(String text, bool active, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? PremiumTheme.accent(context) : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            color: active ? Colors.black : cs.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
                !hasMatches ? 'tournament.ai_scheduler'.tr() : 'tournament.ai_draft_review'.tr(),
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
              ),
              const Spacer(),
              if (isDraft)
                TextButton(
                  onPressed: () => _showAIDetails(provider.aiReport ?? 'AI analyzed team balance and field availability.'),
                  child: Text('tournament.view_report'.tr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, decoration: TextDecoration.underline)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !hasMatches
                ? 'tournament.ai_ready'.tr()
                : 'tournament.ai_draft_mode'.tr(),
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
                    label: Text('tournament.generate_with_ai'.tr()),
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
                    label: Text('tournament.re_generate'.tr()),
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
                          SnackBar(content: Text('tournament.schedule_finalized'.tr())),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: Text('tournament.finalize'.tr()),
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
                  Text('tournament.swap_with'.tr(namedArgs: {'team': teamToSwap.teamName?.toUpperCase() ?? ''}), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    subtitle: Text('tournament.current_group'.tr(namedArgs: {'group': _cleanGroupName(team.groupName, team.groupId)}), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(context);
                      final success = await provider.swapTeams(widget.tournamentId, teamToSwap.teamId, team.teamId);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('tournament.teams_swapped'.tr())),
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
              Text('tournament.ai_logic_report'.tr(), style: TextStyle(color: cs.onSurface, fontSize: 16)),
            ],
          ),
          content: Text(report, style: TextStyle(color: cs.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.close'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen)),
            ),
          ],
        );
      },
    );
  }

  /// Parses a format string like "8v8", "11v11", "5v5" → returns player count per side
  int _parseStartersCount(String? format) {
    if (format == null || format.isEmpty) return 11;
    final match = RegExp(r'^(\d+)').firstMatch(format.trim());
    if (match != null) return int.tryParse(match.group(1)!) ?? 11;
    return 11;
  }

  Widget _buildMatchItem(TournamentMatch match, TournamentTeamResponse? memberTeam) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = match.matchDate != null
        ? DateFormat('dd.MM HH:mm').format(match.matchDate!)
        : 'TBD';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchCenterScreen(
              matchId: match.id,
              tournamentId: widget.tournamentId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.02),
          border: Border(
            bottom: BorderSide(
              color: cs.onSurface.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getMatchStageName(match).toUpperCase(),
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (match.status == 'finished' || match.status == 'FINISHED')
                  Text('tournament.finished_status'.tr().toUpperCase(), style: TextStyle(color: PremiumTheme.accent(context), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))
                else if (match.status == 'LIVE')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PremiumTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: PremiumTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: PremiumTheme.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: PremiumTheme.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (match.status == 'DRAFT')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PremiumTheme.accent(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('tournament.ai_draft'.tr().toUpperCase(), style: TextStyle(color: PremiumTheme.accent(context), fontSize: 9, fontWeight: FontWeight.w900)),
                  )
                else if (match.matchDate != null) ...[
                  if (match.matchDate!.difference(DateTime.now()).inHours < 2)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: PremiumTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('tournament.lineup_deadline'.tr().toUpperCase(), style: const TextStyle(color: PremiumTheme.danger, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (match.fieldName != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 12, color: cs.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(width: 6),
                  Text(
                    match.fieldName!.toUpperCase(),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, size: 16, color: PremiumTheme.accent(context).withValues(alpha: 0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ((match.homeTeamName == null || match.homeTeamName == 'Home Team') ? _getPlayoffPlaceholderName(match, true) : match.homeTeamName!).toUpperCase(),
                              style: TextStyle(
                                color: memberTeam?.teamId == match.homeTeamId ? PremiumTheme.accent(context) : cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            (match.status.toLowerCase() == 'finished' || match.status == 'LIVE') ? '${match.homeScore}' : '-',
                            style: TextStyle(
                              color: (match.status.toLowerCase() == 'finished' || match.status == 'LIVE') ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 16, color: cs.onSurface.withValues(alpha: 0.3)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ((match.awayTeamName == null || match.awayTeamName == 'Away Team') ? _getPlayoffPlaceholderName(match, false) : match.awayTeamName!).toUpperCase(),
                              style: TextStyle(
                                color: memberTeam?.teamId == match.awayTeamId ? PremiumTheme.accent(context) : cs.onSurface,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            (match.status.toLowerCase() == 'finished' || match.status == 'LIVE') ? '${match.awayScore}' : '-',
                            style: TextStyle(
                              color: (match.status.toLowerCase() == 'finished' || match.status == 'LIVE') ? cs.onSurface : cs.onSurface.withValues(alpha: 0.3),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (memberTeam != null || _isOrganizer) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (memberTeam != null) ...[
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () {
                          // Resolve division format to get correct starter count
                          final prov = context.read<TournamentProvider>();
                          Map<String, dynamic>? division;
                          try {
                            division = prov.divisions.firstWhere(
                              (d) => d['id']?.toString() == match.divisionId,
                            );
                          } catch (_) {}
                          final formatStr = division?['format']?.toString()
                              ?? prov.selectedTournament?.format;
                          final maxStarters = _parseStartersCount(formatStr);

                          final isHome = memberTeam.teamId == match.homeTeamId;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchLineupScreen(
                                matchId: match.id,
                                tournamentTeamId: memberTeam.id,
                                teamId: memberTeam.teamId,
                                isHomeTeam: isHome,
                                maxStartersCount: maxStarters,
                                myTeamName: isHome ? match.homeTeamName : match.awayTeamName,
                                opponentName: isHome ? match.awayTeamName : match.homeTeamName,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('tournament.lineup_btn'.tr().toUpperCase(), style: TextStyle(color: cs.onSurface, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchReportScreen(
                                matchId: match.id,
                                tournamentId: widget.tournamentId,
                                match: match,
                                myTournamentTeamId: memberTeam.id,
                                myTeamId: memberTeam.teamId,
                                isHomeTeam: memberTeam.teamId == match.homeTeamId,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('tournament.stats_btn'.tr().toUpperCase(), style: TextStyle(color: cs.onSurface, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  if (_isOrganizer) ...[
                    if (memberTeam != null) const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          side: BorderSide(color: PremiumTheme.accent(context).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('tournament.manage_btn'.tr().toUpperCase(), style: TextStyle(color: PremiumTheme.accent(context), fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchReportScreen(
                                matchId: match.id,
                                tournamentId: widget.tournamentId,
                                match: match,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: PremiumTheme.accent(context),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text('tournament.score_btn'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
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
            Text('tournament.no_standings'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
          ],
        ),
      );
    }

    final Map<String, String> divisionsMap = {};
    for (var s in standings) {
      if (s.divisionId != null) {
        divisionsMap[s.divisionId!] = s.divisionName ?? 'Division';
      }
    }
    
    return StatefulBuilder(
      builder: (context, setState) {
        String? selectedDivisionId;
        if (divisionsMap.isNotEmpty) {
          // Keep selection or default to first
          selectedDivisionId = _selectedStandingsDivisionId ?? divisionsMap.keys.first;
          _selectedStandingsDivisionId = selectedDivisionId;
        }

        final filteredStandings = selectedDivisionId != null 
            ? standings.where((s) => s.divisionId == selectedDivisionId).toList()
            : standings;

        Widget buildContent() {
          if (filteredStandings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text('common.empty_state'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
              ),
            );
          }

          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            final sortedGroupKeys = groupedStandings.keys.toList()..sort((a, b) => (a ?? '').compareTo(b ?? ''));
            _groupLettersMap.clear();
            for (int i = 0; i < sortedGroupKeys.length; i++) {
              final key = sortedGroupKeys[i];
              if (key != null) {
                _groupLettersMap[key] = String.fromCharCode(65 + i);
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sortedGroupKeys.asMap().entries.map((entry) {
                  final groupKey = entry.value;
                  final groupLetter = _groupLettersMap[groupKey] ?? 'A';
                  final standingsList = groupedStandings[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': groupLetter}), Icons.grid_view),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: PremiumTheme.surfaceCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildStandingsHeader(),
                            const Divider(height: 1, thickness: 1),
                            ...standingsList.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildSectionTitle('tournament.playoff_bracket'.tr(), Icons.account_tree_outlined),
                const SizedBox(height: 12),
                SizedBox(
                  height: 440,
                  child: TournamentBracketWidget(
                    matches: provider.matches.where((m) => m.groupId == null).toList(),
                    tournamentId: widget.tournamentId,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('tournament.leaderboard_title'.tr(), Icons.table_chart),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    _buildStandingsHeader(),
                    const Divider(height: 1, thickness: 1),
                    ...filteredStandings.asMap().entries.map((entry) {
                      return _buildStandingsRow(entry.key + 1, entry.value);
                    }),
                  ],
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (divisionsMap.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: PremiumTheme.surfaceCard(context),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'tournament.select_division'.tr().toUpperCase(),
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...divisionsMap.entries.map((entry) {
                                  final isSelected = selectedDivisionId == entry.key;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedStandingsDivisionId = entry.key;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      color: isSelected ? cs.onSurface.withValues(alpha: 0.05) : Colors.transparent,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.value,
                                              style: TextStyle(
                                                color: isSelected ? PremiumTheme.neonGreen : cs.onSurface,
                                                fontSize: 16,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check, color: PremiumTheme.neonGreen),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (divisionsMap[selectedDivisionId] ?? divisionsMap.values.first),
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, color: cs.onSurface.withValues(alpha: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildActionCard(
                'tournament.golden_boot_race'.tr(),
                'tournament.view_top_scorers'.tr(),
                Icons.military_tech,
                PremiumTheme.accent(context),
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentLeaderboardScreen(tournamentId: widget.tournamentId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              buildContent(),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStandingsHeader() {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      color: cs.onSurface.withValues(alpha: 0.4),
      fontSize: 10,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: headerStyle)),
          const SizedBox(width: 12),
          Expanded(child: Text('tournament.team_header'.tr().toUpperCase(), style: headerStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 35, child: Text('tournament.mp_header'.tr().toUpperCase(), textAlign: TextAlign.center, style: headerStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 45, child: Text('tournament.gd_header'.tr().toUpperCase(), textAlign: TextAlign.center, style: headerStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
          SizedBox(width: 35, child: Text('tournament.pts_header'.tr().toUpperCase(), textAlign: TextAlign.center, style: headerStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(int rank, TournamentStanding s, {bool canSwap = false}) {
    final cs = Theme.of(context).colorScheme;
    final isTop3 = rank <= 3;
    final teamName = s.teamName ?? 'Team';

    Color rankBgColor = cs.onSurface.withValues(alpha: 0.05);
    Color rankTextColor = cs.onSurface.withValues(alpha: 0.5);
    if (rank == 1) {
      rankBgColor = Colors.amber;
      rankTextColor = Colors.black;
    } else if (rank == 2) {
      rankBgColor = const Color(0xFFC0C0C0);
      rankTextColor = Colors.black;
    } else if (rank == 3) {
      rankBgColor = const Color(0xFFCD7F32);
      rankTextColor = Colors.black;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.onSurface.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: rankBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: rankTextColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName.toUpperCase(),
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.wins}${"tournament.win_short".tr()} ${s.draws}${"tournament.draw_short".tr()} ${s.losses}${"tournament.loss_short".tr()}',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
            width: 35,
            child: Text(
              s.played.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 45,
            child: Text(
              (s.goalDifference > 0 ? '+' : '') + s.goalDifference.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: s.goalDifference > 0 ? PremiumTheme.neonGreen : (s.goalDifference < 0 ? PremiumTheme.danger : cs.onSurface.withValues(alpha: 0.4)),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 35,
            child: Text(
              s.points.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isTop3 ? rankBgColor : cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: cs.onSurface.withValues(alpha: 0.2), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab(List<TournamentTeamResponse> registrations, TournamentProvider provider) {
    final pending = registrations.where((r) => r.status == 'PENDING').toList();
    final approved = registrations.where((r) => r.status == 'APPROVED').toList();
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('tournament.pending_requests'.tr(), Icons.hourglass_empty),
              if (pending.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: PremiumTheme.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${pending.length}',
                    style: const TextStyle(color: PremiumTheme.danger, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'tournament.pending_requests'.tr(),
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
                    ),
                  ),
                ),
              ),
            )
          else
            ...pending.map((reg) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: PremiumCard(
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
                          Row(
                            children: [
                              Text(reg.team.academyName ?? 'Club Team', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4))),
                              if (reg.divisionId != null) ...[
                                Text(' • ', style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.3))),
                                Builder(
                                  builder: (context) {
                                    final div = provider.divisions.firstWhere(
                                      (d) => d['id'] == reg.divisionId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    final divName = div['name'] ?? 'tournament.division'.tr();
                                    return Text(
                                      divName,
                                      style: TextStyle(fontSize: 11, color: PremiumTheme.neonGreen.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                                    );
                                  }
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'REJECTED');
                        if (context.mounted && !success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('tournament.error_rejecting'.tr())));
                        }
                      },
                      icon: const Icon(Icons.cancel_outlined, color: PremiumTheme.danger, size: 20),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'APPROVED');
                        if (context.mounted && !success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('tournament.error_approving'.tr())));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('tournament.approve_btn'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )),

          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildSectionTitle('tournament.registered_teams'.tr(), Icons.check_circle_outline),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.selectedTournament?.format == 'GROUP_STAGE') ...[
                    ElevatedButton.icon(
                      onPressed: () => _showGroupDrawDialog(context, provider, approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.withValues(alpha: 0.15),
                        foregroundColor: Colors.amber,
                        elevation: 0,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.shuffle, size: 14),
                      label: Text('tournament.group_draw'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () => _showDirectAddTeamDialog(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                      foregroundColor: PremiumTheme.neonGreen,
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('tournament.add_team_directly'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (approved.isEmpty)
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'common.empty_state'.tr(),
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ...approved.map((reg) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: PremiumTheme.neonGreen.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, color: PremiumTheme.neonGreen, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reg.team.name, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(reg.team.academyName ?? 'Club Team', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
                              if (reg.divisionId != null) ...[
                                Text(' • ', style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.3))),
                                Builder(
                                  builder: (context) {
                                    final div = provider.divisions.firstWhere(
                                      (d) => d['id'] == reg.divisionId,
                                      orElse: () => <String, dynamic>{},
                                    );
                                    final divName = div['name'] ?? 'tournament.division'.tr();
                                    return Text(
                                      divName,
                                      style: TextStyle(fontSize: 10, color: PremiumTheme.neonGreen.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                                    );
                                  }
                                ),
                              ],
                            ],
                          ),
                          if (reg.registrationData != null && reg.registrationData!.isNotEmpty) ...[
                            Builder(
                              builder: (context) {
                                String? pref;
                                try {
                                  final decoded = jsonDecode(reg.registrationData!);
                                  if (decoded is Map) {
                                    pref = decoded['time_pref'];
                                  }
                                } catch (_) {}
                                if (pref == null) return const SizedBox.shrink();
                                final label = pref == 'morning' ? 'tournament.morning_pref'.tr() : 'tournament.afternoon_pref'.tr();
                                return Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    label,
                                    style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.access_time_rounded, color: PremiumTheme.neonGreen, size: 18),
                      onPressed: () => _showTimePreferenceDialog(context, provider, reg),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: PremiumTheme.danger, size: 18),
                      onPressed: () async {
                        final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'REJECTED');
                        if (context.mounted && !success) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('tournament.error_rejecting'.tr())));
                        }
                      },
                    ),
                  ],
                ),
              ),
            )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showGroupDrawDialog(BuildContext context, TournamentProvider provider, List<TournamentTeamResponse> approvedTeams) {
    final cs = Theme.of(context).colorScheme;
    
    final Map<String, String> teamGroups = {};
    for (var reg in approvedTeams) {
      teamGroups[reg.teamId] = 'Group A';
    }

    final Map<String, String> groupIdToName = {};
    final uniqueGroupIds = provider.standings.map((s) => s.groupId).whereType<String>().toSet();
    int grpIdx = 0;
    for (var gId in uniqueGroupIds) {
      groupIdToName[gId] = grpIdx == 0 ? 'Group A' : 'Group B';
      grpIdx++;
    }
    
    for (var reg in approvedTeams) {
      final standing = provider.standings.firstWhere((s) => s.teamId == reg.teamId, orElse: () => TournamentStanding(
        teamId: reg.teamId,
        played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0, goalDifference: 0, points: 0
      ));
      if (standing.groupId != null && groupIdToName.containsKey(standing.groupId)) {
        teamGroups[reg.teamId] = groupIdToName[standing.groupId]!;
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceBase(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void runAIDraw() {
              final list = List<TournamentTeamResponse>.from(approvedTeams);
              list.shuffle();
              for (int i = 0; i < list.length; i++) {
                final groupName = i < (list.length / 2) ? 'Group A' : 'Group B';
                teamGroups[list[i].teamId] = groupName;
              }
              setDialogState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shuffle, color: PremiumTheme.neonGreen),
                          const SizedBox(width: 12),
                          Text(
                            'tournament.group_draw'.tr(),
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: runAIDraw,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                          foregroundColor: PremiumTheme.neonGreen,
                          elevation: 0,
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 14),
                        label: Text('tournament.generate_with_ai'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Распределите команды по группам вручную или нажмите ИИ Жеребьевку:',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: approvedTeams.length,
                      itemBuilder: (context, idx) {
                        final reg = approvedTeams[idx];
                        final currentGroup = teamGroups[reg.teamId] ?? 'Group A';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: PremiumTheme.surfaceCard(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  reg.team.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        teamGroups[reg.teamId] = 'Group A';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: currentGroup == 'Group A' ? PremiumTheme.neonGreen : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: currentGroup == 'Group A' ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        'Группа А',
                                        style: TextStyle(
                                          color: currentGroup == 'Group A' ? Colors.black : cs.onSurface.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setDialogState(() {
                                        teamGroups[reg.teamId] = 'Group B';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: currentGroup == 'Group B' ? PremiumTheme.neonGreen : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: currentGroup == 'Group B' ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        'Группа B',
                                        style: TextStyle(
                                          color: currentGroup == 'Group B' ? Colors.black : cs.onSurface.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: cs.onSurface.withValues(alpha: 0.1)),
                          ),
                          child: Text('common.cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final Map<String, List<String>> assignments = {
                              'Group A': [],
                              'Group B': [],
                            };
                            teamGroups.forEach((teamId, groupName) {
                              assignments[groupName]?.add(teamId);
                            });
                            
                            final success = await provider.drawGroups(widget.tournamentId, 2, assignments);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(success ? 'Жеребьевка успешно утверждена!' : 'Ошибка жеребьевки')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PremiumTheme.neonGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('tournament.approve_btn'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDirectAddTeamDialog(BuildContext context, TournamentProvider tournamentProvider) {
    final teamProvider = context.read<TeamProvider>();
    teamProvider.fetchTeams();

    final divisions = tournamentProvider.divisions;
    String? selectedDivisionId = divisions.isNotEmpty ? divisions.first['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DirectAddTeamBottomSheet(
          teamProvider: teamProvider,
          tournamentProvider: tournamentProvider,
          divisions: divisions,
          initialDivisionId: selectedDivisionId,
          tournamentId: widget.tournamentId,
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
                          Text(
                            'tournament.apply_for_division'.tr(),
                            style: const TextStyle(fontSize: 12, color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, letterSpacing: 2),
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
                      _buildMiniInfo(Icons.grid_view, 'tournament.format_info'.tr(), format),
                      Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMiniInfo(Icons.child_care, 'tournament.birth_year_info'.tr(), requiredBirthYear.toString()),
                      Container(width: 1, height: 24, color: cs.onSurface.withValues(alpha: 0.08), margin: const EdgeInsets.symmetric(horizontal: 16)),
                      _buildMiniInfo(Icons.payments_outlined, 'tournament.fee_info'.tr(), '$entryFee ₸'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'tournament.select_your_team'.tr(),
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                if (tp.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)))
                else if (tp.myTeams.isEmpty)
                  Expanded(child: Center(child: Text('tournament.no_teams_profile'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)))))
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
                                  content: Text(success ? 'tournament.registration_sent'.tr() : 'tournament.error_registration'.tr()),
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
                                          'tournament.birth_year_label'.tr(namedArgs: {'year': (team.birthYear ?? 'N/A').toString()}),
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
                    child: Text('common.cancel'.tr(), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold, letterSpacing: 1)),
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

class _DirectAddTeamBottomSheet extends StatefulWidget {
  final TeamProvider teamProvider;
  final TournamentProvider tournamentProvider;
  final List<Map<String, dynamic>> divisions;
  final String? initialDivisionId;
  final String tournamentId;

  const _DirectAddTeamBottomSheet({
    required this.teamProvider,
    required this.tournamentProvider,
    required this.divisions,
    required this.initialDivisionId,
    required this.tournamentId,
  });

  @override
  State<_DirectAddTeamBottomSheet> createState() => _DirectAddTeamBottomSheetState();
}

class _DirectAddTeamBottomSheetState extends State<_DirectAddTeamBottomSheet> {
  String? _selectedDivisionId;
  String _searchQuery = '';
  bool _isSubmitting = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selectedDivisionId = widget.initialDivisionId;
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'tournament.add_team_directly'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (widget.divisions.isNotEmpty) ...[
            Text(
              'tournament.select_division'.tr(),
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDivisionId,
              dropdownColor: PremiumTheme.surfaceCard(context),
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              decoration: PremiumTheme.inputDecorationOf(context, ''),
              items: widget.divisions.map((d) {
                return DropdownMenuItem<String>(
                  value: d['id'],
                  child: Text(d['name'] ?? 'Division'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedDivisionId = val;
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          PremiumTextField(
            controller: _searchController,
            label: 'common.search'.tr(),
            icon: Icons.search,
            hintText: 'tournament.search_teams_hint'.tr(),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: AnimatedBuilder(
              animation: widget.teamProvider,
              builder: (context, _) {
                if (widget.teamProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: PremiumTheme.neonGreen),
                  );
                }

                if (widget.teamProvider.error != null) {
                  return Center(
                    child: Text(
                      'tournament.error_message'.tr(namedArgs: {'error': widget.teamProvider.error!}),
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  );
                }

                final registeredTeamIds = widget.tournamentProvider.registeredTeams
                    .map((rt) => rt.teamId)
                    .toSet();

                final filteredTeams = widget.teamProvider.teams.where((team) {
                  final matchesSearch = team.name.toLowerCase().contains(_searchQuery) ||
                      (team.academyName ?? '').toLowerCase().contains(_searchQuery);
                  final notRegisteredYet = !registeredTeamIds.contains(team.id);
                  return matchesSearch && notRegisteredYet;
                }).toList();

                if (filteredTeams.isEmpty) {
                  return Center(
                    child: Text(
                      'tournament.no_referees'.tr(),
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTeams.length,
                  itemBuilder: (context, index) {
                    final team = filteredTeams[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: PremiumCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield, color: PremiumTheme.neonGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(team.name, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 13)),
                                  if (team.academyName != null)
                                    Text(team.academyName!, style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
                                ],
                              ),
                            ),
                            _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        _isSubmitting = true;
                                      });
                                      
                                      final targetDivisionId = _selectedDivisionId ?? widget.tournamentId;

                                      final success = await widget.tournamentProvider.registerTeamToDivision(
                                        targetDivisionId,
                                        team.id,
                                        '{"registered_by_organizer": true}',
                                      );

                                      if (success) {
                                        await widget.tournamentProvider.fetchTournamentTeams(widget.tournamentId);
                                        await widget.tournamentProvider.fetchTournamentStandings(widget.tournamentId);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('player_added'.tr()),
                                              backgroundColor: PremiumTheme.neonGreen,
                                            ),
                                          );
                                        }
                                      } else {
                                        setState(() {
                                          _isSubmitting = false;
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(widget.tournamentProvider.error ?? 'error_message'.tr()),
                                              backgroundColor: PremiumTheme.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: PremiumTheme.neonGreen,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      minimumSize: const Size(0, 32),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text('common.add'.tr(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _cleanGroupName(String? groupName, String? groupId) {
  if (groupId != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupId)) {
    return _TournamentDetailsPageState._groupLettersMap[groupId]!;
  }
  if (groupName != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupName)) {
    return _TournamentDetailsPageState._groupLettersMap[groupName]!;
  }
  final name = groupName ?? groupId;
  if (name == null) return "A";
  final upper = name.toUpperCase();
  if (upper.startsWith("GROUP") || upper.startsWith("ГРУППА")) {
    final parts = name.split(" ");
    if (parts.length > 1) {
      final letter = parts.last.toUpperCase();
      if (letter == "A" || letter == "А") return "A";
      if (letter == "B" || letter == "Б") return "B";
      return letter;
    }
  }
  if (name.length > 8) {
    return name.split("-").last.toUpperCase();
  }
  return name.toUpperCase();
}

String _getPlayoffPlaceholderName(TournamentMatch match, bool isHome) {
  if (match.roundNumber == 1) {
    if (match.bracketPosition == 0) {
      return isHome ? "A1" : "B2";
    } else if (match.bracketPosition == 1) {
      return isHome ? "B1" : "A2";
    } else if (match.bracketPosition == 2) {
      return isHome ? "A3" : "B3";
    } else if (match.bracketPosition == 3) {
      return isHome ? "A4" : "B4";
    }
  } else if (match.roundNumber == 2) {
    if (match.bracketPosition == 0) {
      return isHome ? "Победитель ПФ1" : "Победитель ПФ2";
    } else if (match.bracketPosition == 1) {
      return isHome ? "Проигравший ПФ1" : "Проигравший ПФ2";
    }
  }
  return 'tournament.awaiting_winner'.tr();
}

String _getMatchStageName(TournamentMatch match) {
  if (match.groupId != null) {
    final letter = _cleanGroupName(null, match.groupId);
    return 'Группа $letter';
  }
  if (match.roundNumber == 1) {
    if (match.bracketPosition == 0 || match.bracketPosition == 1) {
      return '1/2 финала';
    } else if (match.bracketPosition == 2 || match.bracketPosition == 3) {
      return '1/2 за 5-8 м';
    }
  } else if (match.roundNumber == 2) {
    if (match.bracketPosition == 0) {
      return 'Финал 🏆';
    } else if (match.bracketPosition == 1) {
      return 'За 3 место 🥉';
    } else if (match.bracketPosition == 2) {
      return 'За 5-6 место';
    } else if (match.bracketPosition == 3) {
      return 'За 7-8 место';
    }
  }
  return 'Плей-офф';
}
