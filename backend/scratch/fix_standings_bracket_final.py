import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update standings tab to include both cleaned group names and playoff bracket widget
    target_standings = """            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sortedGroupKeys.asMap().entries.map((entry) {
                  final groupKey = entry.value;
                  final groupLetter = _groupLettersMap[groupKey] ?? 'A';
                  final standingsList = groupedStandings[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': groupLetter}), Icons.grid_view),
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
                            ...standingsList.asMap().entries.map((item) {
                              return _buildStandingsRow(item.key + 1, item.value, canSwap: _isOrganizer && provider.matches.any((m) => m.status == 'DRAFT'));
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              ],
            );"""

    replacement_standings = """            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...sortedGroupKeys.asMap().entries.map((entry) {
                  final groupKey = entry.value;
                  final groupLetter = _groupLettersMap[groupKey] ?? 'A';
                  final standingsList = groupedStandings[groupKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': groupLetter}), Icons.grid_view),
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
                            ...standingsList.asMap().entries.map((item) {
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
            );"""

    if target_standings in content:
        content = content.replace(target_standings, replacement_standings)
        print("Standings bracket fixed!")
    else:
        print("Standings bracket target not found!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
