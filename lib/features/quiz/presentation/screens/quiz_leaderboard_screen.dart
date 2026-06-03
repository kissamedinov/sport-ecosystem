import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../providers/quiz_provider.dart';
import '../../data/models/quiz_model.dart';

class QuizLeaderboardScreen extends StatefulWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  State<QuizLeaderboardScreen> createState() => _QuizLeaderboardScreenState();
}

class _QuizLeaderboardScreenState extends State<QuizLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: const Text(
          'GLOBAL LEADERS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.error != null && provider.leaderboard.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLeaderboard(),
                    style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen),
                    child: const Text('Retry', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }

          if (provider.leaderboard.isEmpty) {
            return const Center(
              child: Text(
                'No leaderboard data available.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return RefreshIndicator(
            color: PremiumTheme.neonGreen,
            onRefresh: () => provider.fetchLeaderboard(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.leaderboard.length,
              itemBuilder: (context, index) {
                final entry = provider.leaderboard[index];
                return _buildLeaderboardTile(context, entry, index + 1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, QuizLeaderboardEntry entry, int rank) {
    final medalColors = [Colors.amber, Colors.grey.shade400, const Color(0xFFCD7F32)];
    final color = rank <= 3 ? medalColors[rank - 1] : Colors.blueGrey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
              fontSize: 15,
            ),
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.deepOrange),
            const SizedBox(width: 4),
            Text(
              '${entry.streak} DAY STREAK',
              style: TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.points} PTS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
