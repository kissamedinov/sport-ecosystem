import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../data/models/invitation.dart';
import 'package:mobile/core/theme/premium_theme.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<ClubProvider>();
    Future.microtask(() => provider.fetchMyInvitations());
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
          'INVITATIONS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myInvitations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            );
          }

          if (provider.myInvitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 16),
                  Text(
                    'NO INVITATIONS',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.15),
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
            itemCount: provider.myInvitations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invite = provider.myInvitations[index];
              return _InvitationCard(invitation: invite);
            },
          );
        },
      ),
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ClubProvider>();
    final isPending = invitation.status == InvitationStatus.pending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPending
            ? PremiumTheme.electricBlue.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? PremiumTheme.electricBlue.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PremiumTheme.electricBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business_rounded, color: PremiumTheme.electricBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Club Invitation',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Club ID: ${invitation.clubId.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 11, color: Colors.white38),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(invitation.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Role: ${invitation.role.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => provider.declineInvitation(invitation.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  child: const Text('DECLINE'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => provider.acceptInvitation(invitation.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.neonGreen,
                    foregroundColor: PremiumTheme.deepNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                  child: const Text('ACCEPT'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InvitationStatus status) {
    final (Color color, String label) = switch (status) {
      InvitationStatus.pending => (Colors.orange, 'PENDING'),
      InvitationStatus.accepted => (Colors.green, 'ACCEPTED'),
      InvitationStatus.declined => (Colors.red, 'DECLINED'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}
