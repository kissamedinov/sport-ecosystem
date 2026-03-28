import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../matches/providers/match_provider.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/core/theme/premium_theme.dart';
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
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('PARENT HUB', style: TextStyle(letterSpacing: 2)),
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
      body: Consumer2<ChildProvider, MatchProvider>(
        builder: (context, childProvider, matchProvider, _) {
          final childrenCount = childProvider.children.length;
          final childMatchesCount = matchProvider.matches.length;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumHeader(
                  title: 'Hello, ${(user?.name ?? 'Parent').split(' ').first}!',
                  subtitle: 'PARENT / GUARDIAN',
                  trailing: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    child: const Icon(Icons.family_restroom, color: Colors.orange),
                  ),
                ),

                const Text('FAMILY ACTIVITY', 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: PremiumStatCard(
                        title: 'Children',
                        value: childrenCount.toString(),
                        icon: Icons.child_care_rounded,
                        color: PremiumTheme.electricBlue,
                        subtitle: 'Linked',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PremiumStatCard(
                        title: 'Matches',
                        value: childMatchesCount.toString(),
                        icon: Icons.sports_soccer_rounded,
                        color: PremiumTheme.neonGreen,
                        subtitle: 'This Week',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                PremiumCard(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildListScreen())),
                  child: const Row(
                    children: [
                      Icon(Icons.people_outline, color: PremiumTheme.neonGreen),
                      SizedBox(width: 16),
                      Expanded(child: Text('MANAGE CHILDREN PROFILES', style: TextStyle(fontWeight: FontWeight.bold))),
                      Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('PARENT TOOLS', 
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
                    _buildToolAction(
                      context: context,
                      label: 'Coach Notes',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: Colors.blueAccent,
                      title: 'Coach Feedback',
                    ),
                    _buildToolAction(
                      context: context,
                      label: 'Academy',
                      icon: Icons.school_outlined,
                      color: Colors.orangeAccent,
                      title: 'Academy Info',
                    ),
                    _buildToolAction(
                      context: context,
                      label: 'Attendance',
                      icon: Icons.playlist_add_check_rounded,
                      color: Colors.greenAccent,
                      title: 'Attendance',
                    ),
                    _buildToolAction(
                      context: context,
                      label: 'Payments',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.purpleAccent,
                      title: 'Payments',
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

  Widget _buildToolAction({
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
