import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../widgets/dashboard_widgets.dart';
import 'adult_player_dashboard.dart'; // for TemporaryScreen
import '../../children/presentation/screens/child_list_screen.dart';
import '../../children/providers/child_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildProvider>().fetchChildren();
      context.read<MatchProvider>().fetchMatches();
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PARENT HUB'),
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
      body: Consumer2<ChildProvider, MatchProvider>(
        builder: (context, childProvider, matchProvider, _) {
          final childrenCount = childProvider.children.length;
          final childMatchesCount = matchProvider.matches.length; // Simplified: just showing count for now
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  title: 'Hello, ${user?.name ?? 'Parent'}!',
                  subtitle: 'PARENT / GUARDIAN',
                ),
                const SizedBox(height: 24),
                DashboardActionCard(
                  title: 'My Children',
                  subtitle: childrenCount == 0 
                    ? 'No children linked yet' 
                    : 'Managing $childrenCount child${childrenCount > 1 ? 'ren' : ''}',
                  icon: Icons.child_care,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildListScreen()));
                  },
                ),
                const SizedBox(height: 16),
                DashboardActionCard(
                  title: 'Upcoming Matches',
                  subtitle: childMatchesCount == 0 
                    ? 'No upcoming matches for your children' 
                    : '$childMatchesCount match${childMatchesCount > 1 ? 'es' : ''} scheduled for your family',
                  icon: Icons.event,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: "Children's Matches")));
                  },
                ),
                const SizedBox(height: 32),
                const Text('Parent Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      label: 'Coach Notes',
                      icon: Icons.message,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Coach Feedback'))),
                    ),
                    DashboardGridAction(
                      label: 'Academy Updates',
                      icon: Icons.school,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Academy Info'))),
                    ),
                    DashboardGridAction(
                      label: 'Attendance',
                      icon: Icons.checklist,
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Attendance'))),
                    ),
                    DashboardGridAction(
                      label: 'Payments',
                      icon: Icons.payment,
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Payments'))),
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
