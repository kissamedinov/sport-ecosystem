import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notification_provider.dart';
import '../../../clubs/providers/club_provider.dart';
import '../../../auth/providers/auth_provider.dart' as import_auth;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<NotificationProvider>().fetchNotifications(),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    child: const Text('Retry'),
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
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
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
    final backgroundColor = notification.isRead 
      ? Theme.of(context).cardColor 
      : Theme.of(context).primaryColor.withOpacity(0.05);

    return Card(
      elevation: notification.isRead ? 1 : 4,
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: notification.isRead 
          ? BorderSide.none 
          : BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
          // Navigate to entity if applicable
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTypeIcon(context, notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          timeago.format(DateTime.parse(notification.createdAt)),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
              ),
              if (isInvite) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (notification.title == "Invitation Approval Required")
                      ElevatedButton(
                        onPressed: () => _handleInvitation(context, notification.entityId, true, isApproval: true),
                        child: const Text('Approve'),
                      )
                    else ...[
                      OutlinedButton(
                        onPressed: () => _handleInvitation(context, notification.entityId, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _handleInvitation(context, notification.entityId, true),
                        child: const Text('Accept'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(BuildContext context, String type) {
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
        color: color.withOpacity(0.1),
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
        // Mark as read and refresh
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
