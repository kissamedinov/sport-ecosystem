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
      backgroundColor: PremiumTheme.surfaceBase(context),
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
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.family_restroom, color: Colors.orange),
                  ),
                ),

                const SizedBox(height: 24),
                _buildSectionLabel("FAMILY ACTIVITY"),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.child_care_rounded,
                        value: '$childrenCount',
                        label: 'KIDS',
                        badge: 'LINKED',
                        accent: const Color(0xFFE0AE5A),
                        cardBg: const Color(0xFF1E1508),
                        borderColor: const Color(0xFF7A4818),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.sports_soccer_rounded,
                        value: '$childMatchesCount',
                        label: 'MATCHES',
                        badge: 'WEEKLY',
                        accent: const Color(0xFF72C09A),
                        cardBg: const Color(0xFF101C12),
                        borderColor: const Color(0xFF2A5C32),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                _buildManageChildrenCard(context),

                const SizedBox(height: 28),
                _buildSectionLabel("PARENT TOOLS"),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Coach Feedback'))),
                      child: _buildStatCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        value: 'READ',
                        label: 'COACH NOTES',
                        badge: 'MSG',
                        accent: const Color(0xFF80AADC),
                        cardBg: const Color(0xFF111E2A),
                        borderColor: const Color(0xFF224A72),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Academy Info'))),
                      child: _buildStatCard(
                        icon: Icons.school_outlined,
                        value: 'VIEW',
                        label: 'ACADEMY',
                        badge: 'INFO',
                        accent: const Color(0xFFE0AE5A),
                        cardBg: const Color(0xFF1E1508),
                        borderColor: const Color(0xFF7A4818),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Attendance'))),
                      child: _buildStatCard(
                        icon: Icons.playlist_add_check_rounded,
                        value: 'CHECK',
                        label: 'ATTENDANCE',
                        badge: 'TRACK',
                        accent: const Color(0xFF72C09A),
                        cardBg: const Color(0xFF101C12),
                        borderColor: const Color(0xFF2A5C32),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TemporaryScreen(title: 'Payments'))),
                      child: _buildStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        value: 'PAY',
                        label: 'PAYMENTS',
                        badge: 'WALLET',
                        accent: const Color(0xFFB490D0),
                        cardBg: const Color(0xFF1A0E1E),
                        borderColor: const Color(0xFF4E2068),
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

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildManageChildrenCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildListScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PremiumTheme.neonGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_outline, color: PremiumTheme.neonGreen, size: 20),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'MANAGE CHILDREN PROFILES',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: accent, size: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: accent, fontSize: 8, letterSpacing: 0.6, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.bold, height: 1.0),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: accent.withValues(alpha: 0.5), fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w600),
          ),
        ],
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
