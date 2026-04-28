import 'package:flutter/material.dart';
import 'package:mobile/features/teams/data/models/team.dart';
import 'package:mobile/features/teams/data/models/player_team.dart';
import 'package:mobile/core/api/profile_api_service.dart';
import 'package:mobile/features/clubs/data/models/player_info.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';

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
        iconTheme: const IconThemeData(color: Colors.white70),
        title: Text(
          widget.team.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.team.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.team.academyName ?? 'No Academy'} • ${widget.team.ageCategory ?? 'N/A'}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
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
                child: _buildMiniStat('RATING', widget.team.rating.toString(), Colors.amber),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('WINS', widget.team.wins.toString(), Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat('LOSSES', widget.team.losses.toString(), Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Coach assignment section
          _buildSectionHeader('ASSIGNED COACH', Icons.sports_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: PremiumTheme.glassDecorationOf(context, radius: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedCoachId,
              dropdownColor: PremiumTheme.surfaceCard(context),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_search_rounded, color: PremiumTheme.neonGreen, size: 20),
                labelText: 'Select Coach',
                labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PremiumTheme.neonGreen),
                ),
              ),
              items: widget.availableCoaches.map((c) {
                return DropdownMenuItem(
                  value: c.userId,
                  child: Text(c.name, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCoachId = val),
            ),
          ),
          const SizedBox(height: 28),

          // Roster section
          _buildSectionHeader('ROSTER (${widget.team.players.length})', Icons.people_rounded),
          const SizedBox(height: 12),

          if (widget.team.players.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.person_off_rounded, size: 40, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 12),
                  Text(
                    'NO PLAYERS YET',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
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
            text: 'ADD PLAYER',
            icon: Icons.person_add_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Integration with Invitation system coming soon.')),
              );
            },
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
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1)),
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2),
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
    final name = pt.player?.name ?? 'Unknown Player';
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
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  'Player',
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removing player...')));
            },
          ),
        ],
      ),
    );
  }

  void _saveTeamChanges(BuildContext context) async {
    if (_selectedCoachId == widget.team.coachId) {
      Navigator.pop(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving changes...')));
    Navigator.pop(context);
  }
}
