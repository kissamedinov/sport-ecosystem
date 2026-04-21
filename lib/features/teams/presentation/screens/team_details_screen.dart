import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/team_provider.dart';
import '../../data/models/team.dart';
import '../../data/models/player_team.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/data/models/user.dart';
import '../../../../features/matches/data/models/match.dart';
import '../widgets/team_form_indicator.dart';

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  Team? _team;
  bool _isLoading = true;
  PlayerTeam? _myMembership;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    final teamProvider = context.read<TeamProvider>();
    final authProvider = context.read<AuthProvider>();
    
    final team = await teamProvider.fetchTeamById(widget.teamId);
    
    if (mounted && team != null) {
      final currentUserId = authProvider.user?.id;
      final membership = team.players.where((p) => p.playerId == currentUserId).firstOrNull;
      
      setState(() {
        _team = team;
        _myMembership = membership;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch social link')),
        );
      }
    }
  }

  void _handleJoinRequest() async {
    final authProvider = context.read<AuthProvider>();
    
    final bool isParent = authProvider.user?.roles?.any((r) => r.toUpperCase() == 'PARENT') ?? false;
    
    if (isParent) {
      _showChildSelectionDialog();
    } else {
      _submitJoinRequest(null);
    }
  }

  Future<void> _showChildSelectionDialog() async {
    final authProvider = context.read<AuthProvider>();
    final children = await authProvider.fetchMyChildren();
    
    if (!mounted) return;
    
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a child profile first in your profile settings.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Child',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children.map((child) => ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('${child['first_name']} ${child['last_name']}'),
              onTap: () {
                Navigator.pop(context);
                _submitJoinRequest(child['id']);
              },
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _submitJoinRequest(String? childId) async {
    final teamProvider = context.read<TeamProvider>();
    final success = await teamProvider.joinTeam(_team!.id, childProfileId: childId);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trial request sent successfully!')),
      );
      _loadTeam();
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = _team;
    final authProvider = context.watch<AuthProvider>();
    
    if (_isLoading || team == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isApproved = _myMembership?.joinStatus == 'APPROVED';
    final isPending = _myMembership?.joinStatus == 'PENDING';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(team),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (team.coachId == authProvider.user?.id)
                    _buildCoachActions(team),
                  _buildTrialAction(isApproved, isPending),
                  const SizedBox(height: 24),
                  _buildSectionTitle('TEAM PERFORMANCE'),
                  const SizedBox(height: 12),
                  _buildStatsCard(team),
                  const SizedBox(height: 24),
                  _buildSectionTitle('TRAINING SCHEDULE'),
                  const SizedBox(height: 12),
                  _buildScheduleCard(team),
                  const SizedBox(height: 24),
                  _buildSectionTitle('RECENT MATCHES'),
                  const SizedBox(height: 12),
                  if (team.recentMatches.isEmpty)
                    const Center(child: Text('No recent matches recorded'))
                  else
                    ...team.recentMatches.map((match) => _buildMatchTile(match, team.id)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('ROSTER'),
                  const SizedBox(height: 12),
                  _buildRosterSection(team, isApproved),
                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(Team team) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[900]!, Colors.blue[400]!, Colors.indigo[800]!],
                ),
              ),
            ),
            Positioned(
              right: -20,
              top: -20,
              child: Icon(Icons.groups, size: 200, color: Colors.white.withOpacity(0.1)),
            ),
            Positioned(
              bottom: 60,
              left: 16,
              child: Row(
                children: [
                  if (team.whatsapp != null)
                    _buildSocialIcon(Icons.message, Colors.green, () => _launchUrl(team.whatsapp)),
                  const SizedBox(width: 12),
                  if (team.instagram != null)
                    _buildSocialIcon(Icons.camera_alt, Colors.pink, () => _launchUrl(team.instagram)),
                ],
              ).animate().fadeIn(delay: 400.ms).slideX(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCoachActions(Team team) {
    final pendingCount = team.players.where((p) => p.joinStatus == 'PENDING').length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Coach Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('$pendingCount pending requests', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to management screen (to be created)
              _showRequestsModal(team);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue[900],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('View All'),
          ),
        ],
      ),
    );
  }

  void _showRequestsModal(Team team) {
    final pendingRequests = team.players.where((p) => p.joinStatus == 'PENDING').toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pending Trial Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (pendingRequests.isEmpty)
                const Expanded(child: Center(child: Text('No pending requests')))
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final req = pendingRequests[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(req.player?.name ?? 'Candidate ${index + 1}'),
                          subtitle: Text(req.childProfileId != null ? 'Apply by Parent' : 'Apply by Player'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () async {
                                  final success = await context.read<TeamProvider>().approveRequest(team.id, req.id);
                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    _loadTeam();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () async {
                                  final success = await context.read<TeamProvider>().rejectRequest(team.id, req.id);
                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    _loadTeam();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrialAction(bool isApproved, bool isPending) {
    if (isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('You are an active member', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (isPending) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(height: 8),
            Text(
              'TRIAL REQUEST PENDING',
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            Text(
              'Coach will contact you soon',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
      ).animate().shake();
    }

    return ElevatedButton(
      onPressed: _handleJoinRequest,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      child: const Text(
        'ЗАПИСАТЬСЯ НА ПРОБНУЮ ТРЕНИРОВКУ',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    ).animate().scale(delay: 200.ms);
  }

  Widget _buildStatsCard(Team team) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('CURRENT FORM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                TeamFormIndicator(form: team.form, size: 28),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('RATING', team.rating.toString(), Colors.orange),
                _buildStatItem('WINS', team.wins.toString(), Colors.green),
                _buildStatItem('LOSSES', team.losses.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Team team) {
    return Card(
      elevation: 0,
      color: Colors.blue[50]?.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(team.city, style: const TextStyle(fontSize: 13)),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Training Times', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Check back for specific schedule or contact coach', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterSection(Team team, bool isApproved) {
    if (!isApproved) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Full roster visible after trial approval',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: team.players.map((p) => ListTile(
        leading: CircleAvatar(child: Text(p.player?.name.substring(0, 1) ?? '?')),
        title: Text(p.player?.name ?? 'Unknown Player'),
        subtitle: Text(p.joinStatus ?? 'Member'),
      )).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: Colors.blueGrey[300],
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMatchTile(MatchModel match, String teamId) {
    final isHome = match.homeTeamId == teamId;
    final teamScore = isHome ? match.homeScore : match.awayScore;
    final opponentScore = isHome ? match.awayScore : match.homeScore;
    final tScore = teamScore ?? 0;
    final oScore = opponentScore ?? 0;
    final result = tScore > oScore ? 'W' : (tScore < oScore ? 'L' : 'D');
    final resultColor = result == 'W' ? Colors.green : (result == 'L' ? Colors.red : Colors.grey);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[100]!),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: resultColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Center(
            child: Text(result, style: TextStyle(color: resultColor, fontWeight: FontWeight.bold)),
          ),
        ),
        title: Text(isHome ? 'vs Rival' : 'at Rival', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(match.scheduledAt.split('T')[0], style: const TextStyle(fontSize: 11)),
        trailing: Text('$teamScore - $opponentScore', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
