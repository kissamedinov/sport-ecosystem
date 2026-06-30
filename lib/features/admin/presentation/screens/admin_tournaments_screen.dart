import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../tournaments/providers/tournament_provider.dart';
import '../../../tournaments/data/models/tournament.dart';
import '../../../tournaments/presentation/screens/create_tournament_screen.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class AdminTournamentsScreen extends StatefulWidget {
  const AdminTournamentsScreen({super.key});

  @override
  State<AdminTournamentsScreen> createState() => _AdminTournamentsScreenState();
}

class _AdminTournamentsScreenState extends State<AdminTournamentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TournamentProvider>().fetchTournaments());
  }

  TextStyle _t(double size, FontWeight w, Color color) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('admin.tournament_moderation'.tr(), style: _t(18, FontWeight.w600, onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<TournamentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.tournaments.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.tournaments.isEmpty) {
            return Center(
              child: Text(
                'tournament.no_tournaments'.tr(),
                style: _t(14, FontWeight.w400, onSurface.withValues(alpha: 0.5)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchTournaments(),
            color: PremiumTheme.neonGreen,
            child: ListView.builder(
              itemCount: provider.tournaments.length,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemBuilder: (context, index) {
                final tournament = provider.tournaments[index];
                return PremiumCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (tournament.logoUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  tournament.logoUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildLogoPlaceholder(cs),
                                ),
                              )
                            else
                              _buildLogoPlaceholder(cs),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tournament.name,
                                    style: _t(16, FontWeight.w700, onSurface),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${tournament.location} • ${tournament.format}',
                                    style: _t(12, FontWeight.w500, onSurface.withValues(alpha: 0.45)),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusChip(tournament.displayStatus),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 14, color: onSurface.withValues(alpha: 0.35)),
                            const SizedBox(width: 6),
                            Text(
                              '${tournament.startDate} - ${tournament.endDate}',
                              style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Edit Button
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateTournamentScreen(initialTournament: tournament),
                                  ),
                                ).then((_) => provider.fetchTournaments());
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                              label: Text('common.edit'.tr(), style: _t(12, FontWeight.w600, Colors.blue)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Quick Status Actions
                            PopupMenuButton<String>(
                              onSelected: (status) async {
                                final success = await provider.updateTournament(
                                  tournament.id,
                                  {'status': status},
                                );
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Status updated to $status')),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'upcoming', child: Text('Upcoming')),
                                const PopupMenuItem(value: 'active', child: Text('Active')),
                                const PopupMenuItem(value: 'finished', child: Text('Finished')),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: onSurface.withValues(alpha: 0.08)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Text('Status', style: _t(12, FontWeight.w600, onSurface)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, size: 16, color: onSurface),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoPlaceholder(ColorScheme cs) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.emoji_events_outlined, color: cs.onSurface.withValues(alpha: 0.25), size: 24),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bg = PremiumTheme.neonGreen.withValues(alpha: 0.12);
        text = PremiumTheme.neonGreen;
        break;
      case 'FINISHED':
        bg = Colors.grey.withValues(alpha: 0.12);
        text = Colors.grey;
        break;
      default:
        bg = Colors.blue.withValues(alpha: 0.12);
        text = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
