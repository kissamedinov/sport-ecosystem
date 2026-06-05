import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    final currentLocale = context.locale;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'settings.select_language'.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _buildLanguageItem(
            context: context,
            flag: '🇬🇧',
            label: 'English',
            locale: const Locale('en'),
            isSelected: currentLocale.languageCode == 'en',
          ),
          _buildLanguageItem(
            context: context,
            flag: '🇷🇺',
            label: 'Русский',
            locale: const Locale('ru'),
            isSelected: currentLocale.languageCode == 'ru',
          ),
          _buildLanguageItem(
            context: context,
            flag: '🇰🇿',
            label: 'Қазақша',
            locale: const Locale('kk'),
            isSelected: currentLocale.languageCode == 'kk',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required String flag,
    required String label,
    required Locale locale,
    required bool isSelected,
  }) {
    final accent = PremiumTheme.accent(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.setLocale(locale);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                    color: isSelected ? accent : onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
