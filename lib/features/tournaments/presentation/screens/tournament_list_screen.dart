import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tournament_provider.dart';
import '../../../../features/academies/providers/academy_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_page.dart';
import 'tournament_series_details_screen.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament.dart';
import 'tournament_announcements_screen.dart';

class GroupedTournamentItem {
  final String? seriesId;
  final String? seriesName;
  final List<Tournament> tournaments;
  final Tournament? singleTournament;

  GroupedTournamentItem({
    this.seriesId,
    this.seriesName,
    required this.tournaments,
    this.singleTournament,
  });

  bool get isSeries => seriesId != null;

  String get id => isSeries ? seriesId! : singleTournament!.id;
  
  String get name {
    if (isSeries) return seriesName!;
    return singleTournament!.name;
  }

  String? get logoUrl => isSeries
      ? tournaments.firstWhere((t) => t.logoUrl != null && t.logoUrl!.isNotEmpty, orElse: () => tournaments.first).logoUrl
      : singleTournament!.logoUrl;

  String get location => isSeries ? tournaments.first.location : singleTournament!.location;

  String get displayStatus {
    if (isSeries) {
      if (tournaments.any((t) => t.displayStatus == 'ACTIVE')) return 'ACTIVE';
      if (tournaments.any((t) => t.displayStatus == 'UPCOMING' || t.displayStatus == 'REGISTRATION')) return 'UPCOMING';
      return 'FINISHED';
    }
    return singleTournament!.displayStatus;
  }

  String get dateRange {
    if (isSeries) {
      if (tournaments.isEmpty) return '';
      final sorted = List<Tournament>.from(tournaments);
      sorted.sort((a, b) => a.startDate.compareTo(b.startDate));
      final start = sorted.first.startDate;
      final end = sorted.last.endDate;
      return '$start — $end';
    }
    return '${singleTournament!.startDate} — ${singleTournament!.endDate}';
  }

  String get format => isSeries ? tournaments.first.format : singleTournament!.format;
  String get ageCategory => isSeries ? '${tournaments.length} возр.' : singleTournament!.ageCategory;
}

class TournamentListScreen extends StatefulWidget {
  final int initialIndex;
  const TournamentListScreen({super.key, this.initialIndex = 0});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCity;
  int? _selectedYear;
  bool _showAdults = true;

  final List<String> _kazakhstanCities = [
    'All Cities', 'Astana', 'Almaty', 'Shymkent', 'Karaganda', 'Aktobe', 'Taraz', 'Pavlodar', 'Semey'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
        _refresh();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && user.roles?.contains('PARENT') == true) {
        setState(() {
          _showAdults = false;
        });
      }
      _refresh();
      context.read<AcademyProvider>().fetchMyAcademy();
    });
  }

  void _refresh() {
    final user = context.read<AuthProvider>().user;
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    if (_tabController.index == 2) {
      context.read<TournamentProvider>().fetchTournamentSeries();
    } else if (_tabController.index == 3) {
      context.read<TournamentProvider>().fetchTournaments();
    } else {
      context.read<TournamentProvider>().fetchTournaments(
        city: _selectedCity == 'All Cities' ? null : _selectedCity,
        year: _selectedYear,
        mine: isChild ? true : (_tabController.index == 1),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isAdultTournament(Tournament tournament) {
    final category = tournament.ageCategory.trim().toUpperCase();
    if (category == 'ADULT' || category == 'OPEN' || category == 'MEN' || category == 'WOMEN') {
      return true;
    }
    
    // Check if category contains any 4-digit youth birth years (e.g. 2016-2017)
    final matches = RegExp(r'\b\d{4}\b').allMatches(category);
    if (matches.isNotEmpty) {
      for (final m in matches) {
        final year = int.tryParse(m.group(0) ?? '');
        if (year != null && year >= 2000 && year <= 2030) {
          return false; // Youth birth year
        }
      }
    }
    
    // Check if category starts with U or Y followed by digits (e.g. U13, Y2013, U-13, U 13)
    if (RegExp(r'^[UY]\d+').hasMatch(category) || RegExp(r'\b[UY][- ]?\d+').hasMatch(category)) {
      return false;
    }
    
    return true; // Default to adult
  }

  List<GroupedTournamentItem> _groupTournaments(List<Tournament> list) {
    final List<GroupedTournamentItem> grouped = [];
    final Map<String, List<Tournament>> seriesMap = {};
    final List<String> seenOrder = [];
    
    for (final t in list) {
      if (t.seriesId != null && t.seriesId!.isNotEmpty) {
        if (!seriesMap.containsKey(t.seriesId!)) {
          seenOrder.add('series:${t.seriesId}');
        }
        seriesMap.putIfAbsent(t.seriesId!, () => []).add(t);
      } else {
        seenOrder.add('tourney:${t.id}');
        seriesMap[t.id] = [t];
      }
    }
    
    for (final key in seenOrder) {
      if (key.startsWith('series:')) {
        final seriesId = key.substring(7);
        final listInSeries = seriesMap[seriesId];
        if (listInSeries != null && listInSeries.isNotEmpty) {
          grouped.add(GroupedTournamentItem(
            seriesId: seriesId,
            seriesName: listInSeries.first.seriesName ?? listInSeries.first.name,
            tournaments: listInSeries,
          ));
          seriesMap.remove(seriesId);
        }
      } else {
        final tourneyId = key.substring(8);
        final listInSeries = seriesMap[tourneyId];
        if (listInSeries != null && listInSeries.isNotEmpty) {
          grouped.add(GroupedTournamentItem(
            tournaments: listInSeries,
            singleTournament: listInSeries.first,
          ));
          seriesMap.remove(tourneyId);
        }
      }
    }
    
    return grouped;
  }

  Widget _buildAgeToggle() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_showAdults) {
                  setState(() => _showAdults = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showAdults ? PremiumTheme.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_people_rounded,
                      size: 16,
                      color: _showAdults ? Colors.black : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ВЗРОСЛЫЕ'.tr(),
                      style: GoogleFonts.outfit(
                        color: _showAdults ? Colors.black : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_showAdults) {
                  setState(() => _showAdults = false);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showAdults ? PremiumTheme.neonGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.child_care_rounded,
                      size: 16,
                      color: !_showAdults ? Colors.black : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ДЕТСКИЕ'.tr(),
                      style: GoogleFonts.outfit(
                        color: !_showAdults ? Colors.black : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthProvider>().user;
    final canCreate = user != null && (
      user.roles?.contains('TOURNAMENT_ORGANIZER') == true ||
      user.roles?.contains('ADMIN') == true
    );
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isChild ? '⭐ ${'tournament.my_championships'.tr()}' : 'tournament.tournaments'.tr(),
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        bottom: isChild ? null : TabBar(
          controller: _tabController,
          indicatorColor: PremiumTheme.neonGreen,
          labelColor: PremiumTheme.neonGreen,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          tabs: [
            Tab(text: 'tournament.explore'.tr()),
            Tab(text: 'tournament.my_events'.tr()),
            Tab(text: 'Лиги (Эгиды)'),
            Tab(text: 'tournament.announcements_title'.tr()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      floatingActionButton: canCreate ? FloatingActionButton(
        backgroundColor: PremiumTheme.neonGreen,
        onPressed: () {
          if (_tabController.index == 2) {
            _showCreateSeriesDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateTournamentScreen()),
            ).then((_) => _refresh());
          }
        },
        child: const Icon(Icons.add, color: Colors.black),
      ) : null,
      body: Column(
        children: [
          if (isChild) ...[
            _buildChildGreeting(user.name),
            const SizedBox(height: 10),
          ],
          if (!isChild && _tabController.index < 2) ...[
            _buildFilterBar(),
            _buildAgeToggle(),
          ],
          Expanded(
            child: Consumer<TournamentProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
                }
                if (provider.error != null) {
                  return _buildErrorState(provider.error!);
                }

                if (_tabController.index == 2) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return _buildSeriesTab(provider, cs, isDark);
                }

                if (_tabController.index == 3) {
                  return const TournamentAnnouncementsScreen(embedded: true);
                }

                final tournaments = isChild
                    ? provider.tournaments
                    : provider.tournaments.where((t) => _showAdults ? _isAdultTournament(t) : !_isAdultTournament(t)).toList();

                final groupedItems = _groupTournaments(tournaments);

                if (groupedItems.isEmpty) {
                  return _buildEmptyState();
                }

                final activeGrouped = groupedItems.where((g) => g.displayStatus == 'ACTIVE').toList();
                final upcomingGrouped = groupedItems.where((g) => g.displayStatus != 'ACTIVE' && g.displayStatus != 'FINISHED').toList();
                final finishedGrouped = groupedItems.where((g) => g.displayStatus == 'FINISHED').toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  children: [
                    if (activeGrouped.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_active'.tr()),
                      ...activeGrouped.map((item) => _buildTournamentCard(item, isChild)),
                    ],
                    if (upcomingGrouped.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_upcoming'.tr()),
                      ...upcomingGrouped.map((item) => _buildTournamentCard(item, isChild)),
                    ],
                    if (finishedGrouped.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_finished'.tr()),
                      ...finishedGrouped.map((item) => _buildTournamentCard(item, isChild)),
                    ],
                    const SizedBox(height: 180),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kazakhstanCities.length,
        itemBuilder: (context, index) {
          final city = _kazakhstanCities[index];
          final isSelected = (_selectedCity ?? 'All Cities') == city;
          final displayCity = index == 0 ? 'tournament.all_cities'.tr() : city;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCity = city == 'All Cities' ? null : city);
                _refresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [PremiumTheme.neonGreen, Color(0xFF00C853)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : PremiumTheme.surfaceCard(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : cs.onSurface.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: PremiumTheme.neonGreen.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_circle, color: Colors.black, size: 14),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      displayCity,
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.black : cs.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          color: cs.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTournamentCard(GroupedTournamentItem item, bool isChild) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isActive = item.displayStatus == 'ACTIVE';
    final isFinished = item.displayStatus == 'FINISHED';

    final statusColor = isActive
        ? const Color(0xFF00E676)
        : (isFinished
            ? cs.onSurfaceVariant.withValues(alpha: 0.7)
            : const Color(0xFF2979FF));

    final cardBg = PremiumTheme.surfaceCard(context);

    final statusText = isActive
        ? 'В ЭФИРЕ'
        : (isFinished
            ? 'ЗАВЕРШЕН'
            : 'СКОРО');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          if (item.isSeries) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TournamentSeriesDetailsScreen(seriesId: item.seriesId!)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TournamentDetailsPage(tournamentId: item.singleTournament!.id)),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? PremiumTheme.neonGreen.withValues(alpha: 0.3)
                  : cs.onSurface.withValues(alpha: 0.06),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                if (isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PremiumTheme.neonGreen.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo / Trophy Container
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive
                                    ? [PremiumTheme.neonGreen.withValues(alpha: 0.2), PremiumTheme.neonGreen.withValues(alpha: 0.05)]
                                    : [cs.onSurface.withValues(alpha: 0.05), cs.onSurface.withValues(alpha: 0.01)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive
                                    ? PremiumTheme.neonGreen.withValues(alpha: 0.3)
                                    : cs.onSurface.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: item.logoUrl != null && item.logoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(17),
                                    child: Image.network(item.logoUrl!, fit: BoxFit.cover),
                                  )
                                : Icon(
                                    item.isSeries
                                        ? Icons.shield_rounded
                                        : (isChild ? Icons.star_rounded : Icons.emoji_events_rounded),
                                    color: isActive ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
                                    size: 26,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.isSeries)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: PremiumTheme.electricBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: PremiumTheme.electricBlue.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.shield, color: PremiumTheme.electricBlue, size: 10),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ЛИГА / ЭГИДА',
                                            style: GoogleFonts.outfit(
                                              color: PremiumTheme.electricBlue,
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Text(
                                  item.name,
                                  style: GoogleFonts.outfit(
                                    color: cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.location,
                                      style: GoogleFonts.outfit(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.outfit(
                                color: isActive ? PremiumTheme.neonGreen : statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Info Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.04)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _buildInfoCell(Icons.calendar_today_rounded, item.isSeries ? 'Серия' : item.dateRange.split(' — ').first),
                                const SizedBox(width: 8),
                                _buildInfoCell(Icons.sports_soccer_rounded, item.format),
                                const SizedBox(width: 8),
                                _buildInfoCell(Icons.groups_rounded, item.ageCategory),
                              ],
                            ),
                          ),
                          Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Text(
                                 'ПОДРОБНЕЕ',
                                 style: GoogleFonts.outfit(
                                   color: isActive ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
                                   fontSize: 10,
                                   fontWeight: FontWeight.w800,
                                   letterSpacing: 0.8,
                                 ),
                               ),
                               const SizedBox(width: 4),
                               Icon(Icons.arrow_forward_ios_rounded, size: 10, color: isActive ? PremiumTheme.neonGreen : cs.onSurfaceVariant),
                             ],
                           ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCell(IconData icon, String value) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                color: cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final user = context.read<AuthProvider>().user;
    final isChild = user != null && (
      user.roles?.contains('PLAYER_CHILD') == true ||
      user.roles?.contains('PLAYER_YOUTH') == true
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isChild ? Icons.star_rounded : Icons.emoji_events_outlined,
            size: 80,
            color: isChild ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 16),
          Text(
            isChild ? 'tournament.no_games_scheduled'.tr() : 'tournament.no_tournaments'.tr(),
            style: TextStyle(color: cs.onSurfaceVariant, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isChild ? 'tournament.ask_coach'.tr() : 'tournament.be_first'.tr(),
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChildGreeting(String name) {
    final cs = Theme.of(context).colorScheme;
    final academy = context.watch<AcademyProvider>().myAcademy;
    final academyName = academy?.name ?? 'ORLEON';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumTheme.neonGreen.withValues(alpha: 0.15),
            PremiumTheme.electricBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: PremiumTheme.neonGreen.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'academy.hello_champion'.tr(namedArgs: {'name': name}),
                  style: GoogleFonts.outfit(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  'academy.representing'.tr(namedArgs: {'name': academyName.toUpperCase()}),
                  style: GoogleFonts.outfit(color: PremiumTheme.neonGreen, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  'academy.ready_for_match'.tr(),
                  style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: PremiumTheme.danger),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            PremiumButton(
              text: 'common.retry'.tr(),
              onPressed: () => context.read<TournamentProvider>().fetchTournaments(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesTab(TournamentProvider provider, ColorScheme cs, bool isDark) {
    if (provider.seriesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: cs.onSurfaceVariant, size: 64),
            const SizedBox(height: 16),
            Text(
              'Нет созданных лиг под эгидой',
              style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      itemCount: provider.seriesList.length,
      itemBuilder: (context, index) {
        final series = provider.seriesList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: PremiumTheme.surfaceCard(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TournamentSeriesDetailsScreen(seriesId: series.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [cs.onSurface.withValues(alpha: 0.05), cs.onSurface.withValues(alpha: 0.01)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: cs.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: series.logoUrl != null && series.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(series.logoUrl!, fit: BoxFit.cover),
                                )
                              : const Icon(Icons.emoji_events_rounded, color: PremiumTheme.neonGreen, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                series.name,
                                style: GoogleFonts.outfit(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.7), size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    series.city,
                                    style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: cs.onSurfaceVariant, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreateSeriesDialog(BuildContext context) {
    final nameController = TextEditingController();
    final cityController = TextEditingController(text: 'Astana');
    final descController = TextEditingController();
    final logoController = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: PremiumTheme.surfaceCard(context),
          title: Text(
            'СОЗДАТЬ ЛИГУ (ЭГИДУ)',
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumTextField(
                  controller: nameController,
                  label: 'Название Лиги/Серии',
                  icon: Icons.emoji_events,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: cityController,
                  label: 'Город',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: descController,
                  label: 'Описание лиги',
                  icon: Icons.description,
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: logoController,
                  label: 'Ссылка на Логотип (URL)',
                  icon: Icons.link,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Отмена', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            PremiumButton(
              text: 'Создать',
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                final user = context.read<AuthProvider>().user;
                if (user == null) return;
                
                final success = await context.read<TournamentProvider>().createTournamentSeries(
                  name: nameController.text.trim(),
                  city: cityController.text.trim(),
                  description: descController.text.trim(),
                  logoUrl: logoController.text.trim(),
                  organizerId: user.id,
                );
                
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Лига успешно создана!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
