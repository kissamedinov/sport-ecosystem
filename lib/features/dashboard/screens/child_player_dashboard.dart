import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
// import 'adult_player_dashboard.dart'; // for TemporaryScreen

class ChildPlayerDashboard extends StatefulWidget {
  const ChildPlayerDashboard({super.key});

  @override
  State<ChildPlayerDashboard> createState() => _ChildPlayerDashboardState();
}

class _ChildPlayerDashboardState extends State<ChildPlayerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchMyTeams();
      context.read<MatchProvider>().fetchMatches();
      context.read<NotificationProvider>().fetchNotifications();
      context.read<AuthProvider>().fetchParentRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('FOOTBALL HUB', style: TextStyle(letterSpacing: 2)),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                    },
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('${provider.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer3<TeamProvider, MatchProvider, NotificationProvider>(
        builder: (context, teamProvider, matchProvider, notificationProvider, _) {
          final teamCount = teamProvider.myTeams.length;
          final nextMatch = matchProvider.matches.isNotEmpty ? matchProvider.matches.first : null;
          final authProvider = context.watch<AuthProvider>();
          
          final List<PendingRequestItem> pendingInvites = [];
          
          for (var req in authProvider.parentRequests) {
            pendingInvites.add(PendingRequestItem(
              id: req['id'],
              title: 'Parent Link Request',
              message: '${req['parent_name']} wants to link to your account as a parent.',
              entityId: req['id'],
              isParentRequest: true,
            ));
          }

          final notifs = notificationProvider.notifications.where((n) {
            return !n.isRead && n.type == 'TEAM_INVITE';
          });
          for (var n in notifs) {
            pendingInvites.add(PendingRequestItem(
              id: n.id,
              title: n.title,
              message: n.message,
              entityId: n.entityId ?? '',
              isParentRequest: false,
            ));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHeader(
                  title: 'Hi, ${(user?.name ?? 'Player').split(' ').first}!',
                  subtitle: 'YOUTH PLAYER',
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: PremiumTheme.neonGreen),
                  ),
                ),

                if (pendingInvites.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ACTION REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                        child: const Text('See All', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pendingInvites.take(2).map((invite) => _buildInviteCard(context, invite)),
                ],

                const SizedBox(height: 24),
                const Text('YOUR NEXT MATCH', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Match Details'))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sports_soccer_rounded, color: Colors.amber, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextMatch != null ? 'Match Day!' : 'Tournament Prep',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMatch != null ? nextMatch.scheduledAt : 'Train hard, stay ready',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        title: 'Team',
                        value: teamCount > 0 ? 'ACTIVE' : 'NONE',
                        icon: Icons.shield_rounded,
                        color: PremiumTheme.electricBlue,
                        subtitle: teamCount > 0 ? teamProvider.myTeams.first.name : 'Waiting',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PremiumStatCard(
                        title: 'Experience',
                        value: 'LVL 5',
                        icon: Icons.bolt_rounded,
                        color: PremiumTheme.neonGreen,
                        subtitle: 'Prospect',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Text('MY ACTIVITY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 12),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildActivityAction(
                      context: context,
                      label: 'Stats',
                      icon: Icons.insert_chart_outlined_rounded,
                      color: Colors.blueAccent,
                      title: 'My Statistics',
                    ),
                    _buildActivityAction(
                      context: context,
                      label: 'Awards',
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amberAccent,
                      title: 'Best Player Awards',
                    ),
                    _buildActivityAction(
                      context: context,
                      label: 'Coached',
                      icon: Icons.forum_outlined,
                      color: Colors.greenAccent,
                      title: 'Message from Coach',
                    ),
                    _buildActivityAction(
                      context: context,
                      label: 'Training',
                      icon: Icons.fitness_center_rounded,
                      color: Colors.purpleAccent,
                      title: 'Training Schedule',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String title,
  }) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: title))),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCard(BuildContext context, PendingRequestItem invite) {
    final iconData = invite.isParentRequest ? Icons.family_restroom_rounded : Icons.mail_rounded;
    final color = invite.isParentRequest ? Colors.orangeAccent : Colors.blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        invite.message,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _handleDashboardInvitation(context, invite, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleDashboardInvitation(context, invite, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(80, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleDashboardInvitation(BuildContext context, PendingRequestItem invite, bool accept) async {
    final notificationProvider = context.read<NotificationProvider>();
    bool success = false;

    if (invite.isParentRequest) {
      final authProvider = context.read<AuthProvider>();
      if (accept) {
        success = await authProvider.acceptRequest(invite.entityId);
      } else {
        success = await authProvider.rejectRequest(invite.entityId);
      }
    } else {
      final clubProvider = context.read<ClubProvider>();
      if (accept) {
        success = await clubProvider.acceptInvitation(invite.entityId);
      } else {
        success = await clubProvider.declineInvitation(invite.entityId);
      }
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Invitation accepted!' : 'Invitation declined.')),
        );
        if (!invite.isParentRequest) {
          notificationProvider.markAsRead(invite.id);
          notificationProvider.fetchNotifications();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Please try again.')),
        );
      }
    }
  }
}

class PendingRequestItem {
  final String id;
  final String title;
  final String message;
  final String entityId;
  final bool isParentRequest;

  PendingRequestItem({
    required this.id,
    required this.title,
    required this.message,
    required this.entityId,
    required this.isParentRequest,
  });
}

class TemporaryScreen extends StatelessWidget {
  final String title;
  const TemporaryScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Content for $title coming soon!')),
    );
  }
}
