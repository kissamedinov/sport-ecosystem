import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class FieldManagementScreen extends StatefulWidget {
  const FieldManagementScreen({super.key});

  @override
  State<FieldManagementScreen> createState() => _FieldManagementScreenState();
}

class _FieldManagementScreenState extends State<FieldManagementScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: const Text('FIELD MANAGEMENT', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatGrid(),
            const SizedBox(height: 32),
            _buildSectionTitle('OPERATIONS'),
            const SizedBox(height: 12),
            _buildActionCard(
              context, 
              'Booking Requests', 
              'Review and approve pending reservations', 
              Icons.book_online,
              PremiumTheme.neonGreen,
              () {},
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context, 
              'Batch Slot Generation', 
              'Automatically create time slots for a day', 
              Icons.auto_awesome,
              PremiumTheme.electricBlue,
              () => _showGenerateSlotsDialog(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context, 
              'Manual Availability', 
              'Block specific hours or adjust pricing', 
              Icons.timer_outlined,
              Colors.orange,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  Widget _buildStatGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildStatItem('Today Revenue', '25,000 ₸', Colors.green),
        _buildStatItem('Occupancy', '85%', Colors.blue),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: onTap,
      ),
    );
  }

  void _showGenerateSlotsDialog(BuildContext context) {
    final priceController = TextEditingController(text: '15000');
    final startHourController = TextEditingController(text: '9');
    final endHourController = TextEditingController(text: '22');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceBase(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text('GENERATE SLOTS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Setup your field availability for a full day.', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: startHourController,
              decoration: const InputDecoration(labelText: 'Start Hour (0-23)', labelStyle: TextStyle(color: Colors.white38)),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: endHourController,
              decoration: const InputDecoration(labelText: 'End Hour (1-24)', labelStyle: TextStyle(color: Colors.white38)),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per slot (₸)', labelStyle: TextStyle(color: Colors.white38)),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<BookingProvider>();
              // Use a dummy field ID for now or fetch it from a selection
              const dummyFieldId = '00000000-0000-0000-0000-000000000000'; 
              
              final success = await provider.generateFieldSlots(dummyFieldId, {
                'date': selectedDate.toIso8601String(),
                'start_hour': int.parse(startHourController.text),
                'end_hour': int.parse(endHourController.text),
                'price': double.parse(priceController.text),
                'slot_duration_minutes': 60,
              });

              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slots generated successfully!')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.neonGreen, foregroundColor: Colors.black),
            child: const Text('GENERATE'),
          ),
        ],
      ),
    );
  }
}
