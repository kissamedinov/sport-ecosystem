import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../../clubs/presentation/screens/club_dashboard_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class AdultPlayerDashboard extends StatefulWidget {
  const AdultPlayerDashboard({super.key});

  @override
  State<AdultPlayerDashboard> createState() => _AdultPlayerDashboardState();
}

class _AdultPlayerDashboardState extends State<AdultPlayerDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().fetchMyTeams();
      context.read<MatchProvider>().fetchMatches();
      context.read<NotificationProvider>().fetchNotifications();
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
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
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
      body: Consumer2<TeamProvider, MatchProvider>(
        builder: (context, teamProvider, matchProvider, _) {
          final teamCount = teamProvider.myTeams.length;
          final nextMatch = matchProvider.matches.isNotEmpty ? matchProvider.matches.first : null;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHeader(
                  title: 'Hello, ${(user?.name ?? 'Player').split(' ').first}!',
                  subtitle: 'ADULT PLAYER',
                  trailing: CircleAvatar(
                    radius: 20,
                    backgroundColor: PremiumTheme.neonGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: PremiumTheme.neonGreen),
                  ),
                ),
                
                Text('YOUR NEXT CHALLENGE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 2)),
                const SizedBox(height: 12),
                PremiumCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Match Details'))),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.timer_outlined, color: PremiumTheme.neonGreen, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nextMatch != null ? 'Match against Unknown' : 'No upcoming matches',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextMatch != null ? nextMatch.scheduledAt : 'Stay tuned for updates',
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
                      child: PremiumStatCard(
                        title: 'My Teams',
                        value: teamCount.toString(),
                        icon: Icons.group_outlined,
                        color: PremiumTheme.electricBlue,
                        subtitle: 'Active',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PremiumStatCard(
                        title: 'Performance',
                        value: '8.4',
                        icon: Icons.trending_up,
                        color: PremiumTheme.neonGreen,
                        subtitle: 'Rating',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text('EXPLORE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 2)),
                const SizedBox(height: 12),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildQuickAction(
                      context: context,
                      label: 'Find Match',
                      icon: Icons.search_rounded,
                      color: Colors.blue,
                      route: 'Find Match',
                    ),
                    _buildQuickAction(
                      context: context,
                      label: 'Book Field',
                      icon: Icons.stadium_outlined,
                      color: Colors.orange,
                      route: 'Book Field',
                    ),
                    _buildQuickAction(
                      context: context,
                      label: 'Club Hub',
                      icon: Icons.add_moderator_outlined,
                      color: Colors.purple,
                      route: 'Club Hub',
                      child: const ClubDashboardScreen(),
                    ),
                    _buildQuickAction(
                      context: context,
                      label: 'Tournaments',
                      icon: Icons.emoji_events_outlined,
                      color: Colors.amber,
                      route: 'Tournaments',
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

  Widget _buildQuickAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required String route,
    Widget? child,
  }) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => child ?? TemporaryScreen(title: route))
      ),
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
