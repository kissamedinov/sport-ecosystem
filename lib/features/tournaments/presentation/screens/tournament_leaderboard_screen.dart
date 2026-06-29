import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../widgets/leaderboard_item.dart';
import '../../../../core/theme/premium_theme.dart';

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
              // 1. PRIMARY FILTER: DIVISION SELECTOR (AT THE VERY TOP)
              Container(
                color: PremiumTheme.surfaceCard(context),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? PremiumTheme.neonGreen : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
                                  : null,
                            ),
                            child: Text(
                              d['division_name']?.toUpperCase() ?? 'DIVISION',
                              style: TextStyle(
                                color: isSelected ? Colors.black : cs.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
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

              // 2. SECONDARY FILTER: STATS CATEGORY TAB BAR
              Container(
                color: PremiumTheme.surfaceCard(context),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: PremiumTheme.accent(context),
                  labelColor: PremiumTheme.accent(context),
                  unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.white.withValues(alpha: 0.05),
                  indicatorWeight: 3,
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

              // 3. STATS LIST FOR SELECTED DIVISION & CATEGORY
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats_rounded, size: 48, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 12),
            Text(
              'Данные пока отсутствуют',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
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
