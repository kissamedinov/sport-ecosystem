import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../../../features/academies/providers/academy_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'create_tournament_screen.dart';
import 'tournament_details_page.dart';
import 'tournament_series_details_screen.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../data/models/tournament.dart';

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
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
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
    
    // Check if category is a 4-digit number (e.g. 2013)
    final isYear = RegExp(r'^\d{4}$').hasMatch(category);
    if (isYear) {
      final year = int.tryParse(category);
      if (year != null && year >= 2000 && year <= 2030) {
        return false; // Youth birth year
      }
    }
    
    // Check if category starts with U or Y followed by digits (e.g. U13, Y2013, U-13, U 13)
    if (RegExp(r'^[UY]\d+').hasMatch(category) || RegExp(r'\b[UY][- ]?\d+').hasMatch(category)) {
      return false;
    }
    
    return true; // Default to adult
  }

  Widget _buildAgeToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          _buildAgeChip('ADULT', _showAdults, () {
            if (!_showAdults) {
              setState(() => _showAdults = true);
            }
          }),
          const SizedBox(width: 8),
          _buildAgeChip('YOUTH', !_showAdults, () {
            if (_showAdults) {
              setState(() => _showAdults = false);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildAgeChip(String label, bool isSelected, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: PremiumTheme.surfaceCard(context),
      selectedColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent),
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

                final tournaments = isChild
                    ? provider.tournaments
                    : provider.tournaments.where((t) => _showAdults ? _isAdultTournament(t) : !_isAdultTournament(t)).toList();

                if (tournaments.isEmpty) {
                  return _buildEmptyState();
                }

                final activeTournaments = tournaments.where((t) => t.displayStatus == 'ACTIVE').toList();
                final upcomingTournaments = tournaments.where((t) => t.displayStatus != 'ACTIVE' && t.displayStatus != 'FINISHED').toList();
                final finishedTournaments = tournaments.where((t) => t.displayStatus == 'FINISHED').toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  children: [
                    if (activeTournaments.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_active'.tr()),
                      ...activeTournaments.map((t) => _buildTournamentCard(t, isChild)),
                    ],
                    if (upcomingTournaments.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_upcoming'.tr()),
                      ...upcomingTournaments.map((t) => _buildTournamentCard(t, isChild)),
                    ],
                    if (finishedTournaments.isNotEmpty) ...[
                      _buildSectionTitle('tournament.status_finished'.tr()),
                      ...finishedTournaments.map((t) => _buildTournamentCard(t, isChild)),
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
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kazakhstanCities.length,
        itemBuilder: (context, index) {
          final city = _kazakhstanCities[index];
          final isSelected = (_selectedCity ?? 'All Cities') == city;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(index == 0 ? 'tournament.all_cities'.tr() : city),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCity = val ? city : null);
                _refresh();
              },
              backgroundColor: PremiumTheme.surfaceCard(context),
              selectedColor: PremiumTheme.neonGreen.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? PremiumTheme.neonGreen : cs.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: PremiumTheme.neonGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent),
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
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTournamentCard(dynamic tournament, bool isChild) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = tournament.displayStatus == 'ACTIVE'
        ? const Color(0xFF00E676)
        : (tournament.displayStatus == 'FINISHED'
            ? cs.onSurfaceVariant
            : const Color(0xFF42A5F5));

    final cardBg = isDark
        ? (tournament.displayStatus == 'ACTIVE'
            ? const Color(0xFF0A1F0A)
            : (tournament.displayStatus == 'FINISHED'
                ? const Color(0xFF111418)
                : const Color(0xFF0D1B2A)))
        : PremiumTheme.surfaceCard(context);

    final borderColor = isDark
        ? (tournament.displayStatus == 'ACTIVE'
            ? const Color(0xFF1B5E20)
            : (tournament.displayStatus == 'FINISHED'
                ? const Color(0xFF2A2F36)
                : const Color(0xFF1E3A5F)))
        : statusColor.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TournamentDetailsPage(tournamentId: tournament.id)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                      ),
                      child: tournament.logoUrl != null && tournament.logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(tournament.logoUrl!, fit: BoxFit.cover),
                            )
                          : Icon(
                              isChild ? Icons.star_rounded : Icons.emoji_events_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.name.toUpperCase(),
                            style: TextStyle(color: cs.onSurface, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5, height: 1.2),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 11, color: cs.onSurfaceVariant),
                              const SizedBox(width: 3),
                              Text(
                                tournament.location,
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tournament.displayStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.calendar_today_rounded, tournament.startDate, statusColor),
                    _buildInfoChip(Icons.sports_soccer_rounded, tournament.format, statusColor),
                    _buildInfoChip(Icons.groups_rounded, tournament.ageCategory, statusColor),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'tournament.details'.tr(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 9, color: statusColor),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumTheme.neonGreen.withValues(alpha: 0.15),
            PremiumTheme.electricBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'academy.hello_champion'.tr(namedArgs: {'name': name}),
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
                Text(
                  'academy.representing'.tr(namedArgs: {'name': academyName.toUpperCase()}),
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 2),
                Text(
                  'academy.ready_for_match'.tr(),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
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
            Icon(Icons.emoji_events_outlined, color: cs.onSurfaceVariant, size: 48),
            const SizedBox(height: 16),
            Text(
              'Нет созданных лиг под эгидой',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
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
          child: PremiumCard(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentSeriesDetailsScreen(seriesId: series.id),
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
                  child: series.logoUrl != null && series.logoUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(series.logoUrl!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.emoji_events, color: PremiumTheme.neonGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.name,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: cs.onSurfaceVariant, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            series.city,
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
              ],
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
