import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/api/api_client.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../tournaments/data/models/tournament_match.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../lineups/presentation/screens/match_lineup_screen.dart';
import '../../presentation/screens/match_events_screen.dart';
import '../../../player_stats/presentation/screens/player_stats_screen.dart';
import '../../../matches/providers/match_provider.dart';
import '../../../matches/data/models/match_event.dart';
import '../../../tournaments/providers/tournament_provider.dart';

class MatchDetailsScreen extends StatefulWidget {
  final TournamentMatch match;
  final String homeTeamName;
  final String awayTeamName;

  const MatchDetailsScreen({
    super.key,
    required this.match,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  int _selectedTabIndex = 0;
  final Map<String, String> _playerNamesCache = {};
  bool _isLoadingNames = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lineupProvider = context.read<LineupProvider>();
      if (widget.match.homeTeamId != null) {
        lineupProvider.fetchTeamLineup(widget.match.id, widget.match.homeTeamId!);
      }
      if (widget.match.awayTeamId != null) {
        lineupProvider.fetchTeamLineup(widget.match.id, widget.match.awayTeamId!);
      }
      _loadPlayerNames();
      context.read<MatchProvider>().fetchMatchEvents(widget.match.id);
      if (widget.match.tournamentId != null) {
        context.read<TournamentProvider>().fetchTournamentMatches(widget.match.tournamentId!);
      }
    });
  }

  Future<void> _loadPlayerNames() async {
    setState(() => _isLoadingNames = true);
    final homeId = widget.match.homeTeamId;
    final awayId = widget.match.awayTeamId;
    final apiClient = context.read<ApiClient>();

    Future<void> fetchForTeam(String? teamId) async {
      if (teamId == null) return;
      try {
        final res = await apiClient.get('/teams/$teamId/players');
        if (res.statusCode == 200 && res.data is List) {
          for (var item in res.data) {
            final pId = item['player_id'] ?? item['child_profile_id'];
            final name = item['player_name'] ?? item['player']?['name'];
            if (pId != null && name != null) {
              _playerNamesCache[pId] = name;
            }
          }
        }
      } catch (_) {}
    }

    await fetchForTeam(homeId);
    await fetchForTeam(awayId);
    if (mounted) {
      setState(() {
        _isLoadingNames = false;
      });
    }
  }

  List<String> _calculateTeamForm(String teamId) {
    final tournamentProvider = context.read<TournamentProvider>();
    final allMatches = tournamentProvider.matches;

    final teamMatches = allMatches.where((m) =>
      m.status == 'FINISHED' &&
      (m.homeTeamId == teamId || m.awayTeamId == teamId) &&
      m.matchDate != null
    ).toList();

    // Sort by date descending
    teamMatches.sort((a, b) => b.matchDate!.compareTo(a.matchDate!));

    final recentMatches = teamMatches.take(5).toList();

    final formList = <String>[];
    for (var m in recentMatches) {
      if (m.homeTeamId == teamId) {
        if (m.homeScore > m.awayScore) {
          formList.add('W');
        } else if (m.homeScore < m.awayScore) {
          formList.add('L');
        } else {
          formList.add('D');
        }
      } else {
        if (m.awayScore > m.homeScore) {
          formList.add('W');
        } else if (m.awayScore < m.homeScore) {
          formList.add('L');
        } else {
          formList.add('D');
        }
      }
    }
    return formList;
  }

  @override
  Widget build(BuildContext context) {
    final lineupProvider = context.watch<LineupProvider>();
    final user = context.watch<AuthProvider>().user;
    final isCoach = user?.roles?.any((r) => r == 'COACH' || r == 'TEAM_OWNER') ?? false;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('match.match_center'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildScoreBoard(),
            const SizedBox(height: 12),
            _buildTabSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSelectedTabContent(lineupProvider, isCoach),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(LineupProvider lineupProvider, bool isCoach) {
    if (_selectedTabIndex == 0) {
      // Lineups Tab
      return Column(
        children: [
          _buildLineupSection(
            context,
            widget.homeTeamName,
            widget.match.homeTeamId ?? '',
            widget.match.homeTeamId != null ? lineupProvider.getLineupForMatch(widget.match.id, widget.match.homeTeamId!) : null,
            isCoach,
            true,
          ),
          const SizedBox(height: 24),
          _buildLineupSection(
            context,
            widget.awayTeamName,
            widget.match.awayTeamId ?? '',
            widget.match.awayTeamId != null ? lineupProvider.getLineupForMatch(widget.match.id, widget.match.awayTeamId!) : null,
            isCoach,
            false,
          ),
          const SizedBox(height: 100),
        ],
      );
    } else if (_selectedTabIndex == 1) {
      // Timeline Tab
      return _buildTimelineSection();
    } else {
      // Info / Details Tab
      return _buildInfoSection();
    }
  }

  Widget _buildTimelineSection() {
    final matchProvider = context.watch<MatchProvider>();
    final events = matchProvider.currentMatchEvents;

    final firstHalfEvents = events.where((e) => e.minute <= 45).toList();
    final secondHalfEvents = events.where((e) => e.minute > 45).toList();

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              const Icon(Icons.flash_off_outlined, color: Colors.white12, size: 48),
              const SizedBox(height: 12),
              Text(
                'match.no_events'.tr(),
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (firstHalfEvents.isNotEmpty) ...[
          _buildHalfHeader('match.first_half'.tr()),
          const SizedBox(height: 12),
          ...firstHalfEvents.map((e) => _buildTimelineEventRow(e)),
          const SizedBox(height: 24),
        ],
        if (secondHalfEvents.isNotEmpty) ...[
          _buildHalfHeader('match.second_half'.tr()),
          const SizedBox(height: 12),
          ...secondHalfEvents.map((e) => _buildTimelineEventRow(e)),
          const SizedBox(height: 48),
        ],
      ],
    );
  }

  Widget _buildHalfHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: PremiumTheme.neonGreen,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineEventRow(MatchEvent event) {
    final isHome = event.teamId == widget.match.homeTeamId;
    final pId = event.playerId ?? event.childProfileId;
    final pName = pId != null ? (_playerNamesCache[pId] ?? 'match.player_placeholder'.tr(namedArgs: {'id': pId.length > 4 ? pId.substring(0, 4) : pId})) : 'match.player_generic'.tr();

    String emoji = '⚽';
    String typeLabel = '';
    if (event.eventType == EventType.GOAL) {
      emoji = '⚽';
      typeLabel = 'match.event_type_goal'.tr();
    } else if (event.eventType == EventType.YELLOW_CARD) {
      emoji = '🟨';
      typeLabel = 'match.event_type_yellow'.tr();
    } else if (event.eventType == EventType.RED_CARD) {
      emoji = '🟥';
      typeLabel = 'match.event_type_red'.tr();
    } else if (event.eventType == EventType.SUBSTITUTE) {
      emoji = '🔄';
      typeLabel = 'match.event_type_sub'.tr();
    }

    final contentWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isHome) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${event.minute}'",
              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                typeLabel,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
              ),
            ],
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                typeLabel,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${event.minute}'",
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: contentWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final homeForm = widget.match.homeTeamId != null ? _calculateTeamForm(widget.match.homeTeamId!) : <String>[];
    final awayForm = widget.match.awayTeamId != null ? _calculateTeamForm(widget.match.awayTeamId!) : <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF122229),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('match.details_header'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_rounded, 'match.date_time'.tr(), widget.match.matchDate?.toString().substring(0, 16) ?? 'TBD'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'match.arena_field'.tr(), widget.match.fieldName ?? 'ARENA CENTER'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.info_outline, 'match.match_status'.tr(), widget.match.status),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          Text('match.team_form_title'.tr(), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          // Home form row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.homeTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (homeForm.isEmpty)
                _buildEmptyForm()
              else
                Row(children: homeForm.map((f) => _buildFormCircle(f)).toList()),
            ],
          ),
          const SizedBox(height: 12),
          // Away form row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.awayTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (awayForm.isEmpty)
                _buildEmptyForm()
              else
                Row(children: awayForm.map((f) => _buildFormCircle(f)).toList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFormCircle(String result) {
    Color color = Colors.grey;
    String char = 'match.form_draw'.tr();
    if (result == 'W') {
      color = const Color(0xFF00E676);
      char = 'match.form_win'.tr();
    } else if (result == 'L') {
      color = Colors.redAccent;
      char = 'match.form_loss'.tr();
    }

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.brown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.brown.withOpacity(0.3)),
      ),
      child: const Text(
        '—',
        style: TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PremiumTheme.surfaceBase(context), Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildTeamHeader(widget.homeTeamName, Colors.redAccent)),
              _buildMiddleScore(),
              Expanded(child: _buildTeamHeader(widget.awayTeamName, Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 32),
          _buildMatchMeta(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildMiddleScore() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            '${widget.match.homeScore} : ${widget.match.awayScore}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.match.status == 'LIVE' ? Colors.redAccent.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.match.status,
            style: TextStyle(
              color: widget.match.status == 'LIVE' ? Colors.redAccent : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(String name, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Icon(Icons.shield_rounded, size: 40, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMatchMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          widget.match.matchDate?.toString().substring(0, 16) ?? 'match.time_tbd'.tr(),
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 20),
        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          'match.arena_center'.tr(),
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleAction(Icons.analytics_outlined, 'match.stats'.tr(), () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: widget.match.id)));
        }),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.videocam_outlined, 'match.replay'.tr(), null),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.share_outlined, 'match.share'.tr(), null),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, String label, VoidCallback? onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: onTap != null ? Colors.white54 : Colors.white24, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTabSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            child: _buildTab('match.tab_lineups'.tr(), _selectedTabIndex == 0),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            child: _buildTab('match.tab_timeline'.tr(), _selectedTabIndex == 1),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 2),
            child: _buildTab('match.tab_details'.tr(), _selectedTabIndex == 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? PremiumTheme.neonGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PremiumTheme.neonGreen : Colors.white10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLineupSection(BuildContext context, String teamName, String teamId, MatchLineup? lineup, bool isCoach, bool isHome) {
    final color = isHome ? Colors.redAccent : Colors.blueAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(
                  '$teamName LINEUP',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
            if (lineup != null)
              const Icon(Icons.check_circle_rounded, color: PremiumTheme.neonGreen, size: 18)
            else
              Text('match.pending'.tr(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        if (lineup == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Icon(Icons.groups_3_outlined, color: Colors.white10, size: 40),
                const SizedBox(height: 12),
                Text('match.no_lineup'.tr(), style: const TextStyle(color: Colors.white24, fontSize: 12)),
                if (isCoach && teamId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchLineupScreen(matchId: widget.match.id, teamId: teamId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.1),
                      foregroundColor: color,
                      side: BorderSide(color: color.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('match.submit_lineup'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ] else
          _buildLineupList(lineup),
      ],
    );
  }

  Widget _buildLineupList(MatchLineup lineup) {
    final starters = lineup.players.where((p) => p.isStarting).toList();
    final bench = lineup.players.where((p) => !p.isStarting).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSquadCategory('match.starting_xi'.tr(), starters),
        const SizedBox(height: 16),
        _buildSquadCategory('match.substitutes'.tr(), bench),
      ],
    );
  }

  Widget _buildSquadCategory(String title, List<LineupPlayer> players) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...players.map((p) => _buildPlayerTile(p)),
      ],
    );
  }

  Widget _buildPlayerTile(LineupPlayer p) {
    final id = p.playerId ?? p.childProfileId ?? 'Unknown';
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final name = _playerNamesCache[id] ?? 'match.player_placeholder'.tr(namedArgs: {'id': id.length > 4 ? id.substring(0, 4) : id});
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerStatsScreen(playerId: id)));
        },
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            p.position ?? '?',
            style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        trailing: p.jerseyNumber != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
              child: Text('#${p.jerseyNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
            )
          : null,
      ),
    );
  }
}
