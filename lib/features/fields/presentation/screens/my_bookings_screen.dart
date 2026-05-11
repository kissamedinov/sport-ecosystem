import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: const Text('MY BOOKINGS', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 14)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.myBookings.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: PremiumTheme.neonGreen));
          }

          if (provider.myBookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('No active bookings', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.myBookings.length,
            itemBuilder: (context, index) {
              final booking = provider.myBookings[index];
              final isCancelled = booking.status == 'CANCELLED';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PremiumCard(
                  child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isCancelled ? Colors.grey : PremiumTheme.neonGreen).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.stadium_outlined, 
                            color: isCancelled ? Colors.grey : PremiumTheme.neonGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Field Booking #${booking.id.substring(0, 8)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                booking.status.toUpperCase(),
                                style: TextStyle(
                                  color: isCancelled ? Colors.red : PremiumTheme.neonGreen,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.calendar_today, 'Date', booking.startTime.split('T').first),
                    _buildInfoRow(Icons.access_time, 'Time', '${booking.startTime.split('T').last.substring(0, 5)} - ${booking.endTime.split('T').last.substring(0, 5)}'),
                    if (!isCancelled) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(context, booking.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: PremiumTheme.danger),
                            foregroundColor: PremiumTheme.danger,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('CANCEL BOOKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PremiumTheme.surfaceBase(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('CANCEL BOOKING?', style: TextStyle(color: Colors.white)),
        content: const Text('This action will release the time slot for others.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KEEP IT')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<BookingProvider>().cancelBooking(bookingId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: PremiumTheme.danger),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );
  }
}
