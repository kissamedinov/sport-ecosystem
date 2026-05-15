import 'package:flutter/material.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/orleon_widgets.dart';
import 'package:mobile/features/quiz/presentation/screens/daily_quiz_screen.dart';
import '../../../teams/presentation/screens/team_leaderboard_screen.dart';

class FootballHubScreen extends StatelessWidget {
  const FootballHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'FOOTBALL HUB',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              PremiumTheme.neonGreen.withValues(alpha: 0.05),
              PremiumTheme.surfaceBase(context),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuizCard(context),
              const SizedBox(height: 24),
              const OrleonSectionHeader(title: "GLOBAL ANALYTICS"),
              _buildRankingsCard(context),
              const SizedBox(height: 24),
              const OrleonSectionHeader(title: "TOP ACADEMIES"),
              const SizedBox(height: 12),
              _buildAcademyList(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return OrleonCard(
      padding: const EdgeInsets.all(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          PremiumTheme.neonGreen.withValues(alpha: 0.15),
          PremiumTheme.electricBlue.withValues(alpha: 0.05),
        ],
      ),
      borderColor: PremiumTheme.neonGreen.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.quiz_rounded, size: 40, color: PremiumTheme.neonGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'DAILY FOOTBALL QUIZ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test your knowledge, win points and\nclimb the global leaderboard!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.neonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'START TODAY\'S CHALLENGE',
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsCard(BuildContext context) {
    return OrleonCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeamLeaderboardScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.leaderboard_rounded, size: 28, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TEAM RANKINGS',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Text(
                  'Global performance metrics',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildAcademyList(BuildContext context) {
    final academies = [
      {'name': 'Real Madrid Academy', 'rating': '4.9', 'rank': '1'},
      {'name': 'Barcelona Academy', 'rating': '4.8', 'rank': '2'},
      {'name': 'Manchester City', 'rating': '4.7', 'rank': '3'},
    ];

    return Column(
      children: academies.map((ac) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OrleonCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  ac['rank']!,
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ac['name']!.toUpperCase(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Rating: ${ac['rating']}/5',
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
