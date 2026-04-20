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
  String _filter = 'all';

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
        leading: context.findAncestorWidgetOfExactType<Scaffold>() != null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
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
            icon: const Icon(Icons.tune_rounded, color: Colors.white54, size: 20),
            onPressed: () {},
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

          final all = provider.notifications;
          final unreadCount = all.where((n) => !n.isRead).length;
          final filtered = _filter == 'unread'
              ? all.where((n) => !n.isRead).toList()
              : _filter == 'matches'
                  ? all.where((n) => n.type == 'MATCH_SCHEDULED' || n.type == 'MATCH_RESULT').toList()
                  : all;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inbox',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildFilterChip('all', 'ALL'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'unread',
                          unreadCount > 0 ? 'UNREAD · $unreadCount' : 'UNREAD',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('matches', 'MATCHES'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
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
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                        itemBuilder: (context, index) {
                          return _NotificationCard(notification: filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? PremiumTheme.neonGreen : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? PremiumTheme.neonGreen : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.black : Colors.white60,
            letterSpacing: 0.5,
          ),
        ),
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
    final isApprovalRequest = notification.title == 'Invitation Approval Required';
    final isUnread = !notification.isRead;
    final (iconData, iconColor) = _getTypeStyle(notification.type);

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                                color: isUnread ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              decoration: BoxDecoration(
                                color: iconColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.message,
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(DateTime.parse(notification.createdAt)),
                        style: const TextStyle(fontSize: 11, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isInvite) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isApprovalRequest)
                    _ActionButton(
                      label: 'APPROVE',
                      color: PremiumTheme.neonGreen,
                      textColor: Colors.black,
                      onPressed: () => _handleInvitation(context, notification.entityId, true, isApproval: true),
                    )
                  else ...[
                    _ActionButton(
                      label: 'DECLINE',
                      color: Colors.transparent,
                      textColor: Colors.redAccent,
                      border: Colors.redAccent,
                      onPressed: () => _handleInvitation(context, notification.entityId, false),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'ACCEPT',
                      color: PremiumTheme.neonGreen,
                      textColor: Colors.black,
                      onPressed: () => _handleInvitation(context, notification.entityId, true),
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

  (IconData, Color) _getTypeStyle(String type) {
    return switch (type) {
      'TEAM_INVITE' => (Icons.person_add_alt_1_rounded, Colors.amber),
      'MATCH_SCHEDULED' => (Icons.event_rounded, Colors.blue),
      'MATCH_RESULT' => (Icons.sports_soccer_rounded, PremiumTheme.neonGreen),
      'PARENT_LINK_REQUEST' => (Icons.family_restroom_rounded, Colors.orangeAccent),
      'PLAYER_SELECTED' => (Icons.star_rounded, Colors.orange),
      'CLUB_REQUEST' => (Icons.business_center_rounded, Colors.purple),
      'CLUB_APPROVED' => (Icons.check_circle_rounded, PremiumTheme.neonGreen),
      'CLUB_REJECTED' => (Icons.cancel_rounded, Colors.red),
      'JOIN_REQUEST_RECEIVED' => (Icons.person_add_rounded, Colors.blueAccent),
      'JOIN_REQUEST_ACCEPTED' => (Icons.check_circle_rounded, PremiumTheme.neonGreen),
      'JOIN_REQUEST_REJECTED' => (Icons.cancel_rounded, Colors.red),
      _ => (Icons.notifications_rounded, Colors.white38),
    };
  }

  void _handleInvitation(BuildContext context, String? invitationId, bool accept,
      {bool isApproval = false}) async {
    if (invitationId == null) return;

    final notificationProvider = context.read<NotificationProvider>();
    bool success = false;

    if (notification.type == 'PARENT_LINK_REQUEST') {
      final authProvider = context.read<import_auth.AuthProvider>();
      success = accept
          ? await authProvider.acceptRequest(invitationId)
          : await authProvider.rejectRequest(invitationId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? (accept ? 'Invitation accepted!' : 'Invitation declined.')
              : 'Action failed. Please try again.'),
        ),
      );
      if (success) {
        notificationProvider.markAsRead(notification.id);
        notificationProvider.fetchNotifications();
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: border != null ? Border.all(color: border!) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
