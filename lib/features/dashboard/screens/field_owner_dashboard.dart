import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/dashboard_widgets.dart';
import 'adult_player_dashboard.dart'; // for TemporaryScreen
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/presentation/screens/notification_screen.dart';

class FieldOwnerDashboard extends StatefulWidget {
  const FieldOwnerDashboard({super.key});

  @override
  State<FieldOwnerDashboard> createState() => _FieldOwnerDashboardState();
}

class _FieldOwnerDashboardState extends State<FieldOwnerDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('field.partner_hub'.tr()),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                    },
                  ),
                  if (provider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${provider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              title: 'field.welcome_partner'.tr(namedArgs: {'name': user?.name ?? 'field.partner'.tr()}),
              subtitle: 'field.field_owner_dashboard'.tr(),
            ),
            const SizedBox(height: 24),
            DashboardActionCard(
              title: 'field.booking_requests'.tr(),
              subtitle: 'field.booking_requests_desc'.tr(),
              icon: Icons.book_online,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.booking_requests'.tr())));
              },
            ),
            const SizedBox(height: 16),
            DashboardActionCard(
              title: 'profile.my_fields'.tr(),
              subtitle: 'field.manage_availability_pricing'.tr(),
              icon: Icons.stadium,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.manage_fields'.tr())));
              },
            ),
            const SizedBox(height: 32),
            Text('field.management_tools'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                DashboardGridAction(
                  label: 'field.calendar'.tr(),
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.reservations_calendar'.tr()))),
                ),
                DashboardGridAction(
                  label: 'field.earnings'.tr(),
                  icon: Icons.attach_money,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.earnings_overview'.tr()))),
                ),
                DashboardGridAction(
                  label: 'field.reviews'.tr(),
                  icon: Icons.star_border,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.customer_reviews'.tr()))),
                ),
                DashboardGridAction(
                  label: 'field.promotions'.tr(),
                  icon: Icons.local_offer,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemporaryScreen(title: 'field.promotions'.tr()))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
