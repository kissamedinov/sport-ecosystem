import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/teams/data/models/player_team.dart';
import 'package:mobile/features/teams/providers/team_provider.dart';
import 'package:mobile/features/clubs/data/models/player_info.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'invite_member_screen.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_attendance_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_tactics_screen.dart';
import 'package:mobile/features/coaches/presentation/screens/coach_planner_screen.dart';
import 'package:mobile/features/lineups/presentation/screens/lineup_screen.dart';


class TeamManagementScreen extends StatefulWidget {
  final Team team;
  final List<PlayerInfo> availableCoaches;
  final bool isReadOnly;

  const TeamManagementScreen({
    super.key,
    required this.team,
    required this.availableCoaches,
    this.isReadOnly = false,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {

  String? _selectedCoachId;
  Team? _fullTeam;
  bool _isLoading = false;

  Team get _team => _fullTeam ?? widget.team;

  bool get _isClubStaff {
    final user = context.read<AuthProvider>().user;
    final roles = user?.roles ?? [];
    return roles.contains('CLUB_OWNER') || roles.contains('CLUB_MANAGER') || roles.contains('ADMIN');
  }

  @override
  void initState() {
    super.initState();
    _selectedCoachId = widget.team.coachId;
    _loadFullTeam();
  }

  Future<void> _loadFullTeam() async {
    setState(() => _isLoading = true);
    try {
      final teamProvider = context.read<TeamProvider>();
      final team = await teamProvider.fetchTeamById(widget.team.id);
      if (team != null && mounted) {
        setState(() {
          _fullTeam = team;
          _selectedCoachId = team.coachId;
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssignReadOnly = widget.isReadOnly || !_isClubStaff;

    final activePlayers = _team.players.where((p) => p.joinStatus != 'PENDING').toList();
    final pendingRequests = _team.players.where((p) => p.joinStatus == 'PENDING').toList();

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _team.name.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: isAssignReadOnly ? [] : [
          IconButton(
            icon: const Icon(Icons.save_rounded, color: PremiumTheme.neonGreen),
            onPressed: () => _saveTeamChanges(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Team info header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PremiumTheme.electricBlue, PremiumTheme.surfaceBase(context)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PremiumTheme.electricBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: PremiumTheme.electricBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _team.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_team.academyName ?? 'academy.no_academy'.tr()} • ${_team.ageCategory ?? 'common.unknown'.tr()}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('player.rating'.tr().toUpperCase(), _team.rating.toString(), Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('team.wins'.tr().toUpperCase(), _team.wins.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('team.losses'.tr().toUpperCase(), _team.losses.toString(), Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Coaching Tools Section (for staff when not read-only)
          if (!widget.isReadOnly) ...[
            _buildSectionHeader('coach.coaching_tools'.tr(), Icons.construction_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.how_to_reg_rounded,
                    color: PremiumTheme.neonGreen,
                    title: 'coach.attendance'.tr(),
                    subtitle: 'profile.track_training'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoachAttendanceScreen(
                            teams: [
                              {
                                'id': _team.id,
                                'name': _team.name,
                                'players': _team.players.map((p) => {
                                  'id': p.playerId,
                                  'name': p.player?.name ?? 'Player',
                                }).toList(),
                              }
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.architecture_rounded,
                    color: PremiumTheme.electricBlue,
                    title: 'coach.tactics'.tr(),
                    subtitle: 'profile.formations'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachTacticsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.calendar_month_rounded,
                    color: Colors.amber,
                    title: 'coach.planner'.tr(),
                    subtitle: 'profile.daily_agenda'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CoachPlannerScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickActionCard(
                    icon: Icons.grid_view_rounded,
                    color: Colors.purpleAccent,
                    title: 'match.lineup'.tr(),
                    subtitle: 'team.select_11'.tr(),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LineupScreen(
                            teamName: _team.name,
                            players: activePlayers,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],

          // Coach assignment section
          _buildSectionHeader('club.assigned_coach'.tr(), Icons.sports_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
            child: () {
              if (isAssignReadOnly) {
                final coachName = _team.coachName ?? 'club.unassigned_no_coach'.tr();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: PremiumTheme.neonGreen, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        coachName,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }
              final uniqueCoaches = <String, PlayerInfo>{};
              for (var c in widget.availableCoaches) {
                if (c.userId.isNotEmpty) {
                  uniqueCoaches[c.userId] = c;
                }
              }
              final coachList = uniqueCoaches.values.toList();
              final isValueValid = uniqueCoaches.containsKey(_selectedCoachId);

              return DropdownButtonFormField<String?>(
                initialValue: isValueValid ? _selectedCoachId : null,
                dropdownColor: PremiumTheme.surfaceCard(context),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_search_rounded, color: PremiumTheme.neonGreen, size: 20),
                  labelText: 'club.select_coach'.tr(),
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PremiumTheme.neonGreen),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('club.unassigned_no_coach'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ),
                  ...coachList.map((c) {
                    return DropdownMenuItem<String?>(
                      value: c.userId,
                      child: Text(c.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    );
                  }),
                ],
                onChanged: (val) => setState(() => _selectedCoachId = val),
              );
            }(),
          ),
          const SizedBox(height: 28),

          // Pending Requests section
          if (!widget.isReadOnly && pendingRequests.isNotEmpty) ...[
            _buildSectionHeader('team.pending_trials'.tr(), Icons.hourglass_empty_rounded),
            const SizedBox(height: 12),
            ...pendingRequests.map((req) => _buildPendingTrialCard(req)),
            const SizedBox(height: 28),
          ],

          // Roster section
          _buildSectionHeader('club.roster_count'.tr(namedArgs: {'count': activePlayers.length.toString()}), Icons.people_rounded),
          const SizedBox(height: 12),

          if (_isLoading && activePlayers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: PremiumTheme.neonGreen),
              ),
            )
          else if (activePlayers.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.person_off_rounded, size: 40, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  Text(
                    'club.no_players_yet'.tr(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            )
          else
            ...activePlayers.map((pt) => _buildPlayerCard(pt)),

          const SizedBox(height: 20),

          if (!widget.isReadOnly && _isClubStaff) ...[
            // Add player button
            PremiumButton(
              text: 'club.add_player'.tr(),
              icon: Icons.person_add_rounded,
              onPressed: () => _showAddPlayerModal(context),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 12),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: PremiumTheme.neonGreen, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), letterSpacing: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PremiumTheme.neonGreen.withValues(alpha: 0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _posColor(String pos) {
    switch (pos) {
      case 'GK': return const Color(0xFFFFC107);
      case 'DEF': return PremiumTheme.electricBlue;
      case 'MID': return PremiumTheme.neonGreen;
      case 'FWD': return const Color(0xFFFF5252);
      default: return PremiumTheme.neonGreen;
    }
  }

  void _showEditPlayerDialog(BuildContext context, PlayerTeam pt) {
    final name = pt.player?.name ?? 'common.unknown'.tr();
    String? selectedPos = pt.position;
    final jerseyController = TextEditingController(text: pt.jerseyNumber?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: PremiumTheme.surfaceCard(context),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'team.edit_player_info'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Position Selector
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'team.position'.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['GK', 'DEF', 'MID', 'FWD'].map((pos) {
                        final isSel = selectedPos == pos;
                        final color = _posColor(pos);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedPos = pos;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel ? color.withValues(alpha: 0.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel ? color : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                pos,
                                style: TextStyle(
                                  color: isSel ? color : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Jersey Number
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'team.jersey_number'.tr().toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: jerseyController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: PremiumTheme.inputDecorationOf(
                        context,
                        'team.jersey_number_hint'.tr(),
                        prefixIcon: Icons.numbers_rounded,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'common.cancel'.tr().toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PremiumButton(
                            text: 'common.save'.tr().toUpperCase(),
                            onPressed: () async {
                              final numStr = jerseyController.text.trim();
                              int? parsedNum;
                              if (numStr.isNotEmpty) {
                                parsedNum = int.tryParse(numStr);
                                if (parsedNum == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('team.invalid_jersey'.tr())),
                                  );
                                  return;
                                }
                              }

                              Navigator.pop(context); // Close bottom sheet
                              
                              setState(() => _isLoading = true);
                              try {
                                final teamProvider = context.read<TeamProvider>();
                                final success = await teamProvider.updateTeamPlayerPosition(
                                  _team.id,
                                  pt.id.isNotEmpty ? pt.id : pt.playerId,
                                  position: selectedPos,
                                  jerseyNumber: parsedNum,
                                );

                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Player info updated successfully.')),
                                  );
                                  _loadFullTeam(); // Reload details to reflect updates
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('team.player_update_failed'.tr())),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${'common.error'.tr()}: ${e.toString()}')),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerCard(PlayerTeam pt) {
    final name = pt.player?.name ?? 'common.unknown'.tr();
    final isEditable = !widget.isReadOnly;

    return GestureDetector(
      onTap: isEditable ? () => _showEditPlayerDialog(context, pt) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: pt.position != null 
                    ? _posColor(pt.position!).withValues(alpha: 0.12)
                    : PremiumTheme.electricBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: pt.position != null
                      ? _posColor(pt.position!).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: pt.jerseyNumber != null
                    ? Text(
                        '#${pt.jerseyNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: pt.position != null ? _posColor(pt.position!) : PremiumTheme.electricBlue,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: pt.position != null ? _posColor(pt.position!) : PremiumTheme.electricBlue,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (pt.position != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _posColor(pt.position!).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pt.position!,
                            style: TextStyle(
                              color: _posColor(pt.position!),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        'club.player_role_label'.tr(),
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isEditable) ...[
              Icon(
                Icons.edit_rounded, 
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25), 
                size: 16
              ),
              const SizedBox(width: 8),
            ],
            if (!widget.isReadOnly && _isClubStaff)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.removing_player'.tr())));
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddPlayerModal(BuildContext context) {
    final clubProvider = context.read<ClubProvider>();
    final dashboard = clubProvider.dashboard;
    if (dashboard == null) return;

    // Filter players not in this team
    final currentTeamPlayerIds = _team.players.map((p) => p.playerId).toSet();
    
    final availablePlayers = dashboard.players.where((p) => !currentTeamPlayerIds.contains(p.userId)).toList();
    final availableChildren = dashboard.childProfiles.where((cp) => 
      cp.linkedUserId == null || !currentTeamPlayerIds.contains(cp.linkedUserId)
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: PremiumTheme.surfaceCard(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('club.add_player_title'.tr(), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSectionHeader('club.club_players'.tr(), Icons.people_rounded),
                  const SizedBox(height: 12),
                  if (availablePlayers.isEmpty)
                    _buildEmptyState('club.no_other_players'.tr())
                  else
                    ...availablePlayers.map((p) => _buildAddPlayerTile(context, p.name, p.userId, false)),

                  const SizedBox(height: 28),
                  _buildSectionHeader('club.child_profiles'.tr(), Icons.child_care_rounded),
                  const SizedBox(height: 12),
                  if (availableChildren.isEmpty)
                    _buildEmptyState('club.no_unassigned_children'.tr())
                  else
                    ...availableChildren.map((cp) => _buildAddPlayerTile(context, cp.fullName, cp.id, true)),
                  
                  const SizedBox(height: 40),
                  PremiumButton(
                    text: 'club.invite_new_person'.tr(),
                    icon: Icons.mail_rounded,
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InviteMemberScreen(
                            clubId: dashboard.club.id,
                            initialTeamId: _team.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAddPlayerTile(BuildContext context, String name, String id, bool isChildProfile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: PremiumTheme.electricBlue.withValues(alpha: 0.1),
            radius: 18,
            child: const Icon(Icons.person_rounded, color: PremiumTheme.electricBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: PremiumTheme.neonGreen),
            onPressed: () => _addPlayerToTeam(context, id, isChildProfile),
          ),
        ],
      ),
    );
  }

  void _addPlayerToTeam(BuildContext context, String id, bool isChildProfile) async {
    final clubProvider = context.read<ClubProvider>();
    
    // For now we use the same addPlayerToTeam but we might need to handle child profiles differently
    // In this backend version, we mostly use user_id
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.adding_player'.tr())));

    final success = await clubProvider.addPlayerToTeam(_team.id, id, null);

    if (success && context.mounted) {
      Navigator.pop(context); // Close modal
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.player_added'.tr())));
      // Refresh dashboard to show new player in roster
      clubProvider.fetchClubDashboard();
      Navigator.pop(context); // Go back to refresh screen or we could just update local state
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: ${clubProvider.error ?? 'common.unknown'.tr()}')));
    }
  }

  void _saveTeamChanges(BuildContext context) async {
    if (_selectedCoachId == _team.coachId) {
      Navigator.pop(context);
      return;
    }
    
    if (_selectedCoachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.select_coach_error'.tr())));
      return;
    }
    
    final clubProvider = context.read<ClubProvider>();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.updating_coach'.tr())));

    final success = await clubProvider.reassignTeamCoach(_team.id, _selectedCoachId!);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.coach_updated'.tr())));
      clubProvider.fetchClubDashboard();
      Navigator.pop(context);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: ${clubProvider.error ?? 'common.unknown'.tr()}')));
    }
  }

  Widget _quickActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTrialCard(PlayerTeam req) {
    final name = req.player?.name ?? 'Candidate';  // localized via fallback below
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.amber.withValues(alpha: 0.12),
            radius: 18,
            child: const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  req.childProfileId != null ? 'team.apply_by_parent'.tr() : 'team.apply_by_player'.tr(),
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.adding_player'.tr())));
                  final success = await context.read<TeamProvider>().approveRequest(_team.id, req.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('team.trial_approved'.tr())));
                    _loadFullTeam();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('team.trial_approve_failed'.tr())));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('team.trial_rejecting'.tr())));
                  final success = await context.read<TeamProvider>().rejectRequest(_team.id, req.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('team.trial_rejected'.tr())));
                    _loadFullTeam();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('team.trial_reject_failed'.tr())));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

