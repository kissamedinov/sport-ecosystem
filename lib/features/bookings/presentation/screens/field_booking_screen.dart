import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../providers/booking_provider.dart';
import '../../data/models/booking_models.dart';

class FieldBookingScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const FieldBookingScreen({
    super.key,
    required this.fieldId,
    required this.fieldName,
  });

  @override
  State<FieldBookingScreen> createState() => _FieldBookingScreenState();
}

class _FieldBookingScreenState extends State<FieldBookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      context.read<BookingProvider>().fetchSlots(widget.fieldId, _selectedDate)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('BOOK ${widget.fieldName.toUpperCase()}', 
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.error != null) return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red)));

          final slots = provider.slots;

          return Column(
            children: [
              _buildDatePicker(),
              Expanded(
                child: slots.isEmpty 
                  ? const Center(child: Text('No slots available for this date', style: TextStyle(color: Colors.white38)))
                  : _buildSlotsGrid(slots),
              ),
              if (_selectedSlotId != null) _buildBookingBar(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedSlotId = null;
              });
              context.read<BookingProvider>().fetchSlots(widget.fieldId, date);
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? PremiumTheme.neonGreen : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'][date.weekday % 7],
                    style: TextStyle(color: isSelected ? Colors.black : Colors.white38, fontSize: 10)),
                  Text(date.day.toString(),
                    style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsGrid(List<FieldSlot> slots) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedSlotId == slot.id;
        final isAvailable = slot.isAvailable;

        return GestureDetector(
          onTap: isAvailable ? () => setState(() => _selectedSlotId = slot.id) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected 
                ? PremiumTheme.neonGreen.withOpacity(0.2) 
                : (isAvailable ? Colors.white.withOpacity(0.05) : Colors.red.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? PremiumTheme.neonGreen : Colors.transparent,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${slot.startTime} - ${slot.endTime}',
              style: TextStyle(
                color: isAvailable ? Colors.white : Colors.white24,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingBar(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PremiumTheme.cardNavy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(color: Colors.white70)),
                Text('5,000 ₸', style: TextStyle(color: PremiumTheme.neonGreen, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final success = await provider.confirmBooking(_selectedSlotId!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking Confirmed!'))
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumTheme.neonGreen,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CONFIRM BOOKING', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
