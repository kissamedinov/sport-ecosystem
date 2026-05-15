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
import '../../tournaments/presentation/screens/tournament_list_screen.dart';
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
                      const PremiumSectionLabel('ACTION REQUIRED'),
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
                const PremiumSectionLabel('YOUR NEXT MATCH'),
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shield_rounded,
                        value: teamCount > 0 ? teamProvider.myTeams.first.name.split(' ').first.toUpperCase() : 'NONE',
                        label: 'TEAM',
                        badge: 'SQUAD',
                        accent: const Color(0xFF42A5F5),
                        cardBg: const Color(0xFF0D1B2A),
                        borderColor: const Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.bolt_rounded,
                        value: 'LVL 5',
                        label: 'LEVEL',
                        badge: 'XP',
                        accent: const Color(0xFF00E676),
                        cardBg: const Color(0xFF0A1F0A),
                        borderColor: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const PremiumSectionLabel('MY ACTIVITY'),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen())),
                      child: _buildStatCard(
                        icon: Icons.emoji_events_rounded,
                        value: 'GO',
                        label: 'TOURNAMENTS',
                        badge: 'COMPETE',
                        accent: const Color(0xFFFFA726),
                        cardBg: const Color(0xFF1A1200),
                        borderColor: const Color(0xFFE65100),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'My Statistics'))),
                      child: _buildStatCard(
                        icon: Icons.insert_chart_outlined_rounded,
                        value: 'SEE',
                        label: 'STATS',
                        badge: 'TRACK',
                        accent: const Color(0xFF42A5F5),
                        cardBg: const Color(0xFF0D1B2A),
                        borderColor: const Color(0xFF1E3A5F),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Message from Coach'))),
                      child: _buildStatCard(
                        icon: Icons.forum_outlined,
                        value: 'CHAT',
                        label: 'COACHED',
                        badge: 'COACH',
                        accent: const Color(0xFF00E676),
                        cardBg: const Color(0xFF0A1F0A),
                        borderColor: const Color(0xFF1B5E20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Training Schedule'))),
                      child: _buildStatCard(
                        icon: Icons.fitness_center_rounded,
                        value: 'TRAIN',
                        label: 'TRAINING',
                        badge: 'GRIND',
                        accent: const Color(0xFFCE93D8),
                        cardBg: const Color(0xFF1A001A),
                        borderColor: const Color(0xFF6A0080),
                      ),
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

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required String badge,
    required Color accent,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: accent, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.bold, height: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600),
          ),
        ],
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
                    color: color.withValues(alpha: 0.1),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
