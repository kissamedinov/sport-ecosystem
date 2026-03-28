import 'package:flutter/material.dart';
import '../../../../core/api/stats_api_service.dart';
import '../../data/models/player_stats.dart';
import '../widgets/stat_card.dart';

class PlayerStatsScreen extends StatefulWidget {
  final String playerId;

  const PlayerStatsScreen({super.key, required this.playerId});

  @override
  _PlayerStatsScreenState createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  final StatsApiService _apiService = StatsApiService();
  late Future<PlayerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _apiService.getPlayerStats(widget.playerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Player Profile"),
        backgroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: FutureBuilder<PlayerStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final stats = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(stats),
                const SizedBox(height: 24),
                _buildStatsGrid(stats),
                const SizedBox(height: 32),
                _buildAwardsSection(stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(PlayerStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: Colors.indigo[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            child: Text(
              stats.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            stats.name,
            style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Forward", // In real app, we'd have position in the model
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(PlayerStats stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          StatCard(label: "Goals", value: "${stats.goals}", icon: Icons.sports_soccer, color: Colors.green),
          StatCard(label: "Assists", value: "${stats.assists}", icon: Icons.assistant, color: Colors.blue),
          StatCard(label: "Saves", value: "${stats.saves}", icon: Icons.front_hand, color: Colors.orange),
          StatCard(label: "Yellow", value: "${stats.yellowCards}", icon: Icons.square, color: Colors.yellow[700]!),
          StatCard(label: "Red", value: "${stats.redCards}", icon: Icons.square, color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildAwardsSection(PlayerStats stats) {
    if (stats.awards.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Career Awards",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.awards.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                  title: Text(
                    stats.awards[index],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.star, color: Colors.amberAccent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
