import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminProvider>().fetchAllUsers());
  }

  TextStyle _t(double size, FontWeight w, Color color) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text('admin.user_management'.tr(), style: _t(18, FontWeight.w600, onSurface)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.users.isEmpty) {
            return Center(
              child: Text(
                'No users found',
                style: _t(14, FontWeight.w400, onSurface.withValues(alpha: 0.5)),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllUsers(),
            color: PremiumTheme.neonGreen,
            child: ListView.builder(
              itemCount: provider.users.length,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemBuilder: (context, index) {
                final user = provider.users[index];
                final name = user['name'] ?? 'Unknown User';
                final email = user['email'] ?? '';
                final roles = List<String>.from(user['roles'] ?? []);
                final clubName = user['club_name'];

                return PremiumCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Text(
                        name.substring(0, 1).toUpperCase(),
                        style: _t(16, FontWeight.w700, cs.primary),
                      ),
                    ),
                    title: Text(name, style: _t(15, FontWeight.w600, onSurface)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(email, style: _t(12, FontWeight.w400, onSurface.withValues(alpha: 0.45))),
                        if (clubName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.business, size: 12, color: cs.primary),
                              const SizedBox(width: 4),
                              Text(clubName, style: _t(12, FontWeight.w500, cs.primary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: roles.map((r) => _buildRoleChip(r)).toList(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color bg;
    Color text;
    switch (role.toUpperCase()) {
      case 'ADMIN':
      case 'ORGANIZER':
        bg = Colors.red.withValues(alpha: 0.12);
        text = Colors.red;
        break;
      case 'TOURNAMENT_ORGANIZER':
        bg = Colors.orange.withValues(alpha: 0.12);
        text = Colors.orange;
        break;
      case 'CLUB_OWNER':
      case 'COACH':
        bg = PremiumTheme.neonGreen.withValues(alpha: 0.12);
        text = PremiumTheme.neonGreen;
        break;
      default:
        bg = Colors.blue.withValues(alpha: 0.12);
        text = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        role.replaceAll('_', ' '),
        style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
