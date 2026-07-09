import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/tournament_provider.dart';
import '../../data/models/tournament_team_response.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class TournamentRegistrationHubScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentRegistrationHubScreen({super.key, required this.tournamentId});

  @override
  State<TournamentRegistrationHubScreen> createState() => _TournamentRegistrationHubScreenState();
}

class _TournamentRegistrationHubScreenState extends State<TournamentRegistrationHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TournamentProvider>().fetchTournamentTeams(widget.tournamentId);
      context.read<TournamentProvider>().fetchTournamentDetails(widget.tournamentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<TournamentProvider>();
    final registrations = provider.registeredTeams;
    final divisions = provider.divisions;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Заявки на участие',
          style: GoogleFonts.outfit(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: isLoading && registrations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen))
          : registrations.isEmpty
              ? Center(
                  child: Text(
                    'Заявок пока нет',
                    style: GoogleFonts.outfit(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: divisions.isEmpty ? 1 : divisions.length,
                  itemBuilder: (context, divIndex) {
                    final div = divisions.isNotEmpty ? divisions[divIndex] : <String, dynamic>{};
                    final divId = div['id'];
                    final divName = div['name'] ?? 'Общая категория';

                    final divRegs = registrations.where((r) => divId == null || r.divisionId == divId).toList();
                    if (divRegs.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: PremiumTheme.neonGreen,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                divName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurfaceVariant,
                                  letterSpacing: 1,
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
                                  '${divRegs.length}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...divRegs.map((reg) => _buildRegistrationCard(reg, provider, cs)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildRegistrationCard(TournamentTeamResponse reg, TournamentProvider provider, ColorScheme cs) {
    final status = reg.status;
    Color statusColor = cs.onSurfaceVariant;
    String statusLabel = 'В ожидании';

    if (status == 'APPROVED') {
      statusColor = PremiumTheme.neonGreen;
      statusLabel = 'Одобрено';
    } else if (status == 'REJECTED') {
      statusColor = PremiumTheme.danger;
      statusLabel = 'Отклонено';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.shield, color: PremiumTheme.neonGreen, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reg.team.name,
                        style: GoogleFonts.outfit(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reg.team.academyName ?? 'Свободный клуб',
                        style: GoogleFonts.outfit(
                          color: cs.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            if (status == 'PENDING') ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'REJECTED');
                      if (mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ошибка при отклонении заявки')),
                        );
                      }
                    },
                    child: Text(
                      'Отклонить',
                      style: GoogleFonts.outfit(
                        color: PremiumTheme.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await provider.updateTeamStatus(widget.tournamentId, reg.teamId, 'APPROVED');
                      if (mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ошибка при одобрении заявки')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(80, 36),
                    ),
                    child: Text(
                      'Одобрить',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
