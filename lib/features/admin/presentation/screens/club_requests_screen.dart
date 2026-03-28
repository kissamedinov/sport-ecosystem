import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/admin/providers/admin_provider.dart';

class ClubRequestsScreen extends StatefulWidget {
  const ClubRequestsScreen({super.key});

  @override
  State<ClubRequestsScreen> createState() => _ClubRequestsScreenState();
}

class _ClubRequestsScreenState extends State<ClubRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AdminProvider>().fetchClubRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('CLUB REGISTRACTIONS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));
          
          final requests = provider.requests;
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final status = req['status'] ?? 'PENDING';
              
              return PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req['name'] ?? 'Unknown Club', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'PENDING' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(status, style: TextStyle(color: status == 'PENDING' ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Owner ID: ${req['owner_id']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('Location: ${req['city']}, ${req['address']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    if (status == 'PENDING') ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => provider.approveRequest(req['id']),
                              style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
                              child: const Text('APPROVE'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => provider.rejectRequest(req['id']),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), foregroundColor: Colors.redAccent),
                              child: const Text('REJECT'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
