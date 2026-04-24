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

  Widget _buildAnnouncementCard(BuildContext context, Tournament t) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.2)),
                ),
                child: Text(
                  t.ageCategory,
                  style: const TextStyle(color: PremiumTheme.electricBlue, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TournamentDetailsPage(tournamentId: t.id),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
              ),
              ElevatedButton(
                onPressed: () => _showApplyDialog(context, t),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumTheme.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('APPLY WITH TEAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showApplyDialog(BuildContext context, Tournament t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('APPLY FOR TOURNAMENT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('To register your team, please contact the organizer or use the direct registration button below.', 
              style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            if (t.whatsapp != null || t.phone != null) ...[
              const Text('ORGANIZER CONTACTS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 12),
              if (t.whatsapp != null)
                ListTile(
                  leading: const Icon(Icons.message, color: PremiumTheme.neonGreen),
                  title: Text(t.whatsapp!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('WhatsApp', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
              if (t.phone != null)
                ListTile(
                  leading: const Icon(Icons.phone, color: PremiumTheme.neonGreen),
                  title: Text(t.phone!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Phone', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TournamentDetailsPage(tournamentId: t.id)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
            child: const Text('GO TO REGISTRATION'),
          ),
        ],
      ),
    );
  }
}
