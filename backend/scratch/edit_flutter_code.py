import os

def main():
    filepath = 'lib/features/tournaments/presentation/screens/tournament_details_page.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Edit 1: Append bottom helper
    target1 = """            ),
          ),
        ],
      ),
    );
  }
}"""
    replacement1 = """            ),
          ),
        ],
      ),
    );
  }
}

String _cleanGroupName(String? groupName, String? groupId) {
  final name = groupName ?? groupId;
  if (name == null) return "A";
  final upper = name.toUpperCase();
  if (upper.startsWith("GROUP") || upper.startsWith("ГРУППА")) {
    final parts = name.split(" ");
    if (parts.length > 1) {
      final letter = parts.last.toUpperCase();
      if (letter == "A" || letter == "А") return "A";
      if (letter == "B" || letter == "Б") return "B";
      return letter;
    }
  }
  if (name.length > 8) {
    return name.split("-").last.toUpperCase();
  }
  return name.toUpperCase();
}"""
    if target1 in content:
        content = content.replace(target1, replacement1)
        print("Edit 1 applied!")
    else:
        print("Edit 1 target not found!")
        
    # Edit 2: Swap team dialog subtitle
    target2 = "subtitle: Text('tournament.current_group'.tr(namedArgs: {'group': team.groupId?.toString().split(\"-\").last.toUpperCase() ?? \"A\"}), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),"
    replacement2 = "subtitle: Text('tournament.current_group'.tr(namedArgs: {'group': _cleanGroupName(team.groupName, team.groupId)}), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4), fontSize: 11)),"
    if target2 in content:
        content = content.replace(target2, replacement2)
        print("Edit 2 applied!")
    else:
        print("Edit 2 target not found!")
        
    # Edit 3: Standings table group headers
    target3 = """            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              groupedStandings.putIfAbsent(s.groupId, () => []).add(s);
            }

            return Column(
              children: groupedStandings.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': entry.key?.toString().split("-").last.toUpperCase() ?? "A"}), Icons.grid_view),"""
    
    replacement3 = """            final groupedStandings = <String?, List<TournamentStanding>>{};
            for (var s in filteredStandings) {
              final key = s.groupName ?? s.groupId;
              groupedStandings.putIfAbsent(key, () => []).add(s);
            }

            return Column(
              children: groupedStandings.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('tournament.group_prefix'.tr(namedArgs: {'group': _cleanGroupName(entry.key, entry.key)}), Icons.grid_view),"""
                    
    if target3 in content:
        content = content.replace(target3, replacement3)
        print("Edit 3 applied!")
    else:
        print("Edit 3 target not found!")
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Done!")

if __name__ == '__main__':
    main()
