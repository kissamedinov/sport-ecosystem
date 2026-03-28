import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/child_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:mobile/features/children/presentation/screens/child_management_screen.dart';
import 'add_child_screen.dart';

class ChildListScreen extends StatefulWidget {
  const ChildListScreen({super.key});

  @override
  State<ChildListScreen> createState() => _ChildListScreenState();
}

class _ChildListScreenState extends State<ChildListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildProvider>().fetchChildren();
    });
  }

  @override
  Widget build(BuildContext context) {
    final childProvider = context.watch<ChildProvider>();
    final children = childProvider.children;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Child',
            onPressed: () => _showAddChildOptions(context),
          ),
        ],
      ),
      body: childProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : children.isEmpty
              ? const Center(child: Text('No children added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChildManagementScreen(
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  child.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Age ${child.age} • ${child.teamName}',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAddChildOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADD CHILD', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5, fontSize: 16)),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person_add, color: Colors.white)),
              title: const Text('Create New Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Completely register a new child', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddChildScreen()));
              },
            ),
            const Divider(color: Colors.white10, height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: Colors.greenAccent.withOpacity(0.2), child: const Icon(Icons.link, color: Colors.greenAccent)),
              title: const Text('Link Existing Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('Link a child who is already registered', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showLinkChildByEmailDialog(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLinkChildByEmailDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Link Child by Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Child\'s Email Address',
            labelStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                // We use AuthProvider to trigger the link logic because it contains the new endpoint logic
                // Provide AuthProvider by importing if necessary, or assuming it's higher up in context
                final success = await context.read<AuthProvider>().linkChildByEmail(controller.text.trim());
                if (success && mounted) {
                  Navigator.pop(context);
                  context.read<ChildProvider>().fetchChildren();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link request sent successfully!'), behavior: SnackBarBehavior.floating),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.read<AuthProvider>().error ?? 'Failed to send link request'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('SEND REQUEST', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
