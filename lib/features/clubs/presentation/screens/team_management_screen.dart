import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import '../../providers/club_provider.dart';
import 'invite_member_screen.dart';

class TeamManagementScreen extends StatefulWidget {
  final String teamId;
  final String clubId;

  const TeamManagementScreen({
    super.key, 
    required this.teamId,
    required this.clubId,
  });

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh dashboard to ensure we have latest roster if needed
    // Future.microtask(() => context.read<ClubProvider>().fetchClubDashboard(widget.clubId));
  }

  @override
  Widget build(BuildContext context) {
    final clubProvider = context.watch<ClubProvider>();
    final dashboard = clubProvider.dashboard;
    
    if (dashboard == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final team = dashboard.teams.firstWhere((t) => t.id == widget.teamId);

    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        title: Text(team.name.toUpperCase()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => InviteMemberScreen(
                    clubId: widget.clubId,
                    // initialTeamId: widget.teamId, // Will add this parameter to InviteMemberScreen
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildTeamHeader(team),
          const SizedBox(height: 32),
          const Text('ROSTER / PLAYERS', 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
          const SizedBox(height: 16),
          if (team.players.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('No players assigned to this team yet.', style: TextStyle(color: Colors.white24)),
            ))
          else
            ...team.players.map((player) => _buildPlayerCard(player)),
          
          const SizedBox(height: 32),
          PremiumButton(
            text: 'INVITE NEW PLAYER',
            icon: Icons.person_add_alt_1,
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => InviteMemberScreen(
                    clubId: widget.clubId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(dynamic team) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: Colors.green, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('Academy: ${team.academyName ?? 'N/A'}', style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLargeStat('RATING', team.rating.toString(), Colors.amber),
              _buildLargeStat('WINS', team.wins.toString(), Colors.green),
              _buildLargeStat('LOSSES', team.losses.toString(), Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildPlayerCard(dynamic player) {
    return PremiumCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: const Icon(Icons.person, color: Colors.white70),
        ),
        title: Text(player.fullName ?? 'Unknown Player', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Pos: ${player.position ?? 'N/A'} | Status: ${player.status}', 
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white10),
      ),
    );
  }
}
