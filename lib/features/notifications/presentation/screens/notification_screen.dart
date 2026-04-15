import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notification_provider.dart';
import '../../../clubs/providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart' as import_auth;
import 'package:mobile/core/theme/premium_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    Future.microtask(() => provider.fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        title: const Text(
          'NOTIFICATIONS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
            onPressed: () => context.read<NotificationProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            );
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: PremiumTheme.deepNavy,
                    ),
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'NO NOTIFICATIONS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = provider.notifications[index];
              return _NotificationCard(notification: notification);
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isInvite = notification.type == 'TEAM_INVITE' || notification.type == 'PARENT_LINK_REQUEST';
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? PremiumTheme.neonGreen.withValues(alpha: 0.04)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? PremiumTheme.neonGreen.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeIcon(notification.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isUnread ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeago.format(DateTime.parse(notification.createdAt)),
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: PremiumTheme.neonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notification.message,
              style: const TextStyle(fontSize: 13, color: Colors.white60),
            ),
            if (isInvite) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (notification.title == "Invitation Approval Required")
                    ElevatedButton(
                      onPressed: () => _handleInvitation(context, notification.entityId, true, isApproval: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.neonGreen,
                        foregroundColor: PremiumTheme.deepNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      child: const Text('APPROVE'),
                    )
                  else ...[
                    OutlinedButton(
                      onPressed: () => _handleInvitation(context, notification.entityId, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      child: const Text('DECLINE'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _handleInvitation(context, notification.entityId, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PremiumTheme.neonGreen,
                        foregroundColor: PremiumTheme.deepNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      child: const Text('ACCEPT'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'TEAM_INVITE':
        iconData = Icons.mail_rounded;
        color = Colors.blue;
        break;
      case 'MATCH_SCHEDULED':
        iconData = Icons.event_rounded;
        color = Colors.green;
        break;
      case 'PARENT_LINK_REQUEST':
        iconData = Icons.family_restroom_rounded;
        color = Colors.orangeAccent;
        break;
      case 'PLAYER_SELECTED':
        color = Colors.orange;
        iconData = Icons.star_rounded;
        break;
      case 'CLUB_REQUEST':
        color = Colors.purple;
        iconData = Icons.business_center_rounded;
        break;
      case 'CLUB_APPROVED':
        color = Colors.green;
        iconData = Icons.check_circle_rounded;
        break;
      case 'CLUB_REJECTED':
        color = Colors.red;
        iconData = Icons.cancel_rounded;
        break;
      case 'JOIN_REQUEST_RECEIVED':
        color = Colors.blueAccent;
        iconData = Icons.person_add_rounded;
        break;
      case 'JOIN_REQUEST_ACCEPTED':
        color = Colors.green;
        iconData = Icons.check_circle_rounded;
        break;
      case 'JOIN_REQUEST_REJECTED':
        color = Colors.red;
        iconData = Icons.cancel_rounded;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _handleInvitation(BuildContext context, String? invitationId, bool accept, {bool isApproval = false}) async {
    if (invitationId == null) return;

    final notificationProvider = context.read<NotificationProvider>();
    bool success = false;

    if (notification.type == 'PARENT_LINK_REQUEST') {
      final authProvider = context.read<import_auth.AuthProvider>();
      if (accept) {
        success = await authProvider.acceptRequest(invitationId);
      } else {
        success = await authProvider.rejectRequest(invitationId);
      }
    } else {
      final clubProvider = context.read<ClubProvider>();
      if (isApproval) {
        success = await clubProvider.approveInvitation(invitationId);
      } else if (accept) {
        success = await clubProvider.acceptInvitation(invitationId);
      } else {
        success = await clubProvider.declineInvitation(invitationId);
      }
    }

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Invitation accepted!' : 'Invitation declined.')),
        );
        notificationProvider.markAsRead(notification.id);
        notificationProvider.fetchNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Please try again.')),
        );
      }
    }
  }
}
