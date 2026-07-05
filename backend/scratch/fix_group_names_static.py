import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Declare static Map in State class members
    target_members = "class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {"
    replacement_members = """class _TournamentDetailsPageState extends State<TournamentDetailsPage> with SingleTickerProviderStateMixin {
  static final Map<String, String> _groupLettersMap = {};"""

    if target_members in content and "_groupLettersMap" not in content:
        content = content.replace(target_members, replacement_members)
        print("Static map member declared!")

    # 2. Populate _groupLettersMap and render dynamically in standings tab
    target_standings = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                }).toList(),"""

    replacement_standings = """          if (isGroupStage) {
            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            final sortedGroupKeys = groupedStandings.keys.toList()..sort((a, b) => (a ?? '').compareTo(b ?? ''));
            _groupLettersMap.clear();
            for (int i = 0; i < sortedGroupKeys.length; i++) {
              final key = sortedGroupKeys[i];
              if (key != null) {
                _groupLettersMap[key] = String.fromCharCode(65 + i);
              }
            }

            return Column(
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
                }).toList(),"""

    if target_standings in content:
        content = content.replace(target_standings, replacement_standings)
        print("Standings rendering updated with alphabet map!")
    else:
        print("Standings target not found!")

    # 3. Update _cleanGroupName helper to lookup static map first
    target_helper = """String _cleanGroupName(String? groupName, String? groupId) {"""
    replacement_helper = """String _cleanGroupName(String? groupName, String? groupId) {
  if (groupId != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupId)) {
    return _TournamentDetailsPageState._groupLettersMap[groupId]!;
  }
  if (groupName != null && _TournamentDetailsPageState._groupLettersMap.containsKey(groupName)) {
    return _TournamentDetailsPageState._groupLettersMap[groupName]!;
  }"""

    if target_helper in content and "_groupLettersMap.containsKey" not in content:
        content = content.replace(target_helper, replacement_helper)
        print("_cleanGroupName helper updated!")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done!")

if __name__ == '__main__':
    main()
