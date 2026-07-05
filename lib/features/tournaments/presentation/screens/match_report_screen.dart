import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/tournament_squad_member.dart';
import '../../providers/tournament_squad_provider.dart';
import '../../data/models/tournament_match.dart';
import '../../../matches/presentation/widgets/match_event_dialog.dart';
import '../../../matches/providers/match_provider.dart';
import '../../../matches/data/models/match_event.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../../../core/api/api_client.dart';

class MatchReportScreen extends StatefulWidget {
  final String matchId;
  final String tournamentId;
  final TournamentMatch? match;
  /// The tournament team ID of the reporter's team (null for organizer-only access)
  final String? myTournamentTeamId;
  final String? myTeamId;
  final bool isHomeTeam;

  const MatchReportScreen({
    super.key,
    required this.matchId,
    required this.tournamentId,
    this.match,
    this.myTournamentTeamId,
    this.myTeamId,
    this.isHomeTeam = true,
  });

  @override
  State<MatchReportScreen> createState() => _MatchReportScreenState();
}

class _MatchReportScreenState extends State<MatchReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _homeScoreController = TextEditingController(text: '0');
  final _awayScoreController = TextEditingController(text: '0');
  final _homePenaltyController = TextEditingController(text: '0');
  final _awayPenaltyController = TextEditingController(text: '0');
  bool _isSubmittingScore = false;
  bool _isUpdatingStatus = false;
  TournamentMatch? _currentMatch;

  final Map<String, String> _playerNamesCache = {};
  final Map<String, Map<String, dynamic>> _playerStats = {};

  bool get _isPenaltyRequired {
    if (_currentMatch == null) return false;
    final isPlayoff = _currentMatch!.groupId == null || _currentMatch!.groupId!.isEmpty;
    if (!isPlayoff) return false;
    final homeScore = int.tryParse(_homeScoreController.text) ?? 0;
    final awayScore = int.tryParse(_awayScoreController.text) ?? 0;
    return homeScore == awayScore;
  }

  void _onScoreChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _currentMatch = widget.match;
    final user = context.read<AuthProvider>().user;
    final isOrganizer =
        user?.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
            user?.roles?.contains('ADMIN') == true;

    _homeScoreController.addListener(_onScoreChanged);
    _awayScoreController.addListener(_onScoreChanged);

    // Prefill scores
    if (_currentMatch != null) {
      _homeScoreController.text = _currentMatch!.homeScore.toString();
      _awayScoreController.text = _currentMatch!.awayScore.toString();
      _homePenaltyController.text = (_currentMatch!.homePenaltyScore ?? 0).toString();
      _awayPenaltyController.text = (_currentMatch!.awayPenaltyScore ?? 0).toString();
    }

    _tabController = TabController(
        length: isOrganizer ? 3 : 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshMatchDetails();
      await context.read<MatchProvider>().fetchMatchEvents(widget.matchId);
      await _autoSyncScoreFromEvents();
      _loadPlayerNames();
      if (widget.myTournamentTeamId != null) {
        context
            .read<TournamentSquadProvider>()
            .fetchSquad(widget.myTournamentTeamId!);
      }
    });
  }

  Future<void> _autoSyncScoreFromEvents() async {
    if (!mounted) return;
    final events = context.read<MatchProvider>().currentMatchEvents;
    int homeGoals = 0;
    int awayGoals = 0;

    for (final e in events) {
      if (e.eventType == EventType.GOAL || e.eventType == EventType.PENALTY_GOAL) {
        if (e.teamId == _currentMatch?.homeTeamId) {
          homeGoals++;
        } else if (e.teamId == _currentMatch?.awayTeamId) {
          awayGoals++;
        }
      }
    }

    setState(() {
      _homeScoreController.text = homeGoals.toString();
      _awayScoreController.text = awayGoals.toString();
    });

    try {
      await context.read<TournamentProvider>().updateMatchResult(
        widget.matchId,
        homeGoals,
        awayGoals,
      );
      await _refreshMatchDetails();
    } catch (_) {}
  }

  Future<void> _refreshMatchDetails() async {
    try {
      await context.read<TournamentProvider>().fetchTournamentMatches(widget.tournamentId);
      final updatedMatches = context.read<TournamentProvider>().matches;
      final match = updatedMatches.firstWhere((m) => m.id == widget.matchId);
      if (mounted) {
        setState(() {
          _currentMatch = match;
        });
        _loadPlayerNames();
      }
    } catch (e) {
      debugPrint("Error refreshing match: $e");
    }
  }

  Future<void> _startMatch() async {
    setState(() => _isUpdatingStatus = true);
    final success = await context.read<MatchProvider>().updateMatchStatus(widget.matchId, 'LIVE');
    setState(() => _isUpdatingStatus = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'match.match_live_status'.tr() : 'common.failed'.tr()),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) {
        await _refreshMatchDetails();
      }
    }
  }

  @override
  void dispose() {
    _homeScoreController.removeListener(_onScoreChanged);
    _awayScoreController.removeListener(_onScoreChanged);
    _tabController.dispose();
    _homeScoreController.dispose();
    _awayScoreController.dispose();
    _homePenaltyController.dispose();
    _awayPenaltyController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerNames() async {
    final homeId = _currentMatch?.homeTeamId;
    final awayId = _currentMatch?.awayTeamId;
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
    if (mounted) setState(() {});
  }

  bool get _isOrganizer {
    final user = context.read<AuthProvider>().user;
    return user?.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
        user?.roles?.contains('ADMIN') == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('tournament.match_report_title'.tr()),
        bottom: _isOrganizer
            ? TabBar(
                controller: _tabController,
                indicatorColor: PremiumTheme.neonGreen,
                labelColor: PremiumTheme.neonGreen,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                tabs: [
                  Tab(icon: const Icon(Icons.scoreboard, size: 20), text: 'match.report_tab_score'.tr()),
                  Tab(icon: const Icon(Icons.flash_on, size: 20), text: 'match.report_tab_timeline'.tr()),
                  Tab(icon: const Icon(Icons.bar_chart, size: 20), text: 'match.report_tab_stats'.tr()),
                ],
              )
            : TabBar(
                controller: _tabController,
                indicatorColor: PremiumTheme.neonGreen,
                labelColor: PremiumTheme.neonGreen,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                tabs: [
                  Tab(icon: const Icon(Icons.flash_on, size: 20), text: 'match.report_tab_timeline'.tr()),
                  Tab(icon: const Icon(Icons.bar_chart, size: 20), text: 'match.report_tab_stats'.tr()),
                ],
              ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (_isOrganizer) _buildScoreTab(),
          _buildLiveEventsTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildScoreTab() {
    final homeName = _currentMatch?.homeTeamName ?? 'tournament.home_label'.tr();
    final awayName = _currentMatch?.awayTeamName ?? 'tournament.away_label'.tr();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Board Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF122229), Color(0xFF0B1519)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  Text(
                    'match.match_result_header'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentMatch != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentMatch!.status == 'LIVE') ...[
                          const _PulsingLiveDot(),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentMatch!.status == 'LIVE'
                                ? Colors.redAccent.withOpacity(0.15)
                                : _currentMatch!.status == 'FINISHED'
                                    ? Colors.grey.withOpacity(0.15)
                                    : PremiumTheme.neonGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _currentMatch!.status == 'LIVE'
                                ? 'match.match_live_status'.tr().toUpperCase()
                                : _currentMatch!.status == 'FINISHED'
                                    ? 'match.full_time'.tr().toUpperCase()
                                    : 'match.scheduled'.tr().toUpperCase(),
                            style: TextStyle(
                              color: _currentMatch!.status == 'LIVE'
                                  ? Colors.redAccent
                                  : _currentMatch!.status == 'FINISHED'
                                      ? Colors.grey
                                      : PremiumTheme.neonGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Home Team Score Selector
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              homeName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            _buildScoreInput(_homeScoreController),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ':',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: PremiumTheme.neonGreen),
                        ),
                      ),
                      // Away Team Score Selector
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              awayName,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            _buildScoreInput(_awayScoreController),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isPenaltyRequired) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'ПЕНАЛЬТИ',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreInput(_homePenaltyController),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            ':',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ),
                        Expanded(
                          child: _buildScoreInput(_awayPenaltyController),
                        ),
                      ],
                    ),
                  ],
                  if (_currentMatch?.status == 'SCHEDULED') ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isUpdatingStatus ? null : _startMatch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: PremiumTheme.neonGreen.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUpdatingStatus)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              else
                                const Icon(Icons.play_circle_filled_rounded, color: Colors.black, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'match.start_match_btn'.tr().toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Forfeit / Technical Defeat options
            Text(
              'match.technical_defeat_header'.tr(),
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickScoreButton(
                    label: 'match.forfeit_away'.tr(),
                    onPressed: () {
                      _homeScoreController.text = '3';
                      _awayScoreController.text = '0';
                    },
                    isDanger: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickScoreButton(
                    label: 'match.forfeit_home'.tr(),
                    onPressed: () {
                      _homeScoreController.text = '0';
                      _awayScoreController.text = '3';
                    },
                    isDanger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildQuickScoreButton(
                    label: 'match.forfeit_both'.tr(),
                    onPressed: () {
                      _homeScoreController.text = '0';
                      _awayScoreController.text = '0';
                    },
                    isDanger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Score selector (common results)
            Text(
              'match.quick_score_header'.tr(),
              style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickScoreButton(
                  label: '1 : 0',
                  onPressed: () {
                    _homeScoreController.text = '1';
                    _awayScoreController.text = '0';
                  },
                ),
                _buildQuickScoreButton(
                  label: '2 : 0',
                  onPressed: () {
                    _homeScoreController.text = '2';
                    _awayScoreController.text = '0';
                  },
                ),
                _buildQuickScoreButton(
                  label: '2 : 1',
                  onPressed: () {
                    _homeScoreController.text = '2';
                    _awayScoreController.text = '1';
                  },
                ),
                _buildQuickScoreButton(
                  label: '3 : 1',
                  onPressed: () {
                    _homeScoreController.text = '3';
                    _awayScoreController.text = '1';
                  },
                ),
                _buildQuickScoreButton(
                  label: '0 : 1',
                  onPressed: () {
                    _homeScoreController.text = '0';
                    _awayScoreController.text = '1';
                  },
                ),
                _buildQuickScoreButton(
                  label: '0 : 2',
                  onPressed: () {
                    _homeScoreController.text = '0';
                    _awayScoreController.text = '2';
                  },
                ),
                _buildQuickScoreButton(
                  label: '1 : 2',
                  onPressed: () {
                    _homeScoreController.text = '1';
                    _awayScoreController.text = '2';
                  },
                ),
                _buildQuickScoreButton(
                  label: '1 : 3',
                  onPressed: () {
                    _homeScoreController.text = '1';
                    _awayScoreController.text = '3';
                  },
                ),
                _buildQuickScoreButton(
                  label: '1 : 1',
                  onPressed: () {
                    _homeScoreController.text = '1';
                    _awayScoreController.text = '1';
                  },
                ),
                _buildQuickScoreButton(
                  label: '2 : 2',
                  onPressed: () {
                    _homeScoreController.text = '2';
                    _awayScoreController.text = '2';
                  },
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Submit Button
            GestureDetector(
              onTap: _isSubmittingScore ? null : _submitScore,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: PremiumTheme.neonGreen.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmittingScore)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      else
                        const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'match.submit_result_btn'.tr().toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'tournament.score_will_update'.tr(),
                style: const TextStyle(color: Colors.white30, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScoreButton({required String label, required VoidCallback onPressed, bool isDanger = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDanger ? Colors.redAccent.withOpacity(0.06) : Colors.white.withOpacity(0.02),
        foregroundColor: isDanger ? Colors.redAccent : Colors.white,
        side: BorderSide(
          color: isDanger ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.08),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDanger ? Colors.redAccent : Colors.white70),
      ),
    );
  }

  Widget _buildScoreInput(TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            if (current > 0) {
              controller.text = (current - 1).toString();
            }
          },
        ),
        SizedBox(
          width: 40,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(4),
          icon: const Icon(Icons.add_circle_outline, color: PremiumTheme.neonGreen, size: 20),
          onPressed: () {
            final current = int.tryParse(controller.text) ?? 0;
            controller.text = (current + 1).toString();
          },
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (widget.myTournamentTeamId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'tournament.player_stats_info'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30),
          ),
        ),
      );
    }

    return Consumer<TournamentSquadProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.squad.isEmpty) {
          return Center(child: Text('tournament.no_squad_set'.tr(), style: const TextStyle(color: Colors.white54)));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.squad.length,
                itemBuilder: (context, index) {
                  final member = provider.squad[index];
                  return _buildPlayerStatRow(member);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _submitPlayerStats,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: PremiumTheme.neonGreen.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSubmittingScore)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        else
                          const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          'match.submit_stats_btn'.tr().toUpperCase(),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlayerStatRow(TournamentSquadMember member) {
    _playerStats.putIfAbsent(
      member.childProfileId,
      () => {
        'goals': 0,
        'assists': 0,
        'yellow_cards': 0,
        'red_cards': 0,
      },
    );
    final stats = _playerStats[member.childProfileId]!;

    return Card(
      color: const Color(0xFF122229),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: PremiumTheme.neonGreen.withOpacity(0.1),
                  child: Text(
                    member.jerseyNumber?.toString() ?? '?',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: PremiumTheme.neonGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (member.playerName ?? 'PLAYER').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
                if (member.position != null)
                  Chip(
                    label: Text(member.position!,
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCounter('match.stats_goals'.tr(), stats, 'goals'),
                _statCounter('match.stats_assists'.tr(), stats, 'assists'),
                _statCounter('match.stats_yellow'.tr(), stats, 'yellow_cards'),
                _statCounter('match.stats_red'.tr(), stats, 'red_cards'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCounter(
      String label, Map<String, dynamic> stats, String key) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  if ((stats[key] as int) > 0) stats[key] = stats[key] - 1;
                });
              },
              child: const Icon(Icons.remove, size: 16, color: Colors.white54),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                stats[key].toString(),
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  stats[key] = stats[key] + 1;
                });
              },
              child: const Icon(Icons.add, size: 16, color: PremiumTheme.neonGreen),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submitScore() async {
    final homeScore = int.tryParse(_homeScoreController.text) ?? 0;
    final awayScore = int.tryParse(_awayScoreController.text) ?? 0;

    int? homePenalty;
    int? awayPenalty;

    if (_isPenaltyRequired) {
      homePenalty = int.tryParse(_homePenaltyController.text) ?? 0;
      awayPenalty = int.tryParse(_awayPenaltyController.text) ?? 0;

      if (homePenalty == awayPenalty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Победитель по пенальти должен быть определен (счет серии не может быть равным)!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }
    }

    setState(() => _isSubmittingScore = true);
    final success = await context.read<TournamentProvider>().updateMatchResult(
          widget.matchId,
          homeScore,
          awayScore,
          homePenaltyScore: homePenalty,
          awayPenaltyScore: awayPenalty,
        );
    setState(() => _isSubmittingScore = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'tournament.score_will_update'.tr()
            : '${'common.failed'.tr()}: ${context.read<TournamentProvider>().error}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _submitPlayerStats() async {
    final matchProvider = context.read<MatchProvider>();
    int totalEvents = 0;

    _playerStats.forEach((pid, stats) {
      totalEvents += (stats['goals'] as int) + 
                    (stats['assists'] as int) + 
                    (stats['yellow_cards'] as int) + 
                    (stats['red_cards'] as int);
    });

    if (totalEvents == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('tournament.no_squad_set'.tr())),
      );
      return;
    }

    setState(() => _isSubmittingScore = true);

    try {
      for (var entry in _playerStats.entries) {
        final pid = entry.key;
        final stats = entry.value;

        Future<void> submitBatch(String type, int count) async {
          for (int i = 0; i < count; i++) {
            await matchProvider.addMatchEvent(widget.matchId, {
              'event_type': type,
              'minute': 0,
              'child_profile_id': pid,
              'team_id': widget.myTeamId,
            });
          }
        }

        if (stats['goals'] > 0) await submitBatch('GOAL', stats['goals']);
        if (stats['assists'] > 0) await submitBatch('ASSIST', stats['assists']);
        if (stats['yellow_cards'] > 0) await submitBatch('YELLOW_CARD', stats['yellow_cards']);
        if (stats['red_cards'] > 0) await submitBatch('RED_CARD', stats['red_cards']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('tournament.submit_player_stats'.tr()),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('tournament.error_message'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingScore = false);
    }
  }

  Widget _buildLiveEventsTab() {
    final matchProvider = context.watch<MatchProvider>();
    final rawEvents = matchProvider.currentMatchEvents;

    final allGrouped = _groupTimelineEvents(rawEvents);
    final firstHalfEvents = allGrouped.where((e) => e.minute <= 45).toList();
    final secondHalfEvents = allGrouped.where((e) => e.minute > 45).toList();

    return Column(
      children: [
        // Add Event Button Card
        Padding(
          padding: const EdgeInsets.all(16),
          child: PremiumCard(
            onTap: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (context) => MatchEventDialog(
                  matchId: widget.matchId,
                  homeTeamId: _currentMatch?.homeTeamId,
                  awayTeamId: _currentMatch?.awayTeamId,
                  homeTeamName: _currentMatch?.homeTeamName ?? 'Home Team',
                  awayTeamName: _currentMatch?.awayTeamName ?? 'Away Team',
                ),
              );
              if (result != null) {
                final success = await context.read<MatchProvider>().addMatchEvent(widget.matchId, result);
                if (success) {
                  await _autoSyncScoreFromEvents();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.read<MatchProvider>().error ?? 'Failed to add event'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle, color: PremiumTheme.neonGreen),
                const SizedBox(width: 12),
                Text(
                  'match.add_event_btn'.tr().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),

        // Live Events Timeline
        Expanded(
          child: matchProvider.isLoading && rawEvents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : allGrouped.isEmpty
                  ? Center(
                      child: Text(
                        'match.no_events'.tr(),
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  List<_TimelineGroupedItem> _groupTimelineEvents(List<MatchEvent> events) {
    final sortedEvents = List<MatchEvent>.from(events)..sort((a, b) => a.minute.compareTo(b.minute));
    final List<_TimelineGroupedItem> result = [];
    final Set<String> consumedIds = {};

    int homeScore = 0;
    int awayScore = 0;

    for (var i = 0; i < sortedEvents.length; i++) {
      final e = sortedEvents[i];
      if (consumedIds.contains(e.id)) continue;

      final isHome = e.teamId == _currentMatch?.homeTeamId;
      final pId = e.playerId ?? e.childProfileId;
      final pName = pId != null ? (_playerNamesCache[pId] ?? 'match.player_placeholder'.tr()) : 'match.player_placeholder'.tr();

      if (e.eventType == EventType.GOAL || e.eventType == EventType.PENALTY_GOAL) {
        if (isHome) homeScore++; else awayScore++;

        MatchEvent? assistEvent;
        for (var j = 0; j < sortedEvents.length; j++) {
          final candidate = sortedEvents[j];
          if (!consumedIds.contains(candidate.id) &&
              candidate.eventType == EventType.ASSIST &&
              candidate.minute == e.minute &&
              candidate.teamId == e.teamId &&
              candidate.id != e.id) {
            assistEvent = candidate;
            break;
          }
        }

        String? assistName;
        String? secId;
        if (assistEvent != null) {
          consumedIds.add(assistEvent.id);
          secId = assistEvent.id;
          final aId = assistEvent.playerId ?? assistEvent.childProfileId;
          if (aId != null) {
            assistName = _playerNamesCache[aId] ?? 'match.assistant_placeholder'.tr();
          }
        }

        result.add(_TimelineGroupedItem(
          id: e.id,
          secondaryId: secId,
          eventType: e.eventType,
          minute: e.minute,
          isHome: isHome,
          playerName: pName,
          assistantName: assistName,
          runningScore: "$homeScore - $awayScore",
        ));
        consumedIds.add(e.id);
      } else if (e.eventType == EventType.ASSIST) {
        result.add(_TimelineGroupedItem(
          id: e.id,
          eventType: e.eventType,
          minute: e.minute,
          isHome: isHome,
          playerName: pName,
          runningScore: "$homeScore - $awayScore",
        ));
        consumedIds.add(e.id);
      } else {
        result.add(_TimelineGroupedItem(
          id: e.id,
          eventType: e.eventType,
          minute: e.minute,
          isHome: isHome,
          playerName: pName,
          runningScore: "$homeScore - $awayScore",
        ));
        consumedIds.add(e.id);
      }
    }

    return result;
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

  Widget _buildTimelineEventRow(_TimelineGroupedItem item) {
    final isHome = item.isHome;

    String emoji = '⚽';
    if (item.eventType == EventType.YELLOW_CARD) emoji = '🟨';
    if (item.eventType == EventType.RED_CARD) emoji = '🟥';
    if (item.eventType == EventType.SUBSTITUTE) emoji = '🔄';

    final bool isGoal = item.eventType == EventType.GOAL || item.eventType == EventType.PENALTY_GOAL;

    Widget buildScoreBadge() {
      if (!isGoal) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isHome ? PremiumTheme.neonGreen : Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          item.runningScore,
          style: TextStyle(
            color: isHome ? Colors.black : Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      );
    }

    Widget buildMinuteBadge() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          "${item.minute}'",
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      );
    }

    final Widget playerNamesCol = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isHome ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          item.playerName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        if (item.assistantName != null) ...[
          const SizedBox(height: 1),
          Text(
            'match.pass_label'.tr(namedArgs: {'name': item.assistantName!}),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10.5, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );

    final contentWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isHome) ...[
          buildMinuteBadge(),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 14)),
          buildScoreBadge(),
          const SizedBox(width: 6),
          Flexible(child: playerNamesCol),
        ] else ...[
          Flexible(child: playerNamesCol),
          const SizedBox(width: 6),
          buildScoreBadge(),
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          buildMinuteBadge(),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (_isOrganizer ? 0.78 : 0.88)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: contentWidget,
          ),
          if (_isOrganizer) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF122229),
                    title: Text('match.delete_event_title'.tr(), style: const TextStyle(color: Colors.white)),
                    content: Text('match.delete_event_confirm'.tr(), style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white38))),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: Text('match.delete_btn'.tr(), style: const TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context.read<MatchProvider>().deleteMatchEvent(widget.matchId, item.id);
                  if (item.secondaryId != null) {
                    await context.read<MatchProvider>().deleteMatchEvent(widget.matchId, item.secondaryId!);
                  }
                  await _autoSyncScoreFromEvents();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingLiveDot extends StatefulWidget {
  const _PulsingLiveDot();

  @override
  State<_PulsingLiveDot> createState() => _PulsingLiveDotState();
}

class _PulsingLiveDotState extends State<_PulsingLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TimelineGroupedItem {
  final String id;
  final String? secondaryId;
  final EventType eventType;
  final int minute;
  final bool isHome;
  final String playerName;
  final String? assistantName;
  final String runningScore;

  _TimelineGroupedItem({
    required this.id,
    this.secondaryId,
    required this.eventType,
    required this.minute,
    required this.isHome,
    required this.playerName,
    this.assistantName,
    required this.runningScore,
  });
}
