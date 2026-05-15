import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../matches/providers/match_provider.dart';
import '../../clubs/presentation/screens/club_dashboard_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';
import '../../quiz/presentation/screens/daily_quiz_screen.dart';
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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: PremiumTheme.surfaceBase(context),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'FOOTBALL HUB',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
              ),
              centerTitle: true,
            ),
            actions: [
              _buildNotificationIcon(),
              const SizedBox(width: 10),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer2<TeamProvider, MatchProvider>(
              builder: (context, teamProvider, matchProvider, _) {
                final teamCount = teamProvider.myTeams.length;
                final nextMatch = matchProvider.matches.isNotEmpty ? matchProvider.matches.first : null;
                
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user),
                      const SizedBox(height: 24),
                      
                      _buildDailyQuizBanner(),
                      const SizedBox(height: 28),

                      _buildSectionLabel("YOUR NEXT CHALLENGE"),
                      const SizedBox(height: 12),
                      _buildMatchChallenge(nextMatch),
                      
                      const SizedBox(height: 28),
                      _buildSectionLabel("CAREER GLANCE"),
                      const SizedBox(height: 12),
                      _buildStatsRow(teamCount),

                      const SizedBox(height: 28),
                      _buildSectionLabel("EXPLORE SERVICES"),
                      const SizedBox(height: 12),
                      _buildQuickActionsGrid(),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 26),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(user) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${(user?.name ?? 'Player').split(' ').first}!',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ADULT PLAYER',
                      style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.person_rounded, color: PremiumTheme.neonGreen),
        ),
      ],
    );
  }

  Widget _buildDailyQuizBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [PremiumTheme.neonGreen.withValues(alpha: 0.8), PremiumTheme.neonGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: PremiumTheme.neonShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colors.black, size: 28),
              const SizedBox(width: 12),
              const Text(
                "FOOTBALL IQ QUIZ",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("DAILY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Test your knowledge with today's advanced challenges and earn ranking points.",
            style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyQuizScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: PremiumTheme.neonGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text("START CHALLENGE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchChallenge(nextMatch) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: PremiumTheme.electricBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.timer_outlined, color: PremiumTheme.electricBlue, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextMatch != null ? 'Vs Unknown Team' : 'No matches found',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                Text(
                  nextMatch != null ? nextMatch.scheduledAt : 'Check back later for updates',
                  style: TextStyle(color: onSurface.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int teamCount) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard("MY TEAMS", teamCount.toString(), Icons.groups_rounded, PremiumTheme.electricBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallStatCard("AVG RATING", "8.4", Icons.auto_graph_rounded, PremiumTheme.neonGreen),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, IconData icon, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: onSurface.withValues(alpha: 0.4), letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActionTile("Find Match", Icons.search_rounded, Colors.blue),
        _buildActionTile("Book Field", Icons.stadium_outlined, Colors.orange),
        _buildActionTile("Club Hub", Icons.shield_outlined, Colors.purple),
        _buildActionTile("Tournaments", Icons.emoji_events_outlined, Colors.amber),
      ],
    );
  }

  Widget _buildActionTile(String label, IconData icon, Color color) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.grey)),
      ],
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
