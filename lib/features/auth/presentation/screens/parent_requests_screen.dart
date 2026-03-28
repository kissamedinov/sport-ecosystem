import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';

class ParentRequestsScreen extends StatefulWidget {
  const ParentRequestsScreen({super.key});

  @override
  State<ParentRequestsScreen> createState() => _ParentRequestsScreenState();
}

class _ParentRequestsScreenState extends State<ParentRequestsScreen> {
  List<dynamic>? _requests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final requests = await context.read<AuthProvider>().getParentRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PARENT REQUESTS', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_requests == null || _requests!.isEmpty)
          ? const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white38)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests!.length,
              itemBuilder: (context, index) {
                final req = _requests![index];
                return PremiumCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person_add, color: Colors.white),
                    ),
                    title: Text(req['parent_name'] ?? 'Parent Request', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Wants to link as your guardian', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded, color: PremiumTheme.neonGreen),
                          onPressed: () => _handleRequest(req['id'], true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent),
                          onPressed: () => _handleRequest(req['id'], false),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    _isLoading = true;
    setState(() {});
    
    final success = accept 
      ? await context.read<AuthProvider>().acceptRequest(requestId)
      : await context.read<AuthProvider>().rejectRequest(requestId);
      
    if (success) {
      _fetchRequests();
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process request'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
