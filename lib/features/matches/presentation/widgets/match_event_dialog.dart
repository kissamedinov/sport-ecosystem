import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/api/api_client.dart';

class MatchEventDialog extends StatefulWidget {
  final String matchId;
  final String? homeTeamId;
  final String? awayTeamId;
  final String homeTeamName;
  final String awayTeamName;

  const MatchEventDialog({
    super.key,
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  @override
  State<MatchEventDialog> createState() => _MatchEventDialogState();
}

class _MatchEventDialogState extends State<MatchEventDialog> {
  String _selectedType = 'GOAL';
  String? _selectedTeamId;
  final _minuteController = TextEditingController();
  
  List<dynamic> _teamPlayers = [];
  List<dynamic> _lineupPlayers = [];
  bool _isLoadingPlayers = false;
  String? _lineupWarning;
  String? _selectedPlayerId;
  String? _selectedChildProfileId;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.homeTeamId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPlayersForSelectedTeam();
    });
  }

  @override
  void dispose() {
    _minuteController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayersForSelectedTeam() async {
    if (_selectedTeamId == null) return;
    setState(() {
      _isLoadingPlayers = true;
      _lineupWarning = null;
      _teamPlayers = [];
      _lineupPlayers = [];
      _selectedPlayerId = null;
      _selectedChildProfileId = null;
    });

    try {
      final apiClient = context.read<ApiClient>();

      // 1. Fetch team players
      final playersResponse = await apiClient.get('/teams/$_selectedTeamId/players');
      List<dynamic> fetchedTeamPlayers = [];
      if (playersResponse.statusCode == 200 && playersResponse.data is List) {
        fetchedTeamPlayers = playersResponse.data;
      }

      // 2. Fetch match lineup
      List<dynamic> lineupPlayersList = [];
      bool hasLineup = false;
      try {
        final lineupRes = await apiClient.get('/matches/${widget.matchId}/lineup/$_selectedTeamId');
        if (lineupRes.statusCode == 200 && lineupRes.data != null) {
          final playersData = lineupRes.data['players'];
          if (playersData is List) {
            lineupPlayersList = playersData;
            hasLineup = true;
          }
        }
      } catch (e) {
        hasLineup = false;
      }

      if (!mounted) return;

      setState(() {
        _teamPlayers = fetchedTeamPlayers;
        if (hasLineup) {
          // Filter team players to only include those in the lineup
          _lineupPlayers = fetchedTeamPlayers.where((tp) {
            final tpPlayerId = tp['player_id'];
            final tpChildId = tp['child_profile_id'];
            return lineupPlayersList.any((lp) =>
                (tpPlayerId != null && lp['player_id'] == tpPlayerId) ||
                (tpChildId != null && lp['child_profile_id'] == tpChildId));
          }).toList();

          if (_lineupPlayers.isEmpty) {
            _lineupWarning = 'match.lineup_empty_warning'.tr();
          }
        } else {
          _lineupPlayers = fetchedTeamPlayers;
          _lineupWarning = 'match.lineup_missing_warning'.tr();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _lineupWarning = 'match.players_load_error'.tr(namedArgs: {'error': e.toString()});
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF122028),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: PremiumTheme.neonGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'match.event_dialog_title'.tr(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Event Type Selector (Grid of cards)
              Text(
                'match.event_type'.tr().toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
                children: [
                  _buildEventTypeCard('GOAL', '⚽', 'match.event_goal'.tr(), const Color(0xFF00E676)),
                  _buildEventTypeCard('YELLOW_CARD', '🟨', 'match.event_yellow_card'.tr(), const Color(0xFFFFB300)),
                  _buildEventTypeCard('RED_CARD', '🟥', 'match.event_red_card'.tr(), const Color(0xFFFF5252)),
                  _buildEventTypeCard('SUBSTITUTION', '🔄', 'match.event_substitution'.tr(), const Color(0xFF00E5FF)),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Team Switcher (Segmented Tabs)
              Text(
                'match.team'.tr().toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTeamTab(widget.homeTeamId, widget.homeTeamName),
                    ),
                    Expanded(
                      child: _buildTeamTab(widget.awayTeamId, widget.awayTeamName),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Minute Input
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'match.minute'.tr().toUpperCase(),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _minuteController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.3),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            hintText: '45',
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: PremiumTheme.neonGreen, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 4. Player Selection Dropdown (with isExpanded)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'match.player'.tr().toUpperCase(),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingPlayers)
                          Container(
                            height: 48,
                            alignment: Alignment.center,
                            child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: PremiumTheme.neonGreen)),
                          )
                        else
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                dropdownColor: const Color(0xFF162832),
                                value: _selectedPlayerId ?? _selectedChildProfileId,
                                hint: Text('match.select_player_hint'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 12), overflow: TextOverflow.ellipsis),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                items: _lineupPlayers.map<DropdownMenuItem<String>>((p) {
                                  final id = p['player_id'] ?? p['child_profile_id'] ?? '';
                                  final name = p['player_name'] ?? p['player']?['name'] ?? 'match.no_name'.tr();
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Text(name, overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    final pObj = _lineupPlayers.firstWhere((p) => (p['player_id'] == val || p['child_profile_id'] == val));
                                    _selectedPlayerId = pObj['player_id'];
                                    _selectedChildProfileId = pObj['child_profile_id'];
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_lineupWarning != null) ...[
                const SizedBox(height: 8),
                Text(
                  _lineupWarning!,
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'common.cancel'.tr(),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: (_selectedPlayerId == null && _selectedChildProfileId == null)
                          ? null
                          : () {
                              Navigator.pop(context, {
                                'event_type': _selectedType,
                                'team_id': _selectedTeamId,
                                'minute': int.tryParse(_minuteController.text) ?? 0,
                                'player_id': _selectedPlayerId,
                                'child_profile_id': _selectedChildProfileId,
                              });
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: (_selectedPlayerId != null || _selectedChildProfileId != null)
                              ? PremiumTheme.neonGreen
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: (_selectedPlayerId != null || _selectedChildProfileId != null)
                              ? [BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'common.save'.tr(),
                          style: TextStyle(
                            color: (_selectedPlayerId != null || _selectedChildProfileId != null) ? Colors.black : Colors.white38,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

  Widget _buildEventTypeCard(String type, String icon, String label, Color color) {
    final active = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : Colors.white.withValues(alpha: 0.08),
            width: active ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white54,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w900 : FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamTab(String? teamId, String teamName) {
    final active = _selectedTeamId == teamId;
    return GestureDetector(
      onTap: () {
        if (teamId != null && _selectedTeamId != teamId) {
          setState(() => _selectedTeamId = teamId);
          _loadPlayersForSelectedTeam();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? PremiumTheme.electricBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: active ? Colors.black : Colors.white60,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
