import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:easy_localization/easy_localization.dart';
import '../../providers/notification_provider.dart';
import '../../../clubs/providers/club_provider.dart';
import '../../../clubs/data/models/invitation.dart';
import '../../../auth/providers/auth_provider.dart' as import_auth;
import '../../../teams/providers/team_provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import '../../../matches/data/repositories/match_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../tournaments/presentation/screens/match_center_screen.dart';
import '../../../tournaments/presentation/screens/tournament_details_page.dart';
import '../../../teams/presentation/screens/team_details_screen.dart';
import '../../../clubs/presentation/screens/club_dashboard_screen.dart';


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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: context.findAncestorWidgetOfExactType<Scaffold>() != null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'notification.notifications'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
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
                    style: TextStyle(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTheme.neonGreen,
                      foregroundColor: PremiumTheme.surfaceBase(context),
                    ),
                    child: Text('notification.retry'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
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
                    Text(
                      'notification.inbox'.tr(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildFilterChip('all', 'notification.all'.tr()),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'unread',
                          unreadCount > 0 ? 'notification.unread_count'.tr(namedArgs: {'count': unreadCount.toString()}) : 'notification.unread'.tr(),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('matches', 'notification.matches'.tr()),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: cs.onSurface.withValues(alpha: 0.08)),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: cs.onSurface.withValues(alpha: 0.15),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'notification.no_notifications'.tr(),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.3),
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
                        separatorBuilder: (ctx, _) => Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.06),
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
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.black : cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final dynamic notification;

  const _NotificationCard({required this.notification});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  Map<String, String> _getLocalizedNotification(String title, String message, String lang) {
    String localTitle = title;
    String localMessage = message;

    if (lang == 'ru') {
      if (title == 'Invitation Accepted') {
        localTitle = 'Приглашение принято';
      } else if (title == 'Club Request Approved') {
        localTitle = 'Заявка клуба одобрена';
      } else if (title == 'Club Request Rejected') {
        localTitle = 'Заявка клуба отклонена';
      } else if (title == 'New Club Registration Request') {
        localTitle = 'Новый запрос на регистрацию';
      } else if (title == 'Match Scheduled! ⚽') {
        localTitle = 'Матч запланирован! ⚽';
      } else if (title == 'Match Result! 🏆') {
        localTitle = 'Результат матча! 🏆';
      }

      if (message.contains('has accepted your invitation to join the club')) {
        final name = message.split(' has accepted')[0];
        localMessage = '$name принял ваше приглашение вступить в клуб.';
      } else if (message.contains('Congratulations! Your request for \'')) {
        final clubName = message.split('Congratulations! Your request for \'')[1].split('\' has been approved')[0];
        localMessage = 'Поздравляем! Ваш запрос на создание клуба «$clubName» был одобрен. Теперь вы владелец.';
      } else if (message.contains('We regret to inform you that your request for \'')) {
        final clubName = message.split('We regret to inform you that your request for \'')[1].split('\' has been rejected')[0];
        localMessage = 'К сожалению, ваш запрос на создание клуба «$clubName» был отклонен.';
      } else if (message.contains('New match scheduled: ')) {
        final matchTeams = message.replaceAll('New match scheduled: ', '');
        localMessage = 'Запланирован новый матч: $matchTeams';
      } else if (message.contains('Final score: ')) {
        final score = message.replaceAll('Final score: ', '');
        localMessage = 'Итоговый счет: $score';
      }
    } else if (lang == 'kk') {
      if (title == 'Invitation Accepted') {
        localTitle = 'Шақыру қабылданды';
      } else if (title == 'Club Request Approved') {
        localTitle = 'Клуб сұранысы мақұлданды';
      } else if (title == 'Club Request Rejected') {
        localTitle = 'Клуб сұранысы қабылданбады';
      } else if (title == 'New Club Registration Request') {
        localTitle = 'Клубты тіркеуге жаңа сұраныс';
      } else if (title == 'Match Scheduled! ⚽') {
        localTitle = 'Матч жоспарланды! ⚽';
      } else if (title == 'Match Result! 🏆') {
        localTitle = 'Матч нәтижесі! 🏆';
      }

      if (message.contains('has accepted your invitation to join the club')) {
        final name = message.split(' has accepted')[0];
        localMessage = '$name клубқа қосылу туралы шақыруыңызды қабылдады.';
      } else if (message.contains('Congratulations! Your request for \'')) {
        final clubName = message.split('Congratulations! Your request for \'')[1].split('\' has been approved')[0];
        localMessage = 'Құттықтаймыз! «$clubName» клубын құру сұранысыңыз мақұлданды. Енді сіз иесіз.';
      } else if (message.contains('We regret to inform you that your request for \'')) {
        final clubName = message.split('We regret to inform you that your request for \'')[1].split('\' has been rejected')[0];
        localMessage = 'Өкінішке орай, «$clubName» клубын құру сұранысыңыз қабылданбады.';
      } else if (message.contains('New match scheduled: ')) {
        final matchTeams = message.replaceAll('New match scheduled: ', '');
        localMessage = 'Жаңа матч жоспарланды: $matchTeams';
      } else if (message.contains('Final score: ')) {
        final score = message.replaceAll('Final score: ', '');
        localMessage = 'Қорытынды есеп: $score';
      }
    }

    return {'title': localTitle, 'message': localMessage};
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    final cs = Theme.of(context).colorScheme;
    final lang = context.locale.languageCode;
    final localized = _getLocalizedNotification(notification.title, notification.message, lang);
    final displayTitle = localized['title']!;
    final displayMessage = localized['message']!;
    final isInvite = notification.type == 'TEAM_INVITE' || notification.type == 'PARENT_LINK_REQUEST';
    final isApprovalRequest = notification.title == 'Invitation Approval Required';
    final isUnread = !notification.isRead;
    final (iconData, iconColor) = _getTypeStyle(notification.type);

    final provider = context.watch<NotificationProvider>();
    final resolvedStatus = provider.getResolvedStatus(notification.id);

    return GestureDetector(
      onTap: () {
        if (isUnread) {
          context.read<NotificationProvider>().markAsRead(notification.id);
        }
        _handleTapNavigation(context, notification);
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
                              displayTitle,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                                color: isUnread ? cs.onSurface : cs.onSurface.withValues(alpha: 0.65),
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
                        displayMessage,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(DateTime.parse(notification.createdAt)),
                        style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
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
                  if (resolvedStatus != null)
                    _ResultBadge(accepted: resolvedStatus == 'accepted')
                  else if (isApprovalRequest)
                    _ActionButton(
                      label: 'notification.approve'.tr(),
                      color: PremiumTheme.neonGreen,
                      textColor: Colors.black,
                      onPressed: () => _handleInvitation(context, notification.entityId, true, isApproval: true),
                    )
                  else ...[
                    _ActionButton(
                      label: 'notification.decline'.tr(),
                      color: Colors.transparent,
                      textColor: Colors.redAccent,
                      border: Colors.redAccent,
                      onPressed: () => _handleInvitation(context, notification.entityId, false),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'notification.accept'.tr(),
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

  Future<void> _handleTapNavigation(BuildContext context, dynamic notification) async {
    final entityId = notification.entityId;
    final entityType = notification.entityType;
    final type = notification.type;

    if (entityId == null || entityId.isEmpty) return;

    if (entityType == 'MATCH' || type == 'MATCH_SCHEDULED' || type == 'MATCH_RESULT' || (type == 'PLAYER_SELECTED' && entityType == 'MATCH')) {
      _navigateToMatch(context, entityId);
    } else if (entityType == 'TOURNAMENT' || type.toString().contains('TOURNAMENT')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentDetailsPage(tournamentId: entityId),
        ),
      );
    } else if (entityType == 'TEAM' || type == 'TEAM_INVITE') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamDetailsScreen(teamId: entityId),
        ),
      );
    }
  }

  Future<void> _navigateToMatch(BuildContext context, String matchId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: PremiumTheme.neonGreen),
      ),
    );

    try {
      final matchRepository = MatchRepository(ApiClient());
      final match = await matchRepository.getMatchById(matchId);
      
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
        if (match.tournamentId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchCenterScreen(
                matchId: match.id,
                tournamentId: match.tournamentId!,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournament ID not found for this match')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
        String errorMessage = 'Error loading match details: $e';
        if (e.toString().contains('404') || e.toString().toLowerCase().contains('not found')) {
          errorMessage = 'match.match_not_found'.tr();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }


  void _handleInvitation(BuildContext context, String? invitationId, bool accept,
      {bool isApproval = false}) async {
    if (invitationId == null) return;

    final notificationProvider = context.read<NotificationProvider>();
    final authProvider = context.read<import_auth.AuthProvider>();
    final clubProvider = context.read<ClubProvider>();
    bool success = false;

    String finalInvitationId = invitationId;
    if (widget.notification.type == 'TEAM_INVITE') {
      try {
        await clubProvider.fetchMyInvitations();
        final matchingInvite = clubProvider.myInvitations.firstWhere(
          (invite) => invite.status == InvitationStatus.pending && 
                      (invite.clubId == invitationId || invite.teamId == invitationId),
        );
        finalInvitationId = matchingInvite.id;
      } catch (e) {
        // fallback
      }
    }

    if (widget.notification.type == 'PARENT_LINK_REQUEST') {
      success = accept
          ? await authProvider.acceptRequest(finalInvitationId)
          : await authProvider.rejectRequest(finalInvitationId);
    } else {
      if (isApproval) {
        success = await clubProvider.approveInvitation(finalInvitationId);
      } else if (accept) {
        success = await clubProvider.acceptInvitation(finalInvitationId);
      } else {
        success = await clubProvider.declineInvitation(finalInvitationId);
      }
    }

    if (context.mounted) {
      if (success) {
        final authProvider = context.read<import_auth.AuthProvider>();
        final teamProvider = context.read<TeamProvider>();

        await notificationProvider.setResolvedStatus(widget.notification.id, accept ? 'accepted' : 'declined');
        notificationProvider.markAsRead(widget.notification.id);
        
        // Refresh appropriate provider data instantly
        if (widget.notification.type == 'PARENT_LINK_REQUEST') {
          authProvider.fetchMyParents();
          authProvider.checkAuthStatus();
          authProvider.fetchParentRequests();
          if (widget.notification.entityId != null) {
            for (final n in notificationProvider.notifications) {
              if (n.entityId == widget.notification.entityId &&
                  n.id != widget.notification.id) {
                await notificationProvider.setResolvedStatus(
                    n.id, accept ? 'accepted' : 'declined');
              }
            }
          }
        } else if (widget.notification.type == 'TEAM_INVITE') {
          teamProvider.fetchMyTeams();
          authProvider.checkAuthStatus();
        }

        notificationProvider.fetchNotifications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('notification.action_failed'.tr())),
        );
      }
    }
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
      _ => (Icons.notifications_rounded, Colors.grey),
    };
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

class _ResultBadge extends StatelessWidget {
  final bool accepted;

  const _ResultBadge({required this.accepted});

  @override
  Widget build(BuildContext context) {
    final color = accepted ? PremiumTheme.neonGreen : Colors.redAccent;
    final icon = accepted ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = accepted ? 'admin.approved'.tr() : 'admin.rejected'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
