import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/tournaments/providers/tournament_provider.dart';
import 'package:mobile/features/tournaments/presentation/screens/create_tournament_screen.dart';
import 'package:mobile/features/tournaments/presentation/screens/tournament_list_screen.dart';
import 'package:mobile/features/teams/presentation/screens/team_management_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_screen.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() => _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrimaryAction(context),
                      const SizedBox(height: 24),
                      _buildSectionHeader("OPERATIONAL OVERVIEW"),
                      const SizedBox(height: 16),
                      _buildStatsGrid(context, provider),
                      const SizedBox(height: 24),
                      _buildSectionHeader("PENDING APPROVALS"),
                      const SizedBox(height: 12),
                      _buildEmptyPlaceholder(
                        context, 
                        "No pending team registrations at the moment.", 
                        Icons.assignment_ind_outlined
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader("UPCOMING DEADLINES"),
                      const SizedBox(height: 12),
                      _buildEmptyPlaceholder(
                        context, 
                        "Your calendar is clear. No immediate deadlines found.", 
                        Icons.calendar_today_outlined
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: PremiumTheme.surfaceBase(context),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          "ORGANIZER HUB",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PremiumTheme.neonGreen.withValues(alpha: 0.05), Colors.transparent],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTournamentScreen()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [PremiumTheme.neonGreen, Color(0xFFADFF2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Launch Tournament",
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    "Start your next big event",
                    style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), letterSpacing: 2),
    );
  }

  Widget _buildStatsGrid(BuildContext context, TournamentProvider provider) {
    final active = provider.tournaments.where((t) => t.status == 'upcoming' || t.status == 'scheduled').length;
    
    return Row(
      children: [
        _statCard(
          context, 
          "ACTIVE", "$active", "TOURNAMENTS", 
          Icons.emoji_events_rounded, 
          PremiumTheme.electricBlue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen())),
        ),
        const SizedBox(width: 12),
        _statCard(
          context, 
          "TOTAL", "48", "TEAMS", 
          Icons.group_rounded, 
          Colors.purpleAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamManagementScreen())),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String tag, String value, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (onTap != null) onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Text(tag, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 16),
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context, String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
