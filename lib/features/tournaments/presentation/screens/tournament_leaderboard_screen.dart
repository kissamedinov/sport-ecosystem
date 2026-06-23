import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../widgets/leaderboard_item.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentLeaderboardScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentLeaderboardScreen({super.key, required this.tournamentId});

  @override
  State<TournamentLeaderboardScreen> createState() => _TournamentLeaderboardScreenState();
}

class _TournamentLeaderboardScreenState extends State<TournamentLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  late Future<Map<String, dynamic>> _leaderboardsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _leaderboardsFuture = _fetchLeaderboards();
  }

  Future<Map<String, dynamic>> _fetchLeaderboards() async {
    try {
      final response = await _apiClient.get('/tournaments/${widget.tournamentId}/leaderboards');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("Failed to fetch leaderboards: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'СТАТИСТИКА'.tr(),
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'Бомбардиры'),
            Tab(text: 'Ассистенты'),
            Tab(text: 'Вратари'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _leaderboardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'tournament.error_message'.tr(namedArgs: {'error': snapshot.error.toString()}),
                style: const TextStyle(color: PremiumTheme.danger),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final scorers = data['scorers'] as List? ?? [];
          final assists = data['assists'] as List? ?? [];
          final cleanSheets = data['clean_sheets'] as List? ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLeaderboardList(scorers, Icons.sports_soccer, PremiumTheme.neonGreen),
              _buildLeaderboardList(assists, Icons.help_outline_rounded, Colors.blueAccent),
              _buildLeaderboardList(cleanSheets, Icons.shield_outlined, Colors.amber),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardList(List<dynamic> items, IconData icon, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Данные пока отсутствуют',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LeaderboardItem(
            name: item['name'] ?? 'Игрок',
            teamName: item['team_name'],
            rank: index + 1,
            value: item['value'] ?? 0,
            icon: icon,
            highlightColor: color,
          ),
        );
      },
    );
  }
}
