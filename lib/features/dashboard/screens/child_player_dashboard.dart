import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../widgets/dashboard_widgets.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import 'adult_player_dashboard.dart'; // for TemporaryScreen

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
                  title: 'Hi, ${user?.name ?? 'Player'}!',
                  subtitle: 'YOUTH PLAYER',
                ),
                const SizedBox(height: 24),
                DashboardActionCard(
                  title: 'Upcoming Match',
                  subtitle: nextMatch != null 
                    ? 'vs ${nextMatch.awayTeamId == teamProvider.myTeams.firstOrNull?.id ? nextMatch.homeTeamId.substring(0,8) : nextMatch.awayTeamId.substring(0,8)} on ${nextMatch.scheduledAt}'
                    : 'No matches scheduled',
                  icon: Icons.sports_soccer,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Match Details')));
                  },
                ),
                const SizedBox(height: 16),
                DashboardActionCard(
                  title: 'My Team',
                  subtitle: teamCount > 0 
                    ? 'Playing for ${teamProvider.myTeams.first.name}' 
                    : 'Not assigned to a team',
                  icon: Icons.shield,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'My Team')));
                  },
                ),
                const SizedBox(height: 32),
                const Text('My Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      label: 'My Stats',
                      icon: Icons.bar_chart,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'My Statistics'))),
                    ),
                    DashboardGridAction(
                      label: 'Awards',
                      icon: Icons.emoji_events,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Best Player Awards'))),
                    ),
                    DashboardGridAction(
                      label: 'Coach Feedback',
                      icon: Icons.chat_bubble_outline,
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Message from Coach'))),
                    ),
                    DashboardGridAction(
                      label: 'Training',
                      icon: Icons.fitness_center,
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Training Schedule'))),
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
