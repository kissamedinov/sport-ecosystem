import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tournament_provider.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_page.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament_series.dart';
import '../../data/models/tournament.dart';

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
            if (context.mounted) {
              context.read<TournamentProvider>().fetchTournamentSeriesDetail(seriesId);
            }
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
    _tabController = TabController(length: 3, vsync: this);
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
          style: GoogleFonts.outfit(
            letterSpacing: 1,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        actions: [
          if (isOrganizer)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: PremiumTheme.neonGreen),
              onPressed: () => _showEditSeriesDialog(context, detail),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Aegis Banner Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          PremiumTheme.surfaceCard(context),
                          PremiumTheme.surfaceCard(context).withValues(alpha: 0.8),
                        ]
                      : [
                          PremiumTheme.surfaceCard(context),
                          PremiumTheme.surfaceCard(context).withValues(alpha: 0.95),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: isDark ? 0.08 : 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStatLabel('league_details.stat_live'.tr(), detail.editions.where((t) => t.displayStatus == 'ACTIVE').length, PremiumTheme.neonGreen, cs),
                            const SizedBox(width: 10),
                            _buildStatLabel('league_details.stat_upcoming'.tr(), detail.editions.where((t) => t.displayStatus != 'ACTIVE' && t.displayStatus != 'FINISHED').length, Colors.lightBlueAccent, cs),
                            const SizedBox(width: 10),
                            _buildStatLabel('league_details.stat_past'.tr(), detail.editions.where((t) => t.displayStatus == 'FINISHED').length, cs.onSurfaceVariant.withValues(alpha: 0.6), cs),
                          ],
                        ),
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
                tabs: [
                  Tab(text: 'league_details.tabs_tournaments'.tr()),
                  Tab(text: 'league_details.tabs_champions'.tr()),
                  Tab(text: 'league_details.tabs_players'.tr()),
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
                _buildPlayersTab(detail, cs, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(String label, int count, Color color, ColorScheme cs) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$count $label',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
      ],
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
                'league_details.no_tournaments_in_league'.tr(),
                style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _CreateSeriesTournamentButton(seriesId: detail.id),
            ],
          ),
        ),
      );
    }

    final activeAndUpcoming = detail.editions.where((t) => t.displayStatus == 'ACTIVE' || t.displayStatus != 'FINISHED').toList();
    final finished = detail.editions.where((t) => t.displayStatus == 'FINISHED').toList();

    // Sort active & upcoming so active is first, then closest start date
    activeAndUpcoming.sort((a, b) {
      if (a.displayStatus == 'ACTIVE' && b.displayStatus != 'ACTIVE') return -1;
      if (b.displayStatus == 'ACTIVE' && a.displayStatus != 'ACTIVE') return 1;
      return a.startDate.compareTo(b.startDate);
    });

    // Sort finished descending (most recent first)
    finished.sort((a, b) => b.startDate.compareTo(a.startDate));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _CreateSeriesTournamentButton(seriesId: detail.id),
        if (activeAndUpcoming.isNotEmpty) ...[
          _buildListSectionTitle('league_details.current_and_upcoming'.tr(), activeAndUpcoming.length, cs),
          const SizedBox(height: 8),
          ...activeAndUpcoming.map((t) => _buildTournamentListItem(t, cs, isDark)),
          const SizedBox(height: 16),
        ],
        if (finished.isNotEmpty) ...[
          _buildListSectionTitle('league_details.past_tournaments'.tr(), finished.length, cs),
          const SizedBox(height: 8),
          ...finished.map((t) => _buildTournamentListItem(t, cs, isDark)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildListSectionTitle(String title, int count, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentListItem(Tournament t, ColorScheme cs, bool isDark) {
    final isFinished = t.displayStatus == 'FINISHED';
    final isActive = t.displayStatus == 'ACTIVE';

    Color statusColor = cs.onSurfaceVariant;
    String statusText = 'league_details.status_upcoming_badge'.tr();
    if (isActive) {
      statusColor = PremiumTheme.neonGreen;
      statusText = 'league_details.status_live'.tr();
    } else if (isFinished) {
      statusColor = cs.onSurfaceVariant.withValues(alpha: 0.6);
      statusText = 'league_details.status_finished_badge'.tr();
    }

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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.1),
                ),
              ),
              child: t.logoUrl != null && t.logoUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(t.logoUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.sports_soccer, color: PremiumTheme.neonGreen, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.name,
                          style: GoogleFonts.outfit(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: PremiumTheme.neonGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              statusText.toUpperCase(),
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${t.startDate} — ${t.endDate}',
                          style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (t.ageCategory.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.ageCategory.contains('г.р') ? t.ageCategory : '${t.ageCategory} г.р.',
                            style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.format.toUpperCase(),
                          style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDetailsPage(
                    tournamentId: c.tournamentId,
                    initialTabIndex: 1,
                  ),
                ),
              );
            },
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


  void _showEditSeriesDialog(BuildContext context, TournamentSeriesDetail detail) {
    final nameController = TextEditingController(text: detail.name);
    final cityController = TextEditingController(text: detail.city);
    final descController = TextEditingController(text: detail.description);
    final logoController = TextEditingController(text: detail.logoUrl);
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard(context),
          title: Text(
            'league_details.edit_league'.tr(),
            style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumTextField(
                  controller: nameController,
                  label: 'league_details.league_name'.tr(),
                  icon: Icons.emoji_events,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: cityController,
                  label: 'league_details.city'.tr(),
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: descController,
                  label: 'league_details.league_description'.tr(),
                  icon: Icons.description,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: logoController,
                  label: 'league_details.logo_url'.tr(),
                  icon: Icons.link,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('league_details.cancel'.tr(), style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            PremiumButton(
              text: 'league_details.save'.tr(),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final success = await context.read<TournamentProvider>().updateTournamentSeries(
                  id: detail.id,
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                  description: descController.text.trim(),
                  logoUrl: logoController.text.trim(),
                );
                
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('league_details.league_updated_success'.tr())),
                  );
                }
              },
            ),
          ],
        );
      },
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
