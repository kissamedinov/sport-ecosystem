import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../matches/data/models/match_event.dart';
import '../../../matches/data/models/match_award.dart';
import '../../../matches/data/models/match.dart';
import '../../../lineups/providers/lineup_provider.dart';
import '../../../lineups/models/lineup.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../teams/providers/team_provider.dart';
import '../widgets/shareable_match_card_dialog.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class MatchCenterScreen extends StatefulWidget {
  final String matchId;
  final String tournamentId;

  const MatchCenterScreen({
    Key? key,
    required this.matchId,
    required this.tournamentId,
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

  // Selected team for visual lineup pitch (true = home, false = away)
  bool _viewHomeLineup = true;

  final GlobalKey _repaintKey = GlobalKey();
  String _homeTeamName = 'КОМАНДА ХОЗЯЕВ';
  String _awayTeamName = 'КОМАНДА ГОСТЕЙ';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _matchRepository = MatchRepository(ApiClient());
    _loadMatchData();
  }

  Future<void> _loadMatchData() async {
    try {
      final matchData = await _matchRepository.getMatchById(widget.matchId);
      setState(() {
        _match = matchData;
      });
      // Fetch lineups
      if (mounted) {
        final lineupProvider = context.read<LineupProvider>();
        lineupProvider.fetchTeamLineup(widget.matchId, matchData.homeTeamId);
        lineupProvider.fetchTeamLineup(widget.matchId, matchData.awayTeamId);
      }
      
      // Fetch team names
      if (mounted) {
        final teamProvider = context.read<TeamProvider>();
        final homeTeam = await teamProvider.fetchTeamById(matchData.homeTeamId);
        final awayTeam = await teamProvider.fetchTeamById(matchData.awayTeamId);
        if (mounted) {
          setState(() {
            if (homeTeam != null) _homeTeamName = homeTeam.name;
            if (awayTeam != null) _awayTeamName = awayTeam.name;
            _isLoadingMatch = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _matchError = e.toString();
        _isLoadingMatch = false;
      });
    }
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          'МАТЧ-ЦЕНТР'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareMatchCard,
          ),
        ],
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
    final bool isLive = match.status == 'LIVE';
    final bool isFinished = match.status == 'FINISHED';

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0F1D),
        ),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161F37),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2640), Color(0xFF0B111E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home Team
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.shield, size: 32, color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _homeTeamName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Score
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          isFinished || isLive
                              ? '${match.homeScore} - ${match.awayScore}'
                              : 'VS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLive 
                              ? const Color(0xFF00E676).withOpacity(0.15) 
                              : Colors.blueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLive ? 'LIVE' : (isFinished ? 'ЗАВЕРШЕН' : 'ЗАПЛАНИРОВАН'),
                          style: TextStyle(
                            color: isLive ? const Color(0xFF00E676) : Colors.blueAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Away Team
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.shield, size: 32, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _awayTeamName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F37).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF2979FF),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: 'Составы'),
          Tab(text: 'События'),
          Tab(text: 'Детали'),
        ],
      ),
    );
  }

  Widget _buildLineupsTab(MatchModel match) {
    final lineupProvider = context.watch<LineupProvider>();
    final targetTeamId = _viewHomeLineup ? match.homeTeamId : match.awayTeamId;
    final lineup = lineupProvider.getLineupForMatch(widget.matchId, targetTeamId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Home / Away Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTeamTabButton('Хозяева', _viewHomeLineup, () {
                setState(() => _viewHomeLineup = true);
              }),
              const SizedBox(width: 12),
              _buildTeamTabButton('Гости', !_viewHomeLineup, () {
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
            final gks = starters.where((p) => p.position == 'GK').toList();
            final dfs = starters.where((p) => p.position == 'DF').toList();
            final mfs = starters.where((p) => p.position == 'MF').toList();
            final fws = starters.where((p) => p.position == 'FW').toList();

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
                _positionPlayers(gks, h * 0.85, w),
                // DF positions
                _positionPlayers(dfs, h * 0.65, w),
                // MF positions
                _positionPlayers(mfs, h * 0.40, w),
                // FW positions
                _positionPlayers(fws, h * 0.15, w),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerToken(LineupPlayer p) {
    final name = p.playerId != null && p.playerId!.length > 5 
        ? 'Игрок ${p.playerId!.substring(0, 5)}'
        : 'Игрок';
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
            name,
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
          Expanded(
            child: Text(
              p.playerId != null && p.playerId!.length > 8 
                  ? 'Игрок ${p.playerId!.substring(0, 8)}'
                  : 'Игрок',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (p.jerseyNumber != null)
            Text(
              '#${p.jerseyNumber}',
              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12),
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
        final events = snapshot.data ?? [];
        if (events.isEmpty) {
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

        // Sort events by minute
        events.sort((a, b) => a.minute.compareTo(b.minute));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildTimelineEventItem(event, index == events.length - 1);
          },
        );
      },
    );
  }

  Widget _buildTimelineEventItem(MatchEvent event, bool isLast) {
    IconData icon;
    Color iconColor;
    String titleText = '';

    switch (event.eventType) {
      case 'GOAL':
        icon = Icons.sports_soccer;
        iconColor = const Color(0xFF00E676);
        titleText = 'Гол! ⚽';
        break;
      case 'YELLOW_CARD':
        icon = Icons.portrait_rounded;
        iconColor = const Color(0xFFFFD700);
        titleText = 'Желтая карточка 🟨';
        break;
      case 'RED_CARD':
        icon = Icons.portrait_rounded;
        iconColor = Colors.redAccent;
        titleText = 'Красная карточка 🟥';
        break;
      case 'ASSIST':
        icon = Icons.help_outline_rounded;
        iconColor = Colors.blueAccent;
        titleText = 'Голевая передача 👟';
        break;
      default:
        icon = Icons.sports_soccer;
        iconColor = Colors.white54;
        titleText = 'Событие';
    }

    final playerName = event.childProfileId != null && event.childProfileId!.length > 6
        ? 'Игрок ${event.childProfileId!.substring(0, 6)}'
        : 'Игрок';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        Container(
          width: 32,
          margin: const EdgeInsets.only(top: 2),
          child: Text(
            "${event.minute}'",
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
                  playerName,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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
