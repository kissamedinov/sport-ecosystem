import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import 'invite_member_screen.dart';
import 'create_child_profile_screen.dart';

const _kGreen = Color(0xFF00E676);
const _kBlue  = Color(0xFF1E90D4);
const _kAmber = Color(0xFFFFC107);
const _kTeal  = Color(0xFF1DE9B6);

TextStyle _t(double size, FontWeight w, Color color, {double ls = 0}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, letterSpacing: ls);

class ClubQuickActionsScreen extends StatelessWidget {
  const ClubQuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('nav.quick_actions_title'.tr(),
                  style: _t(24, FontWeight.w600, onSurface)),
              const SizedBox(height: 6),
              Text('nav.quick_actions_subtitle'.tr(),
                  style: _t(14, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
              const SizedBox(height: 32),
              Consumer<ClubProvider>(
                builder: (context, clubProvider, _) {
                  final clubId = clubProvider.dashboard?.club.id;
                  final academies = clubProvider.dashboard?.academies ?? [];
                  return Column(
                    children: [
                      _ActionCard(
                        icon: Icons.group_add_outlined,
                        title: 'nav.invite_member'.tr(),
                        subtitle: 'nav.invite_member_sub'.tr(),
                        accent: _kBlue,
                        onTap: clubId == null ? null : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InviteMemberScreen(clubId: clubId)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.sports_soccer_outlined,
                        title: 'nav.add_player_profile'.tr(),
                        subtitle: 'nav.add_player_profile_sub'.tr(),
                        accent: _kGreen,
                        onTap: clubId == null ? null : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateChildProfileScreen(clubId: clubId),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.shield_outlined,
                        title: 'nav.create_team'.tr(),
                        subtitle: 'nav.create_team_sub'.tr(),
                        accent: _kTeal,
                        onTap: () => _showCreateTeamSheet(context, academies),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.account_balance_outlined,
                        title: 'nav.add_academy'.tr(),
                        subtitle: 'nav.add_academy_sub'.tr(),
                        accent: _kAmber,
                        onTap: clubId == null ? null : () => showCreateAcademySheet(context, clubId),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateTeamSheet(BuildContext rootCtx, List<dynamic> academies) {
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '2015');
    String? selectedAcademyId;

    showModalBottomSheet(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final onSurface = Theme.of(ctx).colorScheme.onSurface;
          final cardColor = PremiumTheme.surfaceCard(ctx);
          final border = PremiumTheme.borderSubtle(ctx);
          return Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              left: 24, right: 24, top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _handle(onSurface),
                const SizedBox(height: 24),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_outlined, color: _kTeal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text('club.create_team_title'.tr(), style: _t(20, FontWeight.w800, onSurface)),
                ]),
                const SizedBox(height: 24),
                if (academies.isEmpty)
                  _warningBanner(onSurface, 'club.create_team_academy_warning'.tr())
                else ...[
                  _label(onSurface, 'club.academy_required'.tr()),
                  const SizedBox(height: 8),
                  _dropdown<String>(
                    ctx: ctx,
                    cardColor: cardColor,
                    border: border,
                    onSurface: onSurface,
                    value: selectedAcademyId,
                    hint: 'club.academy_required'.tr(),
                    items: academies.map((a) => DropdownMenuItem(
                      value: a.id.toString(),
                      child: Text(a.name, style: _t(13, FontWeight.w500, onSurface)),
                    )).toList(),
                    onChanged: (v) => setModal(() => selectedAcademyId = v),
                  ),
                  const SizedBox(height: 16),
                  _label(onSurface, 'club.team_name_required'.tr()),
                  const SizedBox(height: 8),
                  _field(ctx, nameCtrl, 'club.team_name_hint'.tr(), onSurface, border),
                  const SizedBox(height: 16),
                  _label(onSurface, 'club.birth_year'.tr()),
                  const SizedBox(height: 8),
                  _field(ctx, yearCtrl, '2015', onSurface, border,
                      type: TextInputType.number),
                  const SizedBox(height: 28),
                  _submitBtn(
                    label: 'club.create'.tr(),
                    accent: _kTeal,
                    onPressed: selectedAcademyId == null ? null : () async {
                      ctx.read<ClubProvider>().createTeam(
                        selectedAcademyId!,
                        nameCtrl.text,
                        int.tryParse(yearCtrl.text) ?? 2015,
                        '',
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static void showCreateAcademySheet(BuildContext rootCtx, String clubId) {
    final nameCtrl    = TextEditingController();
    final cityCtrl    = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final onSurface = Theme.of(ctx).colorScheme.onSurface;
        final cardColor = PremiumTheme.surfaceCard(ctx);
        final border    = PremiumTheme.borderSubtle(ctx);
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            left: 24, right: 24, top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _handle(onSurface),
                const SizedBox(height: 24),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _kAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_outlined, color: _kAmber, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text('club.add_academy_title'.tr(), style: _t(20, FontWeight.w800, onSurface)),
                ]),
                const SizedBox(height: 24),
                _label(onSurface, 'club.academy_name_required'.tr()),
                const SizedBox(height: 8),
                _field(ctx, nameCtrl, 'club.academy_name_hint'.tr(), onSurface, border),
                const SizedBox(height: 16),
                _label(onSurface, 'club.city_required'.tr()),
                const SizedBox(height: 8),
                _field(ctx, cityCtrl, 'club.city_hint'.tr(), onSurface, border),
                const SizedBox(height: 16),
                _label(onSurface, 'club.address'.tr()),
                const SizedBox(height: 8),
                _field(ctx, addressCtrl, 'club.address_hint'.tr(), onSurface, border),
                const SizedBox(height: 28),
                _submitBtn(
                  label: 'club.create'.tr(),
                  accent: _kAmber,
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || cityCtrl.text.isEmpty) return;
                    ctx.read<ClubProvider>().createAcademy(
                      clubId,
                      nameCtrl.text,
                      cityCtrl.text,
                      addressCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────
  static Widget _handle(Color onSurface) => Center(
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: onSurface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  static Widget _label(Color onSurface, String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: onSurface.withValues(alpha: 0.4), letterSpacing: 1.4),
      );

  static Widget _field(
    BuildContext ctx,
    TextEditingController ctrl,
    String hint,
    Color onSurface,
    Color border, {
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        keyboardType: type,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
              fontSize: 13, fontWeight: FontWeight.w400, color: onSurface.withValues(alpha: 0.35)),
          filled: true,
          fillColor: onSurface.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kGreen, width: 1.5),
          ),
        ),
      );

  static Widget _dropdown<T>({
    required BuildContext ctx,
    required Color cardColor,
    required Color border,
    required Color onSurface,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      DropdownButtonFormField<T>(
        dropdownColor: cardColor,
        initialValue: value,
        hint: Text(hint, style: GoogleFonts.outfit(fontSize: 13, color: onSurface.withValues(alpha: 0.4))),
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface),
        decoration: InputDecoration(
          filled: true,
          fillColor: onSurface.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kGreen, width: 1.5),
          ),
        ),
      );

  static Widget _warningBanner(Color onSurface, String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAmber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_rounded, color: _kAmber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: _kAmber)),
          ),
        ]),
      );

  static Widget _submitBtn({
    required String label,
    required Color accent,
    required VoidCallback? onPressed,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: onPressed != null
                ? LinearGradient(colors: [accent, accent.withValues(alpha: 0.75)])
                : null,
            color: onPressed == null ? accent.withValues(alpha: 0.3) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed != null
                ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onPressed,
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: onPressed != null ? Colors.black : Colors.black54,
                    letterSpacing: 0.5)),
          ),
        ),
      );
}

// ── Action card widget ──────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: PremiumTheme.surfaceCard(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PremiumTheme.borderSubtle(context).withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.07)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: _t(15, FontWeight.w700, onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
