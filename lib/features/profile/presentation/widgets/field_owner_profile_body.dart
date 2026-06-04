import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/fields/providers/booking_provider.dart';
import 'package:mobile/features/fields/data/models/field.dart';
import 'package:mobile/features/fields/data/models/booking.dart';

class FieldOwnerProfileBody extends StatefulWidget {
  const FieldOwnerProfileBody({super.key});

  @override
  State<FieldOwnerProfileBody> createState() => _FieldOwnerProfileBodyState();
}

class _FieldOwnerProfileBodyState extends State<FieldOwnerProfileBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BookingProvider>();
      provider.fetchFields();
      provider.fetchMyBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.fields.isEmpty) {
          return _buildLoadingState();
        }

        final userId = context.read<AuthProvider>().user?.id ?? '';
        final myFields = provider.fields.where((f) => f.ownerId == userId).toList();
        final myBookings = provider.myBookings;

        final activeBookings = myBookings.where((b) => b.status != 'CANCELLED').length;
        final revenue = myBookings
            .where((b) => b.status != 'CANCELLED')
            .fold(0.0, (sum, b) => sum + b.totalPrice);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionLabel('profile.overview'.tr()),
              const SizedBox(height: 12),
              _buildStatsRow(myFields.length, activeBookings, revenue),
              const SizedBox(height: 28),

              _buildSectionLabel('profile.my_fields'.tr()),
              const SizedBox(height: 12),
              _buildFieldsList(myFields),
              const SizedBox(height: 28),

              _buildSectionLabel('profile.recent_bookings'.tr()),
              const SizedBox(height: 12),
              _buildBookingsList(myBookings),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            const CircularProgressIndicator(color: PremiumTheme.neonGreen, strokeWidth: 2),
            const SizedBox(height: 20),
            Text(
              'profile.syncing'.tr(),
              style: TextStyle(
                color: PremiumTheme.neonGreen.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: PremiumTheme.neonGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(int fieldCount, int bookingCount, double revenue) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PremiumStatCard(
                title: 'profile.my_fields'.tr(),
                value: "$fieldCount",
                icon: Icons.stadium_rounded,
                color: PremiumTheme.neonGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PremiumStatCard(
                title: 'field.my_bookings'.tr(),
                value: "$bookingCount",
                icon: Icons.event_available_rounded,
                color: PremiumTheme.electricBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PremiumStatCard(
          title: 'profile.total_revenue'.tr(),
          value: "${revenue.toStringAsFixed(0)} ₸",
          icon: Icons.payments_rounded,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildFieldsList(List<Field> fields) {
    if (fields.isEmpty) {
      return _buildEmptyCard('profile.no_fields'.tr(), Icons.stadium_outlined);
    }

    return Column(
      children: fields.map((field) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.name.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            field.location,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'profile.active_status'.tr(),
                  style: const TextStyle(
                    color: PremiumTheme.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyCard('profile.no_bookings'.tr(), Icons.event_busy_rounded);
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final displayed = bookings.length > 5 ? bookings.take(5).toList() : bookings;

    return Column(
      children: displayed.map((booking) {
        final isCancelled = booking.status == 'CANCELLED';
        final statusColor = isCancelled
            ? Colors.redAccent
            : booking.status == 'CONFIRMED'
                ? PremiumTheme.neonGreen
                : Colors.orangeAccent;
        final date = booking.startTime.length >= 10 ? booking.startTime.substring(0, 10) : 'TBD';
        final startH = booking.startTime.length >= 16 ? booking.startTime.substring(11, 16) : '';
        final endH = booking.endTime.length >= 16 ? booking.endTime.substring(11, 16) : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PremiumCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_rounded, color: statusColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.booking_num'.tr(namedArgs: {'id': booking.id.length >= 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase()}),
                        style: TextStyle(
                          color: onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$date  $startH–$endH',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.totalPrice.toStringAsFixed(0)} ₸',
                      style: TextStyle(
                        color: onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: muted.withValues(alpha: 0.4), size: 32),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
