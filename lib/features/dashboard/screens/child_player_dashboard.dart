import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../clubs/data/models/invitation.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
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
        title: Text('player.football_hub'.tr(), style: const TextStyle(letterSpacing: 2)),
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
              title: 'player.parent_link_request'.tr(),
              message: 'player.parent_link_message'.tr(namedArgs: {'name': req['parent_name'].toString()}),
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
                  title: 'profile.hello'.tr(namedArgs: {'name': (user?.name ?? 'Player').split(' ').first}),
                  subtitle: 'player.youth_player'.tr(),
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
                      PremiumSectionLabel('player.action_required'.tr()),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                        child: Text('profile.view_all'.tr(), style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...pendingInvites.take(2).map((invite) => _buildInviteCard(context, invite)),
                ],

                const SizedBox(height: 24),
                PremiumSectionLabel('player.your_next_match'.tr()),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'match.match_details'.tr()))),
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
                              nextMatch != null ? 'player.match_day'.tr() : 'player.tournament_prep'.tr(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMatch != null ? nextMatch.scheduledAt : 'player.train_hard'.tr(),
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
                        label: 'player.team_label'.tr(),
                        accent: PremiumTheme.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.bolt_rounded,
                        value: 'LVL 5',
                        label: 'player.level'.tr(),
                        accent: PremiumTheme.neonGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                PremiumSectionLabel('player.my_activity'.tr()),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _buildActionCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'nav.tournaments'.tr(),
                      subtitle: 'player.compete_win'.tr(),
                      accent: Colors.amber,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen())),
                    ),
                    _buildActionCard(
                      icon: Icons.insert_chart_outlined_rounded,
                      title: 'player.my_stats'.tr(),
                      subtitle: 'player.track_progress'.tr(),
                      accent: PremiumTheme.electricBlue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'player.my_statistics'.tr()))),
                    ),
                    _buildActionCard(
                      icon: Icons.forum_outlined,
                      title: 'player.coach_msg'.tr(),
                      subtitle: 'player.read_feedback'.tr(),
                      accent: PremiumTheme.neonGreen,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'player.message_from_coach'.tr()))),
                    ),
                    _buildActionCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'academy.training'.tr(),
                      subtitle: 'player.daily_schedule'.tr(),
                      accent: const Color(0xFFCE93D8),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'player.training_schedule'.tr()))),
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
    required Color accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OrleonCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      radius: 16,
      background: isDark ? const Color(0xFF161B22) : cs.surface,
      borderColor: accent.withValues(alpha: 0.28),
      shadow: [BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OrleonCard(
      padding: const EdgeInsets.all(16),
      radius: 18,
      onTap: onTap,
      background: isDark ? const Color(0xFF161B22) : cs.surface,
      borderColor: accent.withValues(alpha: 0.28),
      shadow: [BoxShadow(color: accent.withValues(alpha: isDark ? 0.12 : 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                  child: Text('notification.decline'.tr()),
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
                  child: Text('notification.accept'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final authProvider = context.read<AuthProvider>();
    final teamProvider = context.read<TeamProvider>();
    final clubProvider = context.read<ClubProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool success = false;

    String finalEntityId = invite.entityId;
    if (!invite.isParentRequest) {
      try {
        await clubProvider.fetchMyInvitations();
        final matchingInvite = clubProvider.myInvitations.firstWhere(
          (i) => i.status == InvitationStatus.pending && 
                 (i.clubId == invite.entityId || i.teamId == invite.entityId),
        );
        finalEntityId = matchingInvite.id;
      } catch (e) {
        // fallback
      }
    }

    if (invite.isParentRequest) {
      if (accept) {
        success = await authProvider.acceptRequest(finalEntityId);
      } else {
        success = await authProvider.rejectRequest(finalEntityId);
      }
    } else {
      if (accept) {
        success = await clubProvider.acceptInvitation(finalEntityId);
      } else {
        success = await clubProvider.declineInvitation(finalEntityId);
      }
    }

    if (mounted) {
      if (success) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(accept ? 'notification.invitation_accepted'.tr() : 'notification.invitation_declined'.tr())),
        );
        if (!invite.isParentRequest) {
          notificationProvider.markAsRead(invite.id);
          notificationProvider.setResolvedStatus(invite.id, accept ? 'accepted' : 'declined');
          notificationProvider.fetchNotifications();
          teamProvider.fetchMyTeams();
          authProvider.checkAuthStatus();
        } else {
          authProvider.fetchMyParents();
          authProvider.checkAuthStatus();
          authProvider.fetchParentRequests();
          for (final n in notificationProvider.notifications) {
            if (n.entityId == invite.entityId && n.id != invite.id) {
              notificationProvider.setResolvedStatus(
                  n.id, accept ? 'accepted' : 'declined');
            }
          }
        }
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('notification.action_failed'.tr())),
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
      body: Center(child: Text('common.coming_soon_content'.tr(namedArgs: {'title': title}))),
    );
  }
}
