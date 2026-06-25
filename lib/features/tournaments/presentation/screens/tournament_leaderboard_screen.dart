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
  late Future<List<dynamic>> _leaderboardsFuture;
  String? _selectedDivisionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _leaderboardsFuture = _fetchLeaderboards();
  }

  Future<List<dynamic>> _fetchLeaderboards() async {
    try {
      final response = await _apiClient.get('/tournaments/${widget.tournamentId}/leaderboards');
      return response.data as List<dynamic>;
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
        backgroundColor: PremiumTheme.surfaceCard(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'СТАТИСТИКА'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.accent(context),
          labelColor: PremiumTheme.accent(context),
          unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'БОМБАРДИРЫ'),
            Tab(text: 'АССИСТЕНТЫ'),
            Tab(text: 'ВРАТАРИ'),
            Tab(text: 'ГОЛ+ПАС'),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
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

          final divisionsData = snapshot.data ?? [];
          if (divisionsData.isEmpty) {
            return Center(
              child: Text(
                'Данные пока отсутствуют',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            );
          }

          if (_selectedDivisionId == null && divisionsData.isNotEmpty) {
            _selectedDivisionId = divisionsData.first['division_id'];
          }

          final currentDivisionData = divisionsData.firstWhere(
            (d) => d['division_id'] == _selectedDivisionId,
            orElse: () => divisionsData.first,
          );

          final scorers = currentDivisionData['scorers'] as List? ?? [];
          final assists = currentDivisionData['assists'] as List? ?? [];
          final cleanSheets = currentDivisionData['clean_sheets'] as List? ?? [];
          final goalPlusPass = currentDivisionData['goal_plus_pass'] as List? ?? [];

          return Column(
            children: [
              if (divisionsData.length > 1)
                Container(
                  color: PremiumTheme.surfaceCard(context),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: divisionsData.map((d) {
                        final isSelected = _selectedDivisionId == d['division_id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDivisionId = d['division_id'];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? PremiumTheme.accent(context) : cs.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                d['division_name']?.toUpperCase() ?? 'DIVISION',
                                style: TextStyle(
                                  color: isSelected ? Colors.black : cs.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardList(scorers, Icons.sports_soccer, PremiumTheme.neonGreen),
                    _buildLeaderboardList(assists, Icons.help_outline_rounded, Colors.blueAccent),
                    _buildLeaderboardList(cleanSheets, Icons.shield_outlined, Colors.amber),
                    _buildLeaderboardList(goalPlusPass, Icons.local_fire_department, Colors.deepOrangeAccent),
                  ],
                ),
              ),
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
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return LeaderboardItem(
          name: item['name'] ?? 'Игрок',
          teamName: item['team_name'],
          rank: index + 1,
          value: item['value'] ?? 0,
          icon: icon,
          highlightColor: color,
        );
      },
    );
  }
}
