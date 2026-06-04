import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/teams/data/models/player_team.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/clubs/data/models/player_info.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'invite_member_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  final Team team;
  final List<PlayerInfo> availableCoaches;

  const TeamManagementScreen({
    super.key,
    required this.team,
    required this.availableCoaches,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ProfileApiService _profileApi = ProfileApiService();
  String? _selectedCoachId;

  @override
  void initState() {
    super.initState();
    _selectedCoachId = widget.team.coachId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.team.name.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
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
                        widget.team.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.team.academyName ?? 'academy.no_academy'.tr()} • ${widget.team.ageCategory ?? 'common.unknown'.tr()}',
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
                child: _buildMiniStat('player.rating'.tr().toUpperCase(), widget.team.rating.toString(), Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('team.wins'.tr().toUpperCase(), widget.team.wins.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('team.losses'.tr().toUpperCase(), widget.team.losses.toString(), Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Coach assignment section
          _buildSectionHeader('club.assigned_coach'.tr(), Icons.sports_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCoachId,
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
              items: widget.availableCoaches.map((c) {
                return DropdownMenuItem(
                  value: c.userId,
                  child: Text(c.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCoachId = val),
            ),
          ),
          const SizedBox(height: 28),

          // Roster section
          _buildSectionHeader('club.roster_count'.tr(namedArgs: {'count': widget.team.players.length.toString()}), Icons.people_rounded),
          const SizedBox(height: 12),

          if (widget.team.players.isEmpty)
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
            ...widget.team.players.map((pt) => _buildPlayerCard(pt)),

          const SizedBox(height: 20),

          // Add player button
          PremiumButton(
            text: 'club.add_player'.tr(),
            icon: Icons.person_add_rounded,
            onPressed: () => _showAddPlayerModal(context),
          ),
          const SizedBox(height: 40),
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

  Widget _buildPlayerCard(PlayerTeam pt) {
    final name = pt.player?.name ?? 'common.unknown'.tr();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: PremiumTheme.electricBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: PremiumTheme.electricBlue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'club.player_role_label'.tr(),
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.removing_player'.tr())));
            },
          ),
        ],
      ),
    );
  }

  void _showAddPlayerModal(BuildContext context) {
    final clubProvider = context.read<ClubProvider>();
    final dashboard = clubProvider.dashboard;
    if (dashboard == null) return;

    // Filter players not in this team
    final currentTeamPlayerIds = widget.team.players.map((p) => p.playerId).toSet();
    
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
                            initialTeamId: widget.team.id,
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

    final success = await clubProvider.addPlayerToTeam(widget.team.id, id, null);

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
    if (_selectedCoachId == widget.team.coachId) {
      Navigator.pop(context);
      return;
    }
    
    final clubProvider = context.read<ClubProvider>();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.updating_coach'.tr())));

    final success = await clubProvider.reassignTeamCoach(widget.team.id, _selectedCoachId!);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('club.coach_updated'.tr())));
      clubProvider.fetchClubDashboard();
      Navigator.pop(context);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'common.error'.tr()}: ${clubProvider.error ?? 'common.unknown'.tr()}')));
    }
  }
}
