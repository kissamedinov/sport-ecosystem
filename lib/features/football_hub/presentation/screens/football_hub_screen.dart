import 'package:flutter/material.dart';
import '../../../teams/presentation/screens/team_leaderboard_screen.dart';

class FootballHubScreen extends StatelessWidget {
  const FootballHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FOOTBALL HUB')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQuizCard(context),
            const SizedBox(height: 16),
            _buildRankingsCard(context),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Top Academies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            _buildAcademyList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeamLeaderboardScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.leaderboard, size: 32, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Global Team Rankings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'See who is dominating the ecosystem',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.quiz, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            const Text('Daily Football Quiz', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Test your knowledge and win points!'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Start Quiz')),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademyList() {
    return Column(
      children: [
        ListTile(
          leading: const CircleAvatar(child: Text('1')),
          title: const Text('Real Madrid Academy'),
          subtitle: const Text('Rating: 4.9/5'),
          trailing: const Icon(Icons.star, color: Colors.amber),
        ),
        ListTile(
          leading: const CircleAvatar(child: Text('2')),
          title: const Text('Barcelona Academy'),
          subtitle: const Text('Rating: 4.8/5'),
          trailing: const Icon(Icons.star, color: Colors.amber),
        ),
      ],
    );
  }
}
