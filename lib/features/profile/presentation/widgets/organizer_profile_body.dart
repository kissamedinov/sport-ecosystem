import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/premium_theme.dart';
import '../../../core/presentation/widgets/premium_widgets.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament.dart';
import '../screens/tournament_details_page.dart';
import '../screens/create_tournament_screen.dart';

class OrganizerProfileBody extends StatefulWidget {
  const OrganizerProfileBody({super.key});

  @override
  State<OrganizerProfileBody> createState() => _OrganizerProfileBodyState();
}

class _OrganizerProfileBodyState extends State<OrganizerProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournaments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TournamentProvider>(
      builder: (context, provider, _) {
        final myTournaments = provider.tournaments; // In real app, filter by creator_id

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionLabel("ORGANIZER DASHBOARD"),
              const SizedBox(height: 16),
              _buildStatsGrid(myTournaments),
              const SizedBox(height: 28),
              _buildSectionLabel("QUICK ACTIONS"),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionLabel("MY TOURNAMENTS"),
                  TextButton(
                    onPressed: () {},
                    child: const Text('VIEW ALL', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.isLoading)
                const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
              else if (myTournaments.isEmpty)
                _buildEmptyState("No tournaments created yet.", Icons.emoji_events_outlined)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: myTournaments.length,
                  itemBuilder: (context, index) {
                    return _buildTournamentCard(context, myTournaments[index]);
                  },
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(color: PremiumTheme.neonGreen, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(List<Tournament> tournaments) {
    final active = tournaments.where((t) => t.status == 'upcoming' || t.status == 'scheduled').length;
    final finished = tournaments.where((t) => t.status == 'finished').length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Active", "$active", Icons.play_circle_filled_rounded, PremiumTheme.neonGreen),
        _buildStatCard("Finished", "$finished", Icons.check_circle_rounded, PremiumTheme.electricBlue),
        _buildStatCard("Total Teams", "48", Icons.groups_rounded, Colors.amber),
        _buildStatCard("Total Revenue", "$1.2k", Icons.payments_rounded, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
              Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _actionBtn(
            label: "CREATE",
            icon: Icons.add_rounded,
            color: PremiumTheme.neonGreen,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTournamentScreen()));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            label: "SCHEDULE",
            icon: Icons.calendar_today_rounded,
            color: PremiumTheme.electricBlue,
            onTap: () {
              HapticFeedback.mediumImpact();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionBtn(
            label: "REQUESTS",
            icon: Icons.notifications_active_rounded,
            color: Colors.orangeAccent,
            onTap: () {
              HapticFeedback.mediumImpact();
            },
          ),
        ),
      ],
    );
  }

  Widget _actionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentCard(BuildContext context, Tournament t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailsPage(tournamentId: t.id)));
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: PremiumTheme.glassDecorationOf(context, radius: 24),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: PremiumTheme.neonGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('${t.startDate} • ${t.location}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.status == 'upcoming' ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t.status.toUpperCase(),
                  style: TextStyle(
                    color: t.status == 'upcoming' ? PremiumTheme.neonGreen : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white12, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}
