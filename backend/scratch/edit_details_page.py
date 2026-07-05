import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update isKnockout in _buildMatchesTab
    target1 = """    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    final tournament = provider.selectedTournament;
    final isKnockout = tournament?.format == 'KNOCKOUT';"""

    replacement1 = """    final myTeamIds = context.read<TeamProvider>().myTeams.map((t) => t.id).toSet();
    final tournament = provider.selectedTournament;
    final isKnockout = tournament?.format == 'KNOCKOUT' || tournament?.format == 'GROUP_STAGE';"""

    if target1 in content:
        content = content.replace(target1, replacement1)
        print("isKnockout updated!")

    # 2. Update TournamentBracketWidget parameters in matches tab
    target2 = """        else if (isKnockout && _showBracketView)
          Expanded(
            child: TournamentBracketWidget(
              matches: matches,
              tournamentId: widget.tournamentId,
            ),
          )"""

    replacement2 = """        else if (isKnockout && _showBracketView)
          Expanded(
            child: TournamentBracketWidget(
              matches: matches.where((m) => m.groupId == null).toList(),
              tournamentId: widget.tournamentId,
            ),
          )"""

    if target2 in content:
        content = content.replace(target2, replacement2)
        print("Matches tab bracket filter updated!")

    # 3. Update standings tab group stages list view & bracket rendering
    target3 = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            return Column(
              children: groupedStandings.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': _cleanGroupName(entry.key, entry.key)}), Icons.grid_view),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: PremiumTheme.surfaceCard(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildStandingsHeader(),
                          const Divider(height: 1, thickness: 1),
                          ...entry.value.asMap().entries.map((item) {
                            return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            );
          }"""

    replacement3 = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                ...groupedStandings.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': _cleanGroupName(entry.key, entry.key)}), Icons.grid_view),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: PremiumTheme.surfaceCard(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildStandingsHeader(),
                            const Divider(height: 1, thickness: 1),
                            ...entry.value.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 16),
                _buildSectionTitle('tournament.playoff_bracket'.tr(), Icons.account_tree_outlined),
                const SizedBox(height: 12),
                SizedBox(
                  height: 440,
                  child: TournamentBracketWidget(
                    matches: provider.matches.where((m) => m.groupId == null).toList(),
                    tournamentId: widget.tournamentId,
                  ),
                ),
              ],
            );
          }"""

    if target3 in content:
        content = content.replace(target3, replacement3)
        print("Standings tab group stage bracket updated!")
    else:
        print("Target 3 not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done editing tournament_details_page.dart!")

if __name__ == '__main__':
    main()
