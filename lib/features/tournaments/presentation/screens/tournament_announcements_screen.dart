import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import 'tournament_details_page.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentAnnouncementsScreen extends StatefulWidget {
  const TournamentAnnouncementsScreen({super.key});

  @override
  State<TournamentAnnouncementsScreen> createState() => _TournamentAnnouncementsScreenState();
}

class _TournamentAnnouncementsScreenState extends State<TournamentAnnouncementsScreen> {
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
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TOURNAMENT ANNOUNCEMENTS', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          final announcements = provider.tournaments.where((t) => t.status == 'upcoming' || t.status == 'scheduled').toList();

          if (announcements.isEmpty) {
            return const Center(child: Text('No new announcements', style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final t = announcements[index];
              return _buildAnnouncementCard(context, t);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, dynamic t) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events, color: PremiumTheme.neonGreen, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text('${t.startDate} | ${t.location}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Age: ${t.ageCategory}',
                style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentDetailsPage(tournamentId: t.id),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: PremiumTheme.neonGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Row(
                  children: const [
                    Text('APPLY WITH TEAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
