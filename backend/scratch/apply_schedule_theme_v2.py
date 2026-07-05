import os

def main():
    filepath = 'lib/features/tournaments/presentation/widgets/shareable_schedule_dialog.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Insert getters in state class
    target_class = """class _ShareableScheduleDialogState extends State<ShareableScheduleDialog> {
  late List<DateTime> _availableDates;
  DateTime? _selectedDate;
  bool _isSaving = false;
  final GlobalKey _repaintKey = GlobalKey();"""

    replacement_class = """class _ShareableScheduleDialogState extends State<ShareableScheduleDialog> {
  late List<DateTime> _availableDates;
  DateTime? _selectedDate;
  bool _isSaving = false;
  final GlobalKey _repaintKey = GlobalKey();

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _containerBg => _isDark ? const Color(0xFF0B1519) : Colors.white;
  Color get _itemBg => _isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.025);
  Color get _itemBorderColor => _isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.06);
  Color get _mainTextColor => _isDark ? Colors.white : Colors.black;
  Color get _secondaryTextColor => _isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7);
  Color get _mutedTextColor => _isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.35);
  Color get _dividerColor => _isDark ? Colors.white10 : Colors.black12;
  Color get _shadowColor => _isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

  Color get _dialogBg => _isDark ? const Color(0xFF122229) : Colors.white;
  Color get _dialogTextColor => _isDark ? Colors.white : Colors.black87;
  Color get _dialogBorder => _isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);"""

    if target_class in content and "_containerBg" not in content:
        content = content.replace(target_class, replacement_class)
        print("Getters inserted successfully!")

    # 2. Replacements inside build method
    # Dialog container
    content = content.replace("color: const Color(0xFF122229),", "color: _dialogBg,")
    content = content.replace("border: Border.all(color: Colors.white.withOpacity(0.08)),", "border: Border.all(color: _dialogBorder),")
    content = content.replace("style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),",
                              "style: TextStyle(color: _dialogTextColor, fontSize: 16, fontWeight: FontWeight.bold),")
    content = content.replace("icon: const Icon(Icons.close, color: Colors.white70),", "icon: Icon(Icons.close, color: _dialogTextColor.withValues(alpha: 0.7)),")
    content = content.replace("style: const TextStyle(color: Colors.white70, fontSize: 12),", "style: TextStyle(color: _dialogTextColor.withValues(alpha: 0.7), fontSize: 12),")
    content = content.replace("border: Border.all(color: Colors.white10),", "border: Border.all(color: _dialogBorder),")
    content = content.replace("style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),",
                              "style: TextStyle(color: _dialogTextColor, fontSize: 13, fontWeight: FontWeight.bold),")

    # Repaint Boundary container
    content = content.replace("color: const Color(0xFF0B1519),", "color: _containerBg,")
    content = content.replace("color: Colors.white.withOpacity(0.5),", "color: _secondaryTextColor.withValues(alpha: 0.5),")
    content = content.replace("color: Colors.white.withOpacity(0.05),", "color: _itemBg,")
    
    # We must be careful not to replace color: Colors.white where it shouldn't be, let's replace exact text style definitions
    content = content.replace("""                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),""", """                            style: TextStyle(
                              color: _mainTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),""")

    content = content.replace("const Divider(color: Colors.white10, height: 1),", "Divider(color: _dividerColor, height: 1),")
    content = content.replace("child: Text('tournament.no_matches_scheduled_day'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 12)),",
                              "child: Text('tournament.no_matches_scheduled_day'.tr(), style: TextStyle(color: _mutedTextColor, fontSize: 12)),")

    content = content.replace("color: Colors.white.withOpacity(0.3),", "color: _mutedTextColor,")

    # 3. Replacements inside helper methods (_buildMatchRow & _buildCompactMatchCard)
    # item container
    content = content.replace("color: Colors.white.withOpacity(0.02),", "color: _itemBg,")
    content = content.replace("border: Border.all(color: Colors.white.withOpacity(0.04)),", "border: Border.all(color: _itemBorderColor),")
    
    # icons
    content = content.replace("Icon(Icons.shield, size: 12, color: Colors.white.withOpacity(0.4)),", "Icon(Icons.shield, size: 12, color: _mutedTextColor),")
    content = content.replace("Icon(Icons.shield_outlined, size: 12, color: Colors.white.withOpacity(0.4)),", "Icon(Icons.shield_outlined, size: 12, color: _mutedTextColor),")
    
    # texts
    content = content.replace("color: match.homeTeamName == null ? Colors.white24 : Colors.white70,",
                              "color: match.homeTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,")
    content = content.replace("color: match.awayTeamName == null ? Colors.white24 : Colors.white70,",
                              "color: match.awayTeamName == null ? _mutedTextColor.withValues(alpha: 0.5) : _secondaryTextColor,")

    content = content.replace("style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 7, fontStyle: FontStyle.italic),",
                              "style: TextStyle(color: _mutedTextColor, fontSize: 7, fontStyle: FontStyle.italic),")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Done applying schedule theme v2!")

if __name__ == '__main__':
    main()
