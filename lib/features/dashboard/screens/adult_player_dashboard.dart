import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../../clubs/presentation/screens/club_dashboard_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../widgets/dashboard_widgets.dart';

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
      appBar: AppBar(
        title: const Text('FOOTBALL HUB'),
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  title: 'Hello, ${user?.name ?? 'Player'}!',
                  subtitle: 'ADULT PLAYER',
                ),
                const SizedBox(height: 24),
                DashboardActionCard(
                  title: 'Your Next Match',
                  subtitle: nextMatch != null 
                    ? 'Scheduled: ${nextMatch.scheduledAt}' 
                    : 'No upcoming matches scheduled',
                  icon: Icons.timer_outlined,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Match Details')));
                  },
                ),
                const SizedBox(height: 16),
                DashboardActionCard(
                  title: 'My Teams',
                  subtitle: teamCount == 0 
                    ? 'Not part of any teams yet' 
                    : 'Currently in $teamCount team${teamCount > 1 ? 's' : ''}',
                  icon: Icons.group_outlined,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'My Teams')));
                  },
                ),
                const SizedBox(height: 32),
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    DashboardGridAction(
                      label: 'Find Match',
                      icon: Icons.search,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Find Match'))),
                    ),
                    DashboardGridAction(
                      label: 'Book Field',
                      icon: Icons.calendar_month,
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Book Field'))),
                    ),
                    DashboardGridAction(
                      label: 'Create Club',
                      icon: Icons.add_business,
                      color: Colors.deepPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClubDashboardScreen())), 
                    ),
                    DashboardGridAction(
                      label: 'Tournaments',
                      icon: Icons.emoji_events,
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Tournaments'))),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Temporary screen for navigation placeholder
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
