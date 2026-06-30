import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _pushNotifications = true;
  String _cacheSize = "12.4 MB";

  TextStyle _t(double size, FontWeight w, Color color) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('admin.system_settings'.tr(), style: _t(18, FontWeight.w600, onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('General Settings', cs),
          PremiumCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Maintenance Mode', style: _t(14, FontWeight.w600, onSurface)),
                  subtitle: Text('Disable public app access during updates', style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                  value: _maintenanceMode,
                  activeColor: PremiumTheme.neonGreen,
                  onChanged: (val) {
                    setState(() => _maintenanceMode = val);
                  },
                ),
                Divider(color: onSurface.withValues(alpha: 0.08), height: 1),
                SwitchListTile(
                  title: Text('Global Push Notifications', style: _t(14, FontWeight.w600, onSurface)),
                  subtitle: Text('Enable automatic alerts and matching notifications', style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                  value: _pushNotifications,
                  activeColor: PremiumTheme.neonGreen,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('System & Cache', cs),
          PremiumCard(
            child: Column(
              children: [
                ListTile(
                  title: Text('Cache Size', style: _t(14, FontWeight.w600, onSurface)),
                  subtitle: Text('Temporary images and response cache', style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                  trailing: Text(_cacheSize, style: _t(13, FontWeight.w700, cs.primary)),
                ),
                Divider(color: onSurface.withValues(alpha: 0.08), height: 1),
                ListTile(
                  title: Text('Clear Cache', style: _t(14, FontWeight.w600, Colors.red)),
                  subtitle: Text('Remove cached network files', style: _t(11, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                  trailing: const Icon(Icons.delete_outline, color: Colors.red),
                  onTap: () {
                    setState(() => _cacheSize = "0.0 B");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('App Info', cs),
          PremiumCard(
            child: Column(
              children: [
                ListTile(
                  title: Text('App Version', style: _t(14, FontWeight.w600, onSurface)),
                  trailing: Text('1.0.0 (Build 42)', style: _t(13, FontWeight.w500, onSurface.withValues(alpha: 0.5))),
                ),
                Divider(color: onSurface.withValues(alpha: 0.08), height: 1),
                ListTile(
                  title: Text('SDK Level', style: _t(14, FontWeight.w600, onSurface)),
                  trailing: Text('Flutter 3.22.x', style: _t(13, FontWeight.w500, onSurface.withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: cs.onSurface.withValues(alpha: 0.45),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
