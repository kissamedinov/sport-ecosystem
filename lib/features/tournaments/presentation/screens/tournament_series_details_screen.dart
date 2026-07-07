import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_page.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament_series.dart';

class TournamentSeriesDetailsScreen extends StatefulWidget {
  final String seriesId;
  const TournamentSeriesDetailsScreen({super.key, required this.seriesId});

  @override
  State<TournamentSeriesDetailsScreen> createState() => _TournamentSeriesDetailsScreenState();
}

class _CreateSeriesTournamentButton extends StatelessWidget {
  final String seriesId;
  const _CreateSeriesTournamentButton({required this.seriesId});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isOrganizer = user != null && user.roles?.contains('TOURNAMENT_ORGANIZER') == true;

    if (!isOrganizer) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumButton(
        text: 'Создать новый сезон / турнир',
        icon: Icons.add,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTournamentScreen(seriesId: seriesId),
            ),
          ).then((_) {
            context.read<TournamentProvider>().fetchTournamentSeriesDetail(seriesId);
          });
        },
      ),
    );
  }
}

class _TournamentSeriesDetailsScreenState extends State<TournamentSeriesDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournamentSeriesDetail(widget.seriesId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<TournamentProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final detail = provider.selectedSeriesDetail;
    final isLoading = provider.isLoading;
    final error = provider.error;

    if (isLoading && detail == null) {
      return Scaffold(
        backgroundColor: PremiumTheme.surfaceBase(context),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen)),
      );
    }

    if (error != null && detail == null) {
      return Scaffold(
        backgroundColor: PremiumTheme.surfaceBase(context),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error', style: TextStyle(color: cs.error)),
              const SizedBox(height: 16),
              PremiumButton(
                text: 'Retry',
                onPressed: () {
                  context.read<TournamentProvider>().fetchTournamentSeriesDetail(widget.seriesId);
                },
              ),
            ],
          ),
        ),
      );
    }

    if (detail == null) {
      return Scaffold(
        backgroundColor: PremiumTheme.surfaceBase(context),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Лига не найдена')),
      );
    }

    final isOrganizer = context.watch<AuthProvider>().user?.roles?.contains('TOURNAMENT_ORGANIZER') == true;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          detail.name.toUpperCase(),
          style: const TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          // Aegis Banner Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: PremiumCard(
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                      ),
                    ),
                    child: detail.logoUrl != null && detail.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(detail.logoUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.emoji_events, color: PremiumTheme.neonGreen, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: cs.onSurfaceVariant, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              detail.city,
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                        if (detail.description != null && detail.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            detail.description!,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom Premium Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: isDark ? 0.05 : 0.1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: PremiumTheme.neonGreen,
                unselectedLabelColor: cs.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                tabs: const [
                  Tab(text: 'Сезоны'),
                  Tab(text: 'Чемпионы'),
                  Tab(text: 'Таблица'),
                  Tab(text: 'Игроки'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSeasonsTab(detail, cs, isDark),
                _buildChampionsTab(detail, cs, isDark),
                _buildLeaderboardTab(detail, cs, isDark),
                _buildPlayersTab(detail, cs, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Seasons Tab
  Widget _buildSeasonsTab(TournamentSeriesDetail detail, ColorScheme cs, bool isDark) {
    if (detail.editions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'В этой лиге пока нет турниров',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _CreateSeriesTournamentButton(seriesId: detail.id),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _CreateSeriesTournamentButton(seriesId: detail.id),
        ...detail.editions.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentDetailsPage(tournamentId: t.id),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.1),
                      ),
                    ),
                    child: t.logoUrl != null && t.logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(t.logoUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.sports_soccer, color: PremiumTheme.neonGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.startDate} — ${t.endDate}',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 2. Champions (Hall of Fame) Tab
  Widget _buildChampionsTab(TournamentSeriesDetail detail, ColorScheme cs, bool isDark) {
    if (detail.champions.isEmpty) {
      return Center(
        child: Text(
          'Победители пока не определены',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    final goldColor = isDark ? const Color(0xFFFFB300) : const Color(0xFFD97706);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: detail.champions.length,
      itemBuilder: (context, index) {
        final c = detail.champions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: goldColor, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.teamName,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${c.tournamentName} (${c.divisionName})',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (c.year != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: goldColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${c.year}',
                      style: TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Leaderboard Tab
  Widget _buildLeaderboardTab(TournamentSeriesDetail detail, ColorScheme cs, bool isDark) {
    if (detail.teamLeaderboard.isEmpty) {
      return Center(
        child: Text(
          'История игр команд пуста',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 8,
            columns: const [
              DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Команда', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('И', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('В', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Н', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('П', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Мячи', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Очки', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: List.generate(detail.teamLeaderboard.length, (index) {
              final t = detail.teamLeaderboard[index];
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index == 0 ? PremiumTheme.neonGreen : cs.onSurface,
                        fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (t.logoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(t.logoUrl!, width: 20, height: 20, fit: BoxFit.cover),
                          )
                        else
                          const Icon(Icons.shield, size: 20, color: PremiumTheme.neonGreen),
                        const SizedBox(width: 8),
                        Text(
                          t.teamName,
                          style: TextStyle(
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('${t.played}')),
                  DataCell(Text('${t.wins}')),
                  DataCell(Text('${t.draws}')),
                  DataCell(Text('${t.losses}')),
                  DataCell(Text('${t.goalsFor}-${t.goalsAgainst}')),
                  DataCell(
                    Text(
                      '${t.points}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index == 0 ? PremiumTheme.neonGreen : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // 4. Players Tab
  Widget _buildPlayersTab(TournamentSeriesDetail detail, ColorScheme cs, bool isDark) {
    if (detail.playerLeaderboard.isEmpty) {
      return Center(
        child: Text(
          'История статистики игроков пуста',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: detail.playerLeaderboard.length,
      itemBuilder: (context, index) {
        final p = detail.playerLeaderboard[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PremiumCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                    ),
                  ),
                  child: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(p.avatarUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.person, color: PremiumTheme.neonGreen, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.playerName,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Всего голов: ${p.goals}  |  Голевых передач: ${p.assists}',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (p.yellowCards > 0) ...[
                      Container(
                        width: 12,
                        height: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text('${p.yellowCards}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                      const SizedBox(width: 8),
                    ],
                    if (p.redCards > 0) ...[
                      Container(
                        width: 12,
                        height: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text('${p.redCards}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
