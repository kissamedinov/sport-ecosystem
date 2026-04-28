import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/academies/providers/academy_provider.dart';
import 'package:mobile/features/academies/data/models/academy.dart';

class MyChildrenScreen extends StatefulWidget {
  const MyChildrenScreen({super.key});

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  List<dynamic>? _children;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      final children = await context.read<AuthProvider>().fetchMyChildren();
      setState(() {
        _children = children;
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
        title: const Text('MY CHILDREN', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PremiumCard(
                  onTap: () => _showAddChildOptions(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_rounded, color: PremiumTheme.neonGreen),
                      SizedBox(width: 12),
                      Text('ADD CHILD ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: (_children == null || _children!.isEmpty)
                  ? const Center(child: Text('No linked children', style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _children!.length,
                      itemBuilder: (context, index) {
                        final child = _children![index];
                        final bool isPending = child['status'] == 'PENDING';
                        final String? academyName = child['academy']?['name'];
                        
                        return PremiumCard(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: isPending ? Colors.orange.withOpacity(0.1) : Colors.white10, 
                                  child: Icon(Icons.face, color: isPending ? Colors.orange : Colors.white70)
                                ),
                                title: Text(child['full_name'] ?? child['name'] ?? 'Child Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  isPending 
                                    ? 'PENDING APPROVAL' 
                                    : (academyName ?? (child['date_of_birth'] != null ? 'DOB: ${child['date_of_birth']}' : 'NO ACADEMY')), 
                                  style: TextStyle(
                                    color: isPending ? Colors.orangeAccent : (academyName != null ? PremiumTheme.neonGreen : Colors.white38), 
                                    fontSize: 11
                                  )
                                ),
                                trailing: isPending 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                                  : Icon(Icons.verified_user, color: academyName != null ? PremiumTheme.neonGreen.withOpacity(0.5) : Colors.white10),
                              ),
                              if (!isPending && academyName == null) ...[
                                const Divider(color: Colors.white10),
                                TextButton.icon(
                                  onPressed: () => _showAcademySelector(context, child['player_profile_id']),
                                  icon: const Icon(Icons.add_business_rounded, size: 18, color: PremiumTheme.neonGreen),
                                  label: const Text('JOIN ACADEMY', style: TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }

  void _showAcademySelector(BuildContext context, String? playerProfileId) {
    if (playerProfileId == null) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _AcademyPicker(
        onSelected: (academy) async {
          final success = await context.read<AcademyProvider>().joinAcademyForPlayer(academy.id, playerProfileId);
          if (success && mounted) {
            Navigator.pop(context);
            _fetchChildren();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Join request sent to ${academy.name}'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
    );
  }

  void _showCreateChildDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final inviteCodeController = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CREATE CHILD ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextField(controller: firstNameController, decoration: PremiumTheme.inputDecorationOf(context, 'First Name'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: lastNameController, decoration: PremiumTheme.inputDecorationOf(context, 'Last Name'))),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(primary: PremiumTheme.neonGreen, onPrimary: Colors.black, surface: PremiumTheme.surfaceCard(context)),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) setModalState(() => selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedDate == null ? 'Select Date of Birth' : 'DOB: ${selectedDate!.toLocal().toString().split(' ')[0]}', 
                             style: TextStyle(color: selectedDate == null ? Colors.white38 : Colors.white)),
                        const Icon(Icons.calendar_today, color: PremiumTheme.neonGreen, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: PremiumTheme.inputDecorationOf(context, 'Child Email')),
                const SizedBox(height: 12),
                TextField(controller: passwordController, obscureText: true, decoration: PremiumTheme.inputDecorationOf(context, 'Child Password')),
                const SizedBox(height: 12),
                TextField(controller: inviteCodeController, decoration: PremiumTheme.inputDecorationOf(context, 'Academy Invite Code (Optional)')),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () async {
                      if (firstNameController.text.isEmpty || lastNameController.text.isEmpty || selectedDate == null || emailController.text.isEmpty || passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                        return;
                      }
                      
                      final success = await context.read<AuthProvider>().createChild(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        dob: selectedDate!,
                        email: emailController.text,
                        password: passwordController.text,
                        inviteCode: inviteCodeController.text.isEmpty ? null : inviteCodeController.text,
                      );
                      
                      if (success && mounted) {
                        Navigator.pop(context);
                        _fetchChildren();
                      }
                    },
                    child: const Text('CREATE ACCOUNT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showAddChildOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PremiumTheme.surfaceCard(context),
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
                _showCreateChildDialog(context);
              },
            ),
            const Divider(color: Colors.white10, height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: PremiumTheme.neonGreen.withOpacity(0.2), child: const Icon(Icons.link, color: PremiumTheme.neonGreen)),
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
        backgroundColor: PremiumTheme.surfaceCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Link Child by Email', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          decoration: PremiumTheme.inputDecorationOf(context, 'Child\'s Email Address'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final success = await context.read<AuthProvider>().linkChildByEmail(controller.text.trim());
                if (success && mounted) {
                  Navigator.pop(context);
                  _fetchChildren();
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

class _AcademyPicker extends StatefulWidget {
  final Function(Academy) onSelected;
  const _AcademyPicker({required this.onSelected});

  @override
  State<_AcademyPicker> createState() => _AcademyPickerState();
}

class _AcademyPickerState extends State<_AcademyPicker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Just for UI demo, assuming they are already fetched or fetch them now
    });
  }

  @override
  Widget build(BuildContext context) {
    final academies = context.watch<AcademyProvider>().academies;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SELECT ACADEMY', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (academies.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No academies found', style: TextStyle(color: Colors.white38)))),
          ...academies.map((a) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.business, color: PremiumTheme.neonGreen),
            title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text(a.city, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            onTap: () => widget.onSelected(a),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
