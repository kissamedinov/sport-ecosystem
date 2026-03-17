import 'package:flutter/material.dart';

class TournamentAnnouncementsScreen extends StatelessWidget {
  const TournamentAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOURNAMENT ANNOUNCEMENTS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAnnouncementCard(
            context,
            'SD CUP FESTIVAL',
            'March 23–25 | Astana',
            '50,000 KZT | Age: 2011-2018',
            Icons.emoji_events,
          ),
          const SizedBox(height: 16),
          _buildAnnouncementCard(
            context,
            'Winter Championship',
            'Jan 15–20 | Almaty',
            '45,000 KZT | Age: 2010-2015',
            Icons.sports_soccer,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(BuildContext context, String title, String subtitle, String price, IconData icon) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.orange, size: 40),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(price, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {},
                  child: const Text('APPLY WITH TEAM'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
