import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define the theme block right after final sortedFields = ...
    target_block_start = """    final sortedFields = fieldGroups.keys.toList()..sort();

    final screenHeight = MediaQuery.of(context).size.height;"""

    replacement_block_start = """    final sortedFields = fieldGroups.keys.toList()..sort();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF122229) : Colors.white;
    final dialogTextColor = isDark ? Colors.white : Colors.black87;
    final dialogBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

    final containerBg = isDark ? const Color(0xFF0B1519) : Colors.white;
    final itemBg = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.025);
    final itemBorderColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.06);
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.7);
    final mutedTextColor = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.35);
    final dividerColor = isDark ? Colors.white10 : Colors.black12;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);

    final screenHeight = MediaQuery.of(context).size.height;"""

    if target_block_start in content and "containerBg" not in content:
        content = content.replace(target_block_start, replacement_block_start)
        print("Theme block definition inserted!")

    # Replace Dialog properties:
    content = content.replace("color: const Color(0xFF122229),", "color: dialogBg,")
    content = content.replace("border: Border.all(color: Colors.white.withOpacity(0.08)),", "border: Border.all(color: dialogBorder),")
    content = content.replace("style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),",
                              "style: TextStyle(color: dialogTextColor, fontSize: 16, fontWeight: FontWeight.bold),")
    content = content.replace("icon: const Icon(Icons.close, color: Colors.white70),", "icon: Icon(Icons.close, color: dialogTextColor.withOpacity(0.7)),")
    content = content.replace("style: const TextStyle(color: Colors.white70, fontSize: 12),", "style: TextStyle(color: dialogTextColor.withOpacity(0.7), fontSize: 12),")
    content = content.replace("border: Border.all(color: Colors.white10),", "border: Border.all(color: dialogBorder),")
    content = content.replace("style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),",
                              "style: TextStyle(color: dialogTextColor, fontSize: 13, fontWeight: FontWeight.bold),")

    # Replace RepaintBoundary Container properties:
    content = content.replace("color: const Color(0xFF0B1519),", "color: containerBg,")
    content = content.replace("color: Colors.white.withOpacity(0.5),", "color: secondaryTextColor.withOpacity(0.5),")
    content = content.replace("color: Colors.white.withOpacity(0.05),", "color: itemBg,")
    content = content.replace("color: Colors.white,", "color: mainTextColor,")
    content = content.replace("color: Colors.white54, fontSize: 12", "color: mutedTextColor, fontSize: 12")
    content = content.replace("const Divider(color: Colors.white10, height: 1),", "Divider(color: dividerColor, height: 1),")
    content = content.replace("color: Colors.white.withOpacity(0.3),", "color: mutedTextColor,")

    # Replace _buildMatchRow properties:
    content = content.replace("color: Colors.white.withOpacity(0.02),", "color: itemBg,")
    content = content.replace("border: Border.all(color: Colors.white.withOpacity(0.04)),", "border: Border.all(color: itemBorderColor),")
    content = content.replace("color: Colors.white.withOpacity(0.4)", "color: mutedTextColor")
    content = content.replace("color: match.homeTeamName == null ? Colors.white24 : Colors.white70,",
                              "color: match.homeTeamName == null ? mutedTextColor.withOpacity(0.5) : secondaryTextColor,")
    content = content.replace("color: match.awayTeamName == null ? Colors.white24 : Colors.white70,",
                              "color: match.awayTeamName == null ? mutedTextColor.withOpacity(0.5) : secondaryTextColor,")

    # Replace _buildCompactMatchCard properties:
    content = content.replace("style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 7, fontStyle: FontStyle.italic),",
                              "style: TextStyle(color: mutedTextColor, fontSize: 7, fontStyle: FontStyle.italic),")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done applying schedule theme!")

if __name__ == '__main__':
    main()
