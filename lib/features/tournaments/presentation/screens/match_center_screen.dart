import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../matches/data/models/match_event.dart';
import '../../../matches/data/models/match.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../teams/providers/team_provider.dart';
import '../widgets/shareable_match_card_dialog.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import '../../../teams/data/models/player_team.dart';
import '../../../lineups/presentation/screens/lineup_screen.dart';
import '../../../auth/providers/auth_provider.dart';

class MatchCenterScreen extends StatefulWidget {
  final String matchId;
  final String? tournamentId;
  final String? coachedTeamId;
  final String? coachedTeamName;
  final List<PlayerTeam> players;
  final bool? lineupSubmitted;

  const MatchCenterScreen({
    Key? key,
    required this.matchId,
    this.tournamentId,
    this.coachedTeamId,
    this.coachedTeamName,
    this.players = const [],
    this.lineupSubmitted,
  }) : super(key: key);

  @override
  State<MatchCenterScreen> createState() => _MatchCenterScreenState();
}

class _MatchCenterScreenState extends State<MatchCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StatsApiService _statsApi = StatsApiService();
  late MatchRepository _matchRepository;
  
  MatchModel? _match;
  bool _isLoadingMatch = true;
  String? _matchError;
  String? _fieldName;

  // Selected team for visual lineup pitch (true = home, false = away)
  bool _viewHomeLineup = true;

  final GlobalKey _repaintKey = GlobalKey();
  String _homeTeamName = 'КОМАНДА ХОЗЯЕВ';
  String _awayTeamName = 'КОМАНДА ГОСТЕЙ';

  /// Map of childProfileId / playerId -> display name
  final Map<String, String> _playerNamesCache = {};
  Timer? _liveSyncTimer;
  bool? _lineupSubmittedState;

  @override
  void initState() {
    super.initState();
    _lineupSubmittedState = widget.lineupSubmitted;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _matchRepository = MatchRepository(ApiClient());
    _loadMatchData();
    _startLiveSyncTimer();
  }

  void _startLiveSyncTimer() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _match != null) {
        _refreshLiveState();
      }
    });
  }

  Future<void> _refreshLiveState() async {
    try {
      final matchData = await _matchRepository.getMatchById(widget.matchId);
      if (mounted) {
        setState(() {
          _match = matchData;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMatchData() async {
    try {
      final matchData = await _matchRepository.getMatchById(widget.matchId);
      setState(() {
        _match = matchData;
        if (widget.coachedTeamId != null && matchData.awayTeamId == widget.coachedTeamId) {
          _viewHomeLineup = false;
        }
      });
      // Fetch lineups
      if (mounted) {
        final lineupProvider = context.read<LineupProvider>();
        if (matchData.homeTeamId != null) lineupProvider.fetchTeamLineup(widget.matchId, matchData.homeTeamId!);
        if (matchData.awayTeamId != null) lineupProvider.fetchTeamLineup(widget.matchId, matchData.awayTeamId!);
        if (widget.coachedTeamId != null) lineupProvider.fetchTeamLineup(widget.matchId, widget.coachedTeamId!);
      }
      
      // Fetch team names
      if (mounted) {
        final teamProvider = context.read<TeamProvider>();
        final homeTeam = matchData.homeTeamId != null ? await teamProvider.fetchTeamById(matchData.homeTeamId!) : null;
        final awayTeam = matchData.awayTeamId != null ? await teamProvider.fetchTeamById(matchData.awayTeamId!) : null;
        if (mounted) {
          setState(() {
            if (homeTeam != null) _homeTeamName = homeTeam.name;
            if (awayTeam != null) _awayTeamName = awayTeam.name;
            _isLoadingMatch = false;
          });
          // Load player names for lineup display
          _loadPlayerNames(matchData.homeTeamId, matchData.awayTeamId);
        }
      }

      // Fetch field name
      try {
        if (mounted) {
          final apiClient = context.read<ApiClient>();
          final res = await apiClient.get('/matches/${widget.matchId}');
          if (res.statusCode == 200 && res.data != null) {
            if (mounted) {
              setState(() {
                _fieldName = res.data['field_name'];
              });
            }
          }
        }
      } catch (e) {
        // Ignore field name fetch error
      }
    } catch (e) {
      setState(() {
        _matchError = e.toString();
        _isLoadingMatch = false;
      });
    }
  }

  /// Fetches player names from /teams/{teamId}/players for both sides
  Future<void> _loadPlayerNames(String? homeTeamId, String? awayTeamId) async {
    final apiClient = context.read<ApiClient>();

    Future<void> fetchForTeam(String? teamId) async {
      if (teamId == null) return;
      try {
        final res = await apiClient.get('/teams/$teamId/players');
        if (res.statusCode == 200 && res.data is List) {
          for (var item in res.data) {
            final pId = item['child_profile_id'] ?? item['player_id'];
            final name = item['player_name'] ?? item['player']?['name'];
            if (pId != null && name != null) {
              if (mounted) _playerNamesCache[pId.toString()] = name.toString();
            }
          }
        }
      } catch (_) {}
    }

    await fetchForTeam(homeTeamId);
    await fetchForTeam(awayTeamId);
    if (mounted) setState(() {});
  }

  Future<void> _shareMatchCard() async {
    try {
      RenderRepaintBoundary? boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      Uint8List pngBytes = byteData.buffer.asUint8List();

      if (mounted && _match != null) {
        showDialog(
          context: context,
          builder: (context) => ShareableMatchCardDialog(
            pngBytes: pngBytes,
            homeTeamName: _homeTeamName,
            awayTeamName: _awayTeamName,
            homeScore: _match!.homeScore ?? 0,
            awayScore: _match!.awayScore ?? 0,
            status: _match!.status,
            matchDate: _match!.matchDate,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта карточки: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _liveSyncTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMatch) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00E676)),
        ),
      );
    }

    if (_matchError != null || _match == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F1D),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Ошибка загрузки матча: ${_matchError ?? "Неизвестная ошибка"}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final match = _match!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'match.match_center'.tr().toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildScoreboardCard(match),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLineupsTab(match),
                _buildTimelineTab(match),
                _buildInfoTab(match),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboardCard(MatchModel match) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
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
                Expanded(child: _buildTeamHeader(_homeTeamName, Colors.redAccent)),
                _buildMiddleScore(match),
                Expanded(child: _buildTeamHeader(_awayTeamName, Colors.blueAccent)),
              ],
            ),
            const SizedBox(height: 24),
            _buildMatchMeta(match),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
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
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
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
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildMiddleScore(MatchModel match) {
    final bool isLive = match.status == 'LIVE';
    final bool isFinished = match.status == 'FINISHED';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            isFinished || isLive
                ? '${match.homeScore ?? 0} : ${match.awayScore ?? 0}'
                : 'VS',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isLive ? Colors.redAccent.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isLive ? 'LIVE' : (isFinished ? 'match.status_finished'.tr().toUpperCase() : 'match.status_scheduled'.tr().toUpperCase()),
            style: TextStyle(
              color: isLive ? Colors.redAccent : Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchMeta(MatchModel match) {
    final dateStr = match.matchDate != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(match.matchDate!)
        : 'TBD';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          dateStr,
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 20),
        const Icon(Icons.location_on_outlined, size: 14, color: Colors.white38),
        const SizedBox(width: 8),
        Text(
          _fieldName ?? 'ARENA CENTER',
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final user = context.watch<AuthProvider>().user;
    final bool isCoach = widget.coachedTeamId != null || (user?.roles?.any((r) => r == 'COACH' || r == 'TEAM_OWNER') ?? false);

    return Column(
      children: [
        if (isCoach && widget.coachedTeamId != null) ...[
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LineupScreen(
                    matchId: widget.matchId,
                    teamId: widget.coachedTeamId,
                    teamName: widget.coachedTeamName ?? _homeTeamName,
                    opponent: _awayTeamName,
                    players: widget.players,
                  ),
                ),
              );
              if (result == true || result != null) {
                setState(() => _lineupSubmittedState = true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (_lineupSubmittedState == true)
                    ? PremiumTheme.electricBlue
                    : PremiumTheme.amber,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_lineupSubmittedState == true ? PremiumTheme.electricBlue : PremiumTheme.amber).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_lineupSubmittedState == true) ? Icons.edit_note_rounded : Icons.assignment_turned_in_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (_lineupSubmittedState == true) ? 'Изменить заявку' : 'Подать заявку (Submit Squad)',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCircleAction(Icons.analytics_outlined, 'match.stats'.tr(), () {
              _tabController.animateTo(1);
            }),
            const SizedBox(width: 24),
            _buildCircleAction(Icons.videocam_outlined, 'match.replay'.tr(), null),
            const SizedBox(width: 24),
            _buildCircleAction(Icons.share_outlined, 'match.share'.tr(), () {
              _shareMatchCard();
            }),
          ],
        ),
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
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: onTap != null ? Colors.white : Colors.white24, size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(label.toUpperCase(), style: TextStyle(color: onTap != null ? Colors.white54 : Colors.white24, fontSize: 9, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _tabController.animateTo(0);
              });
            },
            child: _buildTab('match.tab_lineups'.tr(), _tabController.index == 0),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _tabController.animateTo(1);
              });
            },
            child: _buildTab('match.tab_timeline'.tr(), _tabController.index == 1),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _tabController.animateTo(2);
              });
            },
            child: _buildTab('match.tab_details'.tr(), _tabController.index == 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: active ? PremiumTheme.neonGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PremiumTheme.neonGreen : Colors.white10),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: active ? Colors.black : Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLineupsTab(MatchModel match) {
    final lineupProvider = context.watch<LineupProvider>();
    final targetTeamId = _viewHomeLineup ? match.homeTeamId : match.awayTeamId;
    MatchLineup? lineup = targetTeamId != null ? lineupProvider.getLineupForMatch(widget.matchId, targetTeamId) : null;
    if (lineup == null && widget.coachedTeamId != null) {
      final isCoachedTarget = (_viewHomeLineup && match.homeTeamId == widget.coachedTeamId) ||
          (!_viewHomeLineup && match.awayTeamId == widget.coachedTeamId) ||
          (match.homeTeamId == null || match.awayTeamId == null);
      if (isCoachedTarget) {
        lineup = lineupProvider.getLineupForMatch(widget.matchId, widget.coachedTeamId!);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Home / Away Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamTabButton('match.home'.tr(), _viewHomeLineup, () {
                setState(() => _viewHomeLineup = true);
              }),
              const SizedBox(width: 12),
              _buildTeamTabButton('match.away'.tr(), !_viewHomeLineup, () {
                setState(() => _viewHomeLineup = false);
              }),
            ],
          ),
          const SizedBox(height: 16),
          
          if (lineup == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF161F37).withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.groups_outlined, size: 48, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'Состав команды еще не отправлен',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            _buildVisualPitch(lineup),
            const SizedBox(height: 24),
            _buildLineupListSection(lineup),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamTabButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00E676).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00E676) : Colors.white24,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? const Color(0xFF00E676) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualPitch(MatchLineup lineup) {
    final starters = lineup.players.where((p) => p.isStarting).toList();

    // Check if players have custom relative coordinates pos_x / pos_y
    final bool hasCustomCoords = starters.any((p) => p.posX != null && p.posY != null);

    return AspectRatio(
      aspectRatio: 0.75, // Standard football pitch aspect ratio
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3516), Color(0xFF0D1D09)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            if (hasCustomCoords) {
              return Stack(
                children: [
                  // Pitch markings
                  Positioned(
                    left: 0, right: 0, top: h / 2,
                    child: Container(height: 1, color: Colors.white12),
                  ),
                  Center(
                    child: Container(
                      width: w * 0.25,
                      height: w * 0.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 1.5),
                      ),
                    ),
                  ),
                  // Render each player token at custom coordinates
                  ...starters.map((p) {
                    final double px = (p.posX ?? 0.5) * w;
                    final double py = (p.posY ?? 0.5) * h;
                    return Positioned(
                      left: px - 25,
                      top: py - 25,
                      width: 50,
                      child: _buildPlayerToken(p),
                    );
                  }).toList(),
                ],
              );
            }

            // Fallback layout based on default position groupings
            bool isDef(String? pos) {
              if (pos == null) return false;
              final u = pos.toUpperCase();
              return u.startsWith('DEF') || u.startsWith('DF') || u == 'CB' || u == 'LB' || u == 'RB';
            }
            bool isMid(String? pos) {
              if (pos == null) return false;
              final u = pos.toUpperCase();
              return u.startsWith('MID') || u.startsWith('MF') || u == 'CM' || u == 'CAM' || u == 'CDM' || u == 'DM' || u == 'LM' || u == 'RM';
            }
            bool isFwd(String? pos) {
              if (pos == null) return false;
              final u = pos.toUpperCase();
              return u.startsWith('FW') || u == 'ST' || u == 'LW' || u == 'RW';
            }

            final gks = starters.where((p) => p.position?.toUpperCase() == 'GK').toList();
            final dfs = starters.where((p) => isDef(p.position)).toList();
            final mfs = starters.where((p) => isMid(p.position)).toList();
            final fws = starters.where((p) => isFwd(p.position)).toList();

            // Catch any unclassified starters
            String pKey(LineupPlayer p) => p.childProfileId ?? p.playerId ?? p.jerseyNumber?.toString() ?? '';
            final categorizedIds = {...gks, ...dfs, ...mfs, ...fws}.map((p) => pKey(p)).toSet();
            final unclassified = starters.where((p) => !categorizedIds.contains(pKey(p))).toList();
            if (unclassified.isNotEmpty) {
              mfs.addAll(unclassified);
            }

            return Stack(
              children: [
                // Pitch markings
                Positioned(
                  left: 0, right: 0, top: h / 2,
                  child: Container(height: 1, color: Colors.white12),
                ),
                Center(
                  child: Container(
                    width: w * 0.25,
                    height: w * 0.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white12, width: 1.5),
                    ),
                  ),
                ),
                // GK position
                _positionPlayers(gks, h * 0.78, w),
                // DF positions
                _positionPlayers(dfs, h * 0.56, w),
                // MF positions
                _positionPlayers(mfs, h * 0.34, w),
                // FW positions
                _positionPlayers(fws, h * 0.12, w),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerToken(LineupPlayer p) {
    // Resolve name: use playerName from model, then cache lookup, then jersey number fallback
    final key = p.childProfileId ?? p.playerId ?? '';
    final resolvedName = p.playerName
        ?? _playerNamesCache[key]
        ?? (p.jerseyNumber != null ? '#${p.jerseyNumber}' : 'P');
    // Show only the first word of the name for the pitch token
    final shortName = resolvedName.split(' ').first.toUpperCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E676), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            p.jerseyNumber != null ? '${p.jerseyNumber}' : '#',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _positionPlayers(List<LineupPlayer> players, double topPosition, double pitchWidth) {
    if (players.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      top: topPosition,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((p) => SizedBox(
          width: 50,
          child: _buildPlayerToken(p),
        )).toList(),
      ),
    );
  }

  Widget _buildLineupListSection(MatchLineup lineup) {
    final starters = lineup.players.where((p) => p.isStarting).toList();
    final bench = lineup.players.where((p) => !p.isStarting).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'СТАРТОВЫЙ СОСТАВ',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        ...starters.map((p) => _buildPlayerListItem(p)),
        const SizedBox(height: 16),
        const Text(
          'ЗАПАСНЫЕ ИГРОКИ',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        if (bench.isEmpty)
          const Text('Нет запасных игроков', style: TextStyle(color: Colors.white30, fontSize: 11))
        else
          ...bench.map((p) => _buildPlayerListItem(p)),
      ],
    );
  }

  Widget _buildPlayerListItem(LineupPlayer p) {
    final key = p.childProfileId ?? p.playerId ?? '';
    final resolvedName = p.playerName
        ?? _playerNamesCache[key]
        ?? (p.jerseyNumber != null ? 'Player #${p.jerseyNumber}' : 'Unknown Player');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161F37).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p.position ?? '?',
              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(width: 12),
          if (p.jerseyNumber != null) ...[
            Text(
              '#${p.jerseyNumber}',
              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              resolvedName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(MatchModel match) {
    return FutureBuilder<List<MatchEvent>>(
      future: _statsApi.getMatchEvents(widget.matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
        }
        final rawEvents = snapshot.data ?? [];
        final groupedItems = _groupEventsForMatchCenter(rawEvents, match);

        if (groupedItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline_rounded, size: 48, color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                const Text(
                  'Событий в матче пока нет',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: groupedItems.length,
          itemBuilder: (context, index) {
            final item = groupedItems[index];
            return _buildTimelineEventItem(item, index == groupedItems.length - 1);
          },
        );
      },
    );
  }

  List<_MatchCenterGroupedItem> _groupEventsForMatchCenter(List<MatchEvent> events, MatchModel match) {
    final sortedEvents = List<MatchEvent>.from(events)..sort((a, b) => a.minute.compareTo(b.minute));
    final List<_MatchCenterGroupedItem> result = [];
    final Set<String> consumedIds = {};

    int homeScore = 0;
    int awayScore = 0;

    for (var i = 0; i < sortedEvents.length; i++) {
      final e = sortedEvents[i];
      if (consumedIds.contains(e.id)) continue;

      final isHome = e.teamId == match.homeTeamId;
      final key = e.childProfileId ?? e.playerId ?? '';
      final pName = _playerNamesCache[key] ?? (key.isNotEmpty ? 'Player' : 'Unknown');

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
        if (assistEvent != null) {
          consumedIds.add(assistEvent.id);
          final aKey = assistEvent.childProfileId ?? assistEvent.playerId ?? '';
          assistName = _playerNamesCache[aKey];
        }

        result.add(_MatchCenterGroupedItem(
          eventType: e.eventType,
          minute: e.minute,
          playerName: pName,
          assistantName: assistName,
          runningScore: "$homeScore - $awayScore",
          isHome: isHome,
        ));
        consumedIds.add(e.id);
      } else if (e.eventType == EventType.ASSIST) {
        result.add(_MatchCenterGroupedItem(
          eventType: e.eventType,
          minute: e.minute,
          playerName: pName,
          runningScore: "$homeScore - $awayScore",
          isHome: isHome,
        ));
        consumedIds.add(e.id);
      } else {
        result.add(_MatchCenterGroupedItem(
          eventType: e.eventType,
          minute: e.minute,
          playerName: pName,
          runningScore: "$homeScore - $awayScore",
          isHome: isHome,
        ));
        consumedIds.add(e.id);
      }
    }

    return result;
  }

  Widget _buildTimelineEventItem(_MatchCenterGroupedItem item, bool isLast) {
    IconData icon = Icons.sports_soccer;
    Color iconColor = Colors.white54;
    String titleText = '';

    switch (item.eventType) {
      case EventType.GOAL:
      case EventType.PENALTY_GOAL:
        icon = Icons.sports_soccer;
        iconColor = const Color(0xFF00E676);
        titleText = item.eventType == EventType.PENALTY_GOAL ? 'Penalty goal! ⚽️ (${item.runningScore})' : 'Гол! ⚽️ (${item.runningScore})';
        break;
      case EventType.YELLOW_CARD:
        icon = Icons.portrait_rounded;
        iconColor = const Color(0xFFFFD700);
        titleText = 'Желтая карточка 🟨';
        break;
      case EventType.RED_CARD:
        icon = Icons.portrait_rounded;
        iconColor = Colors.redAccent;
        titleText = 'Красная карточка 🟥';
        break;
      case EventType.ASSIST:
        icon = Icons.help_outline_rounded;
        iconColor = Colors.blueAccent;
        titleText = 'Голевая передача 👟';
        break;
      case EventType.SAVE:
        icon = Icons.shield_outlined;
        iconColor = Colors.tealAccent;
        titleText = 'Сейв 🧭';
        break;
      case EventType.SUBSTITUTE:
        icon = Icons.swap_horiz_rounded;
        iconColor = Colors.orangeAccent;
        titleText = 'Замена 🔄';
        break;
    }

    String displayPlayer = item.playerName;
    if (item.assistantName != null) {
      displayPlayer += ' (${item.assistantName})';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        Container(
          width: 32,
          margin: const EdgeInsets.only(top: 2),
          child: Text(
            "${item.minute}'",
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        // Line & node column
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withOpacity(0.5), width: 1.5),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 48,
                color: Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content details
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F37).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  displayPlayer,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(MatchModel match) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildInfoRow('Статус', match.status),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Дата матча', match.matchDate != null ? DateFormat('dd MMMM yyyy HH:mm').format(match.matchDate!.toLocal()) : 'Не определена'),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Раунд/Тур', match.roundNumber != null ? '${match.roundNumber}' : 'Не определен'),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Турнир ID', match.tournamentId ?? 'Не привязан'),
          const Divider(color: Colors.white10, height: 24),
          _buildInfoRow('Дивизион ID', match.divisionId ?? 'Не привязан'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MatchCenterGroupedItem {
  final EventType eventType;
  final int minute;
  final String playerName;
  final String? assistantName;
  final String runningScore;
  final bool isHome;

  _MatchCenterGroupedItem({
    required this.eventType,
    required this.minute,
    required this.playerName,
    this.assistantName,
    required this.runningScore,
    required this.isHome,
  });
}
