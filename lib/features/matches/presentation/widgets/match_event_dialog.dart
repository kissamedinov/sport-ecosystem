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
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF122229),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'match.event_dialog_title'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Event Type Selection
              Text('match.event_type'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1519),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF122229),
                    value: _selectedType,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    items: [
                      DropdownMenuItem(value: 'GOAL', child: Text('⚽  ${'match.event_goal'.tr()}')),
                      DropdownMenuItem(value: 'YELLOW_CARD', child: Text('🟨  ${'match.event_yellow_card'.tr()}')),
                      DropdownMenuItem(value: 'RED_CARD', child: Text('🟥  ${'match.event_red_card'.tr()}')),
                      DropdownMenuItem(value: 'SUBSTITUTION', child: Text('🔄  ${'match.event_substitution'.tr()}')),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Team Selection
              Text('match.team'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1519),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String?>(
                    dropdownColor: const Color(0xFF122229),
                    value: _selectedTeamId,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    items: [
                      DropdownMenuItem(value: widget.homeTeamId, child: Text(widget.homeTeamName)),
                      DropdownMenuItem(value: widget.awayTeamId, child: Text(widget.awayTeamName)),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedTeamId = val);
                      _loadPlayersForSelectedTeam();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Minute and Player Selection dropdown
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('match.minute'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _minuteController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0B1519),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            hintText: '45',
                            hintStyle: const TextStyle(color: Colors.white24),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: PremiumTheme.neonGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('match.player'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_isLoadingPlayers)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: PremiumTheme.neonGreen)),
                          )
                        else ...[
                          if (_lineupWarning != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text(
                                _lineupWarning!,
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1519),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                dropdownColor: const Color(0xFF122229),
                                value: _selectedPlayerId ?? _selectedChildProfileId,
                                hint: Text('match.select_player_hint'.tr(), style: const TextStyle(color: Colors.white24, fontSize: 12)),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_selectedPlayerId == null && _selectedChildProfileId == null)
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('common.save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
}
