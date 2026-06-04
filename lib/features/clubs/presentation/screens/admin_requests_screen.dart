import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/club_provider.dart';
import '../../data/models/club_request.dart';

class AdminClubRequestsScreen extends StatefulWidget {
  const AdminClubRequestsScreen({super.key});

  @override
  State<AdminClubRequestsScreen> createState() => _AdminClubRequestsScreenState();
}

class _AdminClubRequestsScreenState extends State<AdminClubRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClubProvider>().fetchAllClubRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('club.moderation'.tr())),
      body: Consumer<ClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.clubRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.clubRequests.isEmpty) {
            return Center(child: Text('club.no_requests'.tr()));
          }

          return ListView.builder(
            itemCount: provider.clubRequests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final request = provider.clubRequests[index];
              return Card(
                child: ExpansionTile(
                  title: Text(request.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${request.city} | ${'common.status'.tr()}: ${request.status.name.toUpperCase()}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${'common.address'.tr()}: ${request.address}'),
                          Text('${'admin.created_by'.tr()}: ${request.createdBy.substring(0, 8)}...'),
                          if (request.status == RequestStatus.pending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => provider.approveClubRequest(request.id),
                                  child: Text('admin.approve'.tr(), style: const TextStyle(color: Colors.green)),
                                ),
                                TextButton(
                                  onPressed: () => provider.rejectClubRequest(request.id.toString()),
                                  child: Text('admin.reject'.tr(), style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
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
