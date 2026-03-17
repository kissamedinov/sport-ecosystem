import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../data/models/invitation.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClubProvider>().fetchMyInvitations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invitations'),
      ),
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.myInvitations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myInvitations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No invitations found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myInvitations.length,
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Club Invitation', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Club ID: ${invitation.clubId.substring(0, 8)}...'),
                    ],
                  ),
                ),
                _buildStatusBadge(invitation.status),
              ],
            ),
            const Divider(height: 24),
            Text('Role: ${invitation.role.name.toUpperCase()}'),
            const SizedBox(height: 16),
            if (invitation.status == InvitationStatus.pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => provider.declineInvitation(invitation.id),
                    child: const Text('Decline', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => provider.acceptInvitation(invitation.id),
                    child: const Text('Accept'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InvitationStatus status) {
    Color color;
    switch (status) {
      case InvitationStatus.pending: color = Colors.orange; break;
      case InvitationStatus.accepted: color = Colors.green; break;
      case InvitationStatus.declined: color = Colors.red; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
