import re

filepath = r"c:\Users\Asus\Desktop\test\mobile\lib\features\matches\presentation\screens\match_details_screen.dart"

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# We want to replace everything from "Widget _buildSelectedTabContent" (or similar) down to the end of the file
# and also update the build method to get isDark and onSurface and pass them.

# Let's inspect the file content around the build method:
# We will do a replacement of the build method body and all the helper methods.
# To make it super robust, we can just replace everything after:
# "return Scaffold(" with our new build body and helper methods!

target_pattern = r'''    return Scaffold\(
      backgroundColor: PremiumTheme\.surfaceBase\(context\),
      appBar: AppBar\(
        backgroundColor: Colors\.transparent,
        elevation: 0,
        title: Text\('match\.match_center'\.tr\(\), style: const TextStyle\(fontWeight: FontWeight\.w900, letterSpacing: 2, fontSize: 14\)\),
        centerTitle: true,
        actions: \[
          if \(isCoach\)
            IconButton\(
              icon: const Icon\(Icons\.restart_alt, color: Colors\.redAccent\),
              tooltip: 'Сбросить результат',
              onPressed: \(\) async \{
                final confirm = await showDialog<bool>\(
                  context: context,
                  builder: \(context\) => AlertDialog\(
                    backgroundColor: PremiumTheme\.surfaceCard\(context\),
                    title: const Text\('Сброс результата матча', style: TextStyle\(fontWeight: FontWeight\.bold\)\),
                    content: const Text\('Вы действительно хотите отменить счет и сбросить сыгранный матч\? Статистика команд обнулится\.'\),
                    actions: \[
                      TextButton\(
                        onPressed: \(\) => Navigator\.pop\(context, false\),
                        child: Text\('Отмена', style: TextStyle\(color: Theme\.of\(context\)\.colorScheme\.onSurface\.withOpacity\(0\.5\)\)\),
                      \),
                      TextButton\(
                        onPressed: \(\) => Navigator\.pop\(context, true\),
                        child: const Text\('Сбросить', style: TextStyle\(color: Colors\.redAccent, fontWeight: FontWeight\.bold\)\),
                      \),
                    \],
                  \),
                \);
                if \(confirm == true\) \{
                  final matchProvider = context\.read<MatchProvider>\(\);
                  final success = await matchProvider\.resetResult\(widget\.match\.id\);
                  if \(success && mounted\) \{
                    ScaffoldMessenger\.of\(context\)\.showSnackBar\(
                      const SnackBar\(content: Text\('Результат матча успешно сброшен'\), backgroundColor: Colors\.green\),
                    \);
                    context\.read<TournamentProvider>\(\)\.fetchTournamentDetails\(widget\.match\.tournamentId \?\? ''\);
                    Navigator\.pop\(context\);
                  \} else if \(mounted\) \{
                    ScaffoldMessenger\.of\(context\)\.showSnackBar\(
                      SnackBar\(content: Text\(matchProvider\.error \?\? 'Ошибка при сбросе результата'\), backgroundColor: Colors\.redAccent\),
                    \);
                  \}
                \}
              \},
            \),
        \],
      \),
      body: SingleChildScrollView\(
        physics: const BouncingScrollPhysics\(\),
        child: Column\(
          children: \[
            _buildScoreBoard\(\),
            const SizedBox\(height: 12\),
            _buildTabSection\(\),
            Padding\(
              padding: const EdgeInsets\.symmetric\(horizontal: 20\),
              child: _buildSelectedTabContent\(lineupProvider, isCoach\),
            \),
          \],
        \),
      \),
    \);
  \}'''

# Let's see: we want to replace this and all subsequent code till the end of the file.
# The replacement text:
replacement_text = '''    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        title: Text(
          'match.match_center'.tr(),
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isCoach)
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.redAccent),
              tooltip: 'Сбросить результат',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: PremiumTheme.surfaceCard(context),
                    title: const Text('Сброс результата матча', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Вы действительно хотите отменить счет и сбросить сыгранный матч? Статистика команд обнулится.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Отмена', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Сбросить', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  final matchProvider = context.read<MatchProvider>();
                  final success = await matchProvider.resetResult(widget.match.id);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Результат матча успешно сброшен'), backgroundColor: Colors.green),
                    );
                    context.read<TournamentProvider>().fetchTournamentDetails(widget.match.tournamentId ?? '');
                    Navigator.pop(context);
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(matchProvider.error ?? 'Ошибка при сбросе результата'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildScoreBoard(isDark, onSurface),
            const SizedBox(height: 12),
            _buildTabSection(isDark, onSurface),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSelectedTabContent(lineupProvider, isCoach, isDark, onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(LineupProvider lineupProvider, bool isCoach, bool isDark, Color onSurface) {
    if (_selectedTabIndex == 0) {
      // Lineups Tab
      return Column(
        children: [
          _buildLineupSection(
            context,
            widget.homeTeamName,
            widget.match.homeTeamId ?? '',
            widget.match.homeTeamId != null ? lineupProvider.getLineupForMatch(widget.match.id, widget.match.homeTeamId!) : null,
            isCoach,
            true,
            isDark,
            onSurface,
          ),
          const SizedBox(height: 24),
          _buildLineupSection(
            context,
            widget.awayTeamName,
            widget.match.awayTeamId ?? '',
            widget.match.awayTeamId != null ? lineupProvider.getLineupForMatch(widget.match.id, widget.match.awayTeamId!) : null,
            isCoach,
            false,
            isDark,
            onSurface,
          ),
          const SizedBox(height: 100),
        ],
      );
    } else if (_selectedTabIndex == 1) {
      // Timeline Tab
      return _buildTimelineSection(isDark, onSurface);
    } else {
      // Info / Details Tab
      return _buildInfoSection(isDark, onSurface);
    }
  }

  Widget _buildTimelineSection(bool isDark, Color onSurface) {
    final matchProvider = context.watch<MatchProvider>();
    final events = matchProvider.currentMatchEvents;

    final firstHalfEvents = events.where((e) => e.minute <= 45).toList();
    final secondHalfEvents = events.where((e) => e.minute > 45).toList();

    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(
                Icons.flash_off_outlined,
                color: onSurface.withOpacity(0.12),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'match.no_events'.tr(),
                style: TextStyle(
                  color: onSurface.withOpacity(0.35),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (firstHalfEvents.isNotEmpty) ...[
          _buildHalfHeader('match.first_half'.tr(), isDark, onSurface),
          const SizedBox(height: 12),
          ...firstHalfEvents.map((e) => _buildTimelineEventRow(e, isDark, onSurface)),
          const SizedBox(height: 24),
        ],
        if (secondHalfEvents.isNotEmpty) ...[
          _buildHalfHeader('match.second_half'.tr(), isDark, onSurface),
          const SizedBox(height: 12),
          ...secondHalfEvents.map((e) => _buildTimelineEventRow(e, isDark, onSurface)),
          const SizedBox(height: 48),
        ],
      ],
    );
  }

  Widget _buildHalfHeader(String label, bool isDark, Color onSurface) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: onSurface.withOpacity(0.06)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: PremiumTheme.neonGreen,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineEventRow(MatchEvent event, bool isDark, Color onSurface) {
    final isHome = event.teamId == widget.match.homeTeamId;
    final pId = event.playerId ?? event.childProfileId;
    final pName = pId != null ? (_playerNamesCache[pId] ?? 'match.player_placeholder'.tr(namedArgs: {'id': pId.length > 4 ? pId.substring(0, 4) : pId})) : 'match.player_generic'.tr();

    String emoji = '⚽';
    String typeLabel = '';
    if (event.eventType == EventType.GOAL) {
      emoji = '⚽';
      typeLabel = 'match.event_type_goal'.tr();
    } else if (event.eventType == EventType.YELLOW_CARD) {
      emoji = '🟨';
      typeLabel = 'match.event_type_yellow'.tr();
    } else if (event.eventType == EventType.RED_CARD) {
      emoji = '🟥';
      typeLabel = 'match.event_type_red'.tr();
    } else if (event.eventType == EventType.SUBSTITUTE) {
      emoji = '🔄';
      typeLabel = 'match.event_type_sub'.tr();
    }

    final contentWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isHome) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: PremiumTheme.neonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${event.minute}'",
              style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pName,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                typeLabel,
                style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 9),
              ),
            ],
          ),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pName,
                style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                typeLabel,
                style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 9),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${event.minute}'",
              style: TextStyle(color: onSurface.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isHome ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurface.withOpacity(0.04)),
            ),
            child: contentWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, Color onSurface) {
    final homeForm = widget.match.homeTeamId != null ? _calculateTeamForm(widget.match.homeTeamId!) : <String>[];
    final awayForm = widget.match.awayTeamId != null ? _calculateTeamForm(widget.match.awayTeamId!) : <String>[];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceCard(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'match.details_header'.tr(),
            style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_rounded, 'match.date_time'.tr(), widget.match.matchDate?.toString().substring(0, 16) ?? 'TBD', onSurface),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on_outlined, 'match.arena_field'.tr(), widget.match.fieldName ?? 'ARENA CENTER', onSurface),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.info_outline, 'match.match_status'.tr(), widget.match.status, onSurface),
          const SizedBox(height: 24),
          Divider(color: onSurface.withOpacity(0.08), height: 1),
          const SizedBox(height: 20),
          Text(
            'match.team_form_title'.tr(),
            style: TextStyle(color: onSurface.withOpacity(0.54), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          // Home form row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.homeTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (homeForm.isEmpty)
                _buildEmptyForm(onSurface)
              else
                Row(children: homeForm.map((f) => _buildFormCircle(f)).toList()),
            ],
          ),
          const SizedBox(height: 12),
          // Away form row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.awayTeamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              if (awayForm.isEmpty)
                _buildEmptyForm(onSurface)
              else
                Row(children: awayForm.map((f) => _buildFormCircle(f)).toList()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color onSurface) {
    return Row(
      children: [
        Icon(icon, size: 16, color: onSurface.withOpacity(0.38)),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(color: onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFormCircle(String result) {
    Color color = Colors.grey;
    String char = 'match.form_draw'.tr();
    if (result == 'W') {
      color = const Color(0xFF00E676);
      char = 'match.form_win'.tr();
    } else if (result == 'L') {
      color = Colors.redAccent;
      char = 'match.form_loss'.tr();
    }

    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        char,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyForm(Color onSurface) {
    return Text(
      '–',
      style: TextStyle(color: onSurface.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildScoreBoard(bool isDark, Color onSurface) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [PremiumTheme.surfaceBase(context), Colors.black]
              : [PremiumTheme.surfaceBase(context), Colors.white.withOpacity(0.92)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildTeamHeader(widget.homeTeamName, Colors.redAccent, onSurface)),
              _buildMiddleScore(isDark, onSurface),
              Expanded(child: _buildTeamHeader(widget.awayTeamName, Colors.blueAccent, onSurface)),
            ],
          ),
          const SizedBox(height: 32),
          _buildMatchMeta(onSurface),
          const SizedBox(height: 24),
          _buildActionButtons(isDark, onSurface),
        ],
      ),
    );
  }

  Widget _buildMiddleScore(bool isDark, Color onSurface) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: onSurface.withOpacity(0.08)),
          ),
          child: Text(
            '${widget.match.homeScore} : ${widget.match.awayScore}',
            style: TextStyle(color: onSurface, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.match.status == 'LIVE' ? Colors.redAccent.withOpacity(0.12) : Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.match.status,
            style: TextStyle(
              color: widget.match.status == 'LIVE' ? Colors.redAccent : Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(String name, Color color, Color onSurface) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: Icon(Icons.shield_rounded, size: 40, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMatchMeta(Color onSurface) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today_rounded, size: 14, color: onSurface.withOpacity(0.38)),
        const SizedBox(width: 8),
        Text(
          widget.match.matchDate?.toString().substring(0, 16) ?? 'match.time_tbd'.tr(),
          style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 20),
        Icon(Icons.location_on_outlined, size: 14, color: onSurface.withOpacity(0.38)),
        const SizedBox(width: 8),
        Text(
          'match.arena_center'.tr(),
          style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark, Color onSurface) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleAction(Icons.analytics_outlined, 'match.stats'.tr(), onSurface, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MatchEventsScreen(matchId: widget.match.id)));
        }),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.videocam_outlined, 'match.replay'.tr(), onSurface, null),
        const SizedBox(width: 24),
        _buildCircleAction(Icons.share_outlined, 'match.share'.tr(), onSurface, null),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, String label, Color onSurface, VoidCallback? onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.04),
              shape: BoxShape.circle,
              border: Border.all(color: onSurface.withOpacity(0.08)),
            ),
            child: Icon(icon, color: onTap != null ? onSurface : onSurface.withOpacity(0.24), size: 20),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: onTap != null ? onSurface.withOpacity(0.54) : onSurface.withOpacity(0.24),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection(bool isDark, Color onSurface) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            child: _buildTab('match.tab_lineups'.tr(), _selectedTabIndex == 0, onSurface),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 1),
            child: _buildTab('match.tab_timeline'.tr(), _selectedTabIndex == 1, onSurface),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 2),
            child: _buildTab('match.tab_details'.tr(), _selectedTabIndex == 2, onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active, Color onSurface) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? PremiumTheme.neonGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PremiumTheme.neonGreen : onSurface.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.black : onSurface.withOpacity(0.38),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLineupSection(
    BuildContext context,
    String teamName,
    String teamId,
    MatchLineup? lineup,
    bool isCoach,
    bool isHome,
    bool isDark,
    Color onSurface,
  ) {
    final color = isHome ? Colors.redAccent : Colors.blueAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                Text(
                  '$teamName LINEUP',
                  style: TextStyle(color: onSurface, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
            if (lineup != null)
              const Icon(Icons.check_circle_rounded, color: PremiumTheme.neonGreen, size: 18)
            else
              Text(
                'match.pending'.tr(),
                style: TextStyle(color: onSurface.withOpacity(0.24), fontSize: 10, fontWeight: FontWeight.w800),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (lineup == null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: onSurface.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onSurface.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.groups_3_outlined, color: onSurface.withOpacity(0.1), size: 40),
                const SizedBox(height: 12),
                Text('match.no_lineup'.tr(), style: TextStyle(color: onSurface.withOpacity(0.24), fontSize: 12)),
                if (isCoach && teamId.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchLineupScreen(matchId: widget.match.id, teamId: teamId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.12),
                      foregroundColor: color,
                      side: BorderSide(color: color.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('match.submit_lineup'.tr(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),
        ] else
          _buildLineupList(lineup, onSurface),
      ],
    );
  }

  Widget _buildLineupList(MatchLineup lineup, Color onSurface) {
    final starters = lineup.players.where((p) => p.isStarting).toList();
    final bench = lineup.players.where((p) => !p.isStarting).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSquadCategory('match.starting_xi'.tr(), starters, onSurface),
        const SizedBox(height: 16),
        _buildSquadCategory('match.substitutes'.tr(), bench, onSurface),
      ],
    );
  }

  Widget _buildSquadCategory(String title, List<LineupPlayer> players, Color onSurface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: onSurface.withOpacity(0.38), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        ...players.map((p) => _buildPlayerTile(p, onSurface)),
      ],
    );
  }

  Widget _buildPlayerTile(LineupPlayer p, Color onSurface) {
    final id = p.playerId ?? p.childProfileId ?? 'Unknown';
    final name = _playerNamesCache[id] ?? 'match.player_placeholder'.tr(namedArgs: {'id': id.length > 4 ? id.substring(0, 4) : id});
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerStatsScreen(playerId: id)));
        },
        dense: true,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            p.position ?? '?',
            style: const TextStyle(color: PremiumTheme.neonGreen, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(color: onSurface, fontWeight: FontWeight.w700, fontSize: 13),
        ),
        trailing: p.jerseyNumber != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: onSurface.withOpacity(0.06), borderRadius: BorderRadius.circular(4)),
              child: Text('#${p.jerseyNumber}', style: TextStyle(color: onSurface.withOpacity(0.7), fontWeight: FontWeight.w900, fontSize: 10)),
            )
          : null,
      ),
    );
  }
}
'''

# Escape target pattern for matching
escaped_target = re.escape(target_pattern).replace(r'\\', '\\')

# Replace the content
new_content, count = re.subn(target_pattern, replacement_text, content, flags=re.DOTALL)
print(f"Substitutions count: {count}")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Replacement complete!")
