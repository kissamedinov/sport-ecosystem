import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile/core/theme/premium_theme.dart';
import 'package:mobile/core/presentation/widgets/premium_widgets.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/features/fields/providers/booking_provider.dart';
import 'package:mobile/features/fields/data/models/field.dart';
import 'package:mobile/features/fields/data/models/booking.dart';
import 'package:mobile/features/fields/data/field_pricing_manager.dart';

class FieldOwnerProfileBody extends StatefulWidget {
  const FieldOwnerProfileBody({super.key});

  @override
  State<FieldOwnerProfileBody> createState() => _FieldOwnerProfileBodyState();
}

class _FieldOwnerProfileBodyState extends State<FieldOwnerProfileBody> {
  // Local state for interactive additions since database changes are simulated
  final List<Field> _newFields = [];
  List<Map<String, dynamic>> get _promoCodes => FieldPricingManager().promoCodes;

  // Dynamic pricing rule toggles
  bool _primeTimeSurcharge = true;
  bool _weekendSurcharge = true;
  bool _nightOwlDiscount = true;

  // Local set of canceled booking IDs
  final Set<String> _canceledBookingIds = {};

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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BookingProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.fields.isEmpty) {
          return _buildLoadingState();
        }

        final userId = context.read<AuthProvider>().user?.id ?? '';
        final myFields = provider.fields.where((f) => f.ownerId == userId).toList();
        
        // Combine loaded fields with newly registered fields
        final List<Field> allFields = [...myFields, ..._newFields];
        final fieldIds = allFields.map((f) => f.id).toSet();

        // Get bookings matching owner's fields
        final myBookings = provider.myBookings.where((b) => fieldIds.contains(b.fieldId)).toList();
        
        // Filter out canceled bookings
        final activeBookings = myBookings
            .where((b) => b.status != 'CANCELLED' && !_canceledBookingIds.contains(b.id))
            .toList();

        final revenue = activeBookings.fold(0.0, (sum, b) => sum + b.totalPrice);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Stats Cards
              _buildStatsRow(allFields.length, activeBookings.length, revenue),
              const SizedBox(height: 28),

              // Dynamic Pricing panel
              _buildSectionHeader('profile.dynamic_pricing'.tr().toUpperCase(), null),
              const SizedBox(height: 12),
              _buildPricingControlsCard(cs, isDark),
              const SizedBox(height: 28),

              // Fields panel
              _buildSectionHeader(
                'profile.my_fields'.tr(),
                () => _showRegisterFieldSheet(context, userId),
                actionLabel: '+ ${'profile.register_field'.tr().toUpperCase()}',
              ),
              const SizedBox(height: 12),
              _buildFieldsList(allFields),
              const SizedBox(height: 28),

              // Promo codes panel
              _buildSectionHeader(
                'profile.promo_codes'.tr().toUpperCase(),
                () => _showCreatePromoSheet(context),
                actionLabel: '+ ${'profile.create_code'.tr().toUpperCase()}',
              ),
              const SizedBox(height: 12),
              _buildPromoCodesList(cs, isDark),
              const SizedBox(height: 28),

              // Bookings panel
              _buildSectionHeader('profile.recent_bookings'.tr().toUpperCase(), null),
              const SizedBox(height: 12),
              _buildBookingsList(myBookings, allFields, cs, isDark),
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

  Widget _buildSectionHeader(String title, VoidCallback? onAction, {String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel ?? 'ADD',
              style: const TextStyle(
                color: PremiumTheme.neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
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
            Expanded(child: _buildStatCard(title: 'profile.my_fields'.tr(), value: '$fieldCount', icon: Icons.stadium_rounded, color: PremiumTheme.neonGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(title: 'field.my_bookings'.tr(), value: '$bookingCount', icon: Icons.event_available_rounded, color: PremiumTheme.electricBlue)),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(title: 'profile.total_revenue'.tr(), value: "${(revenue / 1000).toStringAsFixed(1)}k ₸", icon: Icons.payments_rounded, color: Colors.amber),
      ],
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 8)],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPricingControlsCard(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          _buildPricingToggleRow(
            icon: Icons.whatshot_rounded,
            color: const Color(0xFFFF9800),
            title: 'profile.prime_time_surcharge'.tr(),
            subtitle: 'profile.prime_time_surcharge_desc'.tr(),
            value: _primeTimeSurcharge,
            onChanged: (val) {
              setState(() => _primeTimeSurcharge = val);
              _showRuleUpdatedSnackbar('profile.prime_time_surcharge'.tr(), val);
            },
          ),
          Divider(height: 24, color: cs.onSurface.withValues(alpha: 0.08)),
          _buildPricingToggleRow(
            icon: Icons.celebration_rounded,
            color: const Color(0xFF2196F3),
            title: 'profile.weekend_surcharge'.tr(),
            subtitle: 'profile.weekend_surcharge_desc'.tr(),
            value: _weekendSurcharge,
            onChanged: (val) {
              setState(() => _weekendSurcharge = val);
              _showRuleUpdatedSnackbar('profile.weekend_surcharge'.tr(), val);
            },
          ),
          Divider(height: 24, color: cs.onSurface.withValues(alpha: 0.08)),
          _buildPricingToggleRow(
            icon: Icons.nights_stay_rounded,
            color: const Color(0xFF9C27B0),
            title: 'profile.night_owl_discount'.tr(),
            subtitle: 'profile.night_owl_discount_desc'.tr(),
            value: _nightOwlDiscount,
            onChanged: (val) {
              setState(() => _nightOwlDiscount = val);
              _showRuleUpdatedSnackbar('profile.night_owl_discount'.tr(), val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingToggleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 10),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: PremiumTheme.neonGreen,
          activeTrackColor: PremiumTheme.neonGreen.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildFieldsList(List<Field> fields) {
    if (fields.isEmpty) {
      return _buildEmptyCard('profile.no_fields'.tr(), Icons.stadium_outlined);
    }

    return Column(
      children: fields.map((field) {
        // Find base rate for fields based on name
        int baseRate = 15000;
        if (field.name.contains('SPORT')) baseRate = 12000;
        if (field.name.contains('ASTANA')) baseRate = 25000;
        if (field.name.contains('DUMAN')) baseRate = 10000;
        if (field.name.contains('QAZAQSTAN')) baseRate = 20000;

        final fieldCs = Theme.of(context).colorScheme;
        final fieldIsDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fieldIsDark ? const Color(0xFF161B22) : fieldCs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.22)),
              boxShadow: [BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: PremiumTheme.neonGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.2)),
                    boxShadow: [BoxShadow(color: PremiumTheme.neonGreen.withValues(alpha: 0.2), blurRadius: 8)],
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
                          color: fieldCs.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: fieldCs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              field.location,
                              style: TextStyle(
                                color: fieldCs.onSurfaceVariant.withValues(alpha: 0.7),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'field.status_active'.tr().toUpperCase(),
                        style: const TextStyle(
                          color: PremiumTheme.neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'field.base_rate_label'.tr(namedArgs: {'rate': '$baseRate'}),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fieldCs.onSurfaceVariant),
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

  Widget _buildPromoCodesList(ColorScheme cs, bool isDark) {
    if (_promoCodes.isEmpty) {
      return _buildEmptyCard('profile.no_promo_codes'.tr(), Icons.discount_rounded);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.75,
      ),
      itemCount: _promoCodes.length,
      itemBuilder: (context, index) {
        final promo = _promoCodes[index];
        final code = promo['code'] as String;
        final discount = promo['discount'] as int;
        final uses = promo['uses'] as String;
        final status = promo['status'] as String;
        final expiry = promo['expiry'] as String;
        final isActive = status == 'ACTIVE';

        final promoIsDark = Theme.of(context).brightness == Brightness.dark;
        final promoColor = isActive ? PremiumTheme.neonGreen : Colors.redAccent;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: promoIsDark ? const Color(0xFF161B22) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: promoColor.withValues(alpha: 0.25)),
            boxShadow: [BoxShadow(color: promoColor.withValues(alpha: 0.07), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? PremiumTheme.neonGreen.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isActive ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : Colors.transparent),
                    ),
                    child: Text(
                      code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isActive ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isActive ? 'field.status_active'.tr() : status,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'field.discount_percent_label'.tr(namedArgs: {'percent': '$discount'}),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'field.expiry_label'.tr(namedArgs: {'date': expiry}),
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 8),
                  ),
                  Text(
                    'field.uses_count'.tr(namedArgs: {'count': uses}),
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, List<Field> allFields, ColorScheme cs, bool isDark) {
    if (bookings.isEmpty) {
      return _buildEmptyCard('profile.no_recent_bookings'.tr(), Icons.event_busy_rounded);
    }

    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    
    // Sort bookings: active first, then by date descending
    final sortedBookings = List<Booking>.from(bookings)
      ..sort((a, b) {
        final aCanceled = a.status == 'CANCELLED' || _canceledBookingIds.contains(a.id);
        final bCanceled = b.status == 'CANCELLED' || _canceledBookingIds.contains(b.id);
        if (aCanceled && !bCanceled) return 1;
        if (!aCanceled && bCanceled) return -1;
        return b.startTime.compareTo(a.startTime);
      });

    return Column(
      children: sortedBookings.map((booking) {
        final isLocalCanceled = _canceledBookingIds.contains(booking.id);
        final isCancelled = booking.status == 'CANCELLED' || isLocalCanceled;
        
        final statusColor = isCancelled
            ? Colors.redAccent
            : booking.status == 'CONFIRMED'
                ? PremiumTheme.neonGreen
                : Colors.orangeAccent;
        
        final date = booking.startTime.length >= 10 ? booking.startTime.substring(0, 10) : 'TBD';
        final startH = booking.startTime.length >= 16 ? booking.startTime.substring(11, 16) : '';
        final endH = booking.endTime.length >= 16 ? booking.endTime.substring(11, 16) : '';

        // Find associated field
        final field = allFields.firstWhere((f) => f.id == booking.fieldId, 
            orElse: () => Field(id: '', name: 'Unknown Arena', location: '', ownerId: ''));

        // Client mock details
        final clientName = _getMockClientName(booking.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => _showBookingDetailsDialog(context, booking, field, clientName, isCancelled),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161B22) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.22)),
                boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sports_soccer_rounded, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: TextStyle(
                            color: onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          field.name,
                          style: TextStyle(
                            color: muted.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$date @ $startH–$endH',
                          style: TextStyle(
                            color: muted.withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isCancelled ? 'CANCELLED' : booking.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${booking.totalPrice.toInt()} ₸',
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyCard(String message, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: muted.withValues(alpha: 0.3), size: 30),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              style: TextStyle(
                color: muted.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showRegisterFieldSheet(BuildContext context, String ownerId) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final priceController = TextEditingController();
    String fieldSize = '6x6';
    String surfaceType = 'Artificial Turf';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'field.register_new_field'.tr().toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name input
                  _buildTextField('field.field_name_label'.tr(), nameController, "e.g. Turkestan Arena", TextInputType.text),
                  const SizedBox(height: 12),

                  // Location input
                  _buildTextField('field.location_address'.tr(), addressController, "e.g. Turan Ave 10, Astana", TextInputType.text),
                  const SizedBox(height: 12),

                  // Price input
                  _buildTextField('field.base_hourly_rent'.tr(), priceController, "e.g. 15000", TextInputType.number),
                  const SizedBox(height: 16),

                  // Field Size Chips
                  Text('field.field_size_format'.tr().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['5x5', '6x6', '7x7', '11x11'].map((size) {
                      final isSelected = fieldSize == size;
                      return GestureDetector(
                        onTap: () => setModalState(() => fieldSize = size),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Colors.black : cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Surface Type Chips
                  Text('field.surface_type_label'.tr().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Artificial Turf', 'Natural Grass', 'Hybrid Pro'].map((type) {
                      final isSelected = surfaceType == type;
                      return GestureDetector(
                        onTap: () => setModalState(() => surfaceType = type),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.black : cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  PremiumButton(
                    text: 'profile.register_field'.tr().toUpperCase(),
                    onPressed: () {
                      if (nameController.text.trim().isEmpty || 
                          addressController.text.trim().isEmpty || 
                          priceController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please complete all inputs to register fields.")),
                        );
                        return;
                      }


                      final newFieldObj = Field(
                        id: 'field-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        location: addressController.text.trim(),
                        ownerId: ownerId,
                      );

                      setState(() {
                        _newFields.add(newFieldObj);
                      });

                      Navigator.pop(context);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("Field '${newFieldObj.name}' registered successfully!"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatePromoSheet(BuildContext context) {
    final codeController = TextEditingController();
    double discountPercent = 10;
    int maxUses = 50;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'field.create_new_promo'.tr().toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField('field.promo_code_hint'.tr(), codeController, "e.g. CHAMP15", TextInputType.text),
                  const SizedBox(height: 16),

                  Text(
                    'field.discount_percentage'.tr(namedArgs: {'percent': '${discountPercent.toInt()}'}).toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                  ),
                  Slider(
                    value: discountPercent,
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: '${discountPercent.toInt()}%',
                    activeColor: PremiumTheme.neonGreen,
                    onChanged: (val) {
                      setModalState(() {
                        discountPercent = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'field.max_usage_count'.tr().toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [20, 50, 100, 200].map((uses) {
                      final isSelected = maxUses == uses;
                      return GestureDetector(
                        onTap: () => setModalState(() => maxUses = uses),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? PremiumTheme.neonGreen : cs.onSurface.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$uses',
                            style: TextStyle(
                              color: isSelected ? Colors.black : cs.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  PremiumButton(
                    text: 'field.create_promo_code_btn'.tr().toUpperCase(),
                    onPressed: () {
                      if (codeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please type a promo code string.")),
                        );
                        return;
                      }

                      final finalCode = codeController.text.trim().toUpperCase();

                      setState(() {
                        _promoCodes.insert(0, {
                          'code': finalCode,
                          'discount': discountPercent.toInt(),
                          'uses': '0/$maxUses',
                          'status': 'ACTIVE',
                          'expiry': '30 Jun 2026',
                        });
                      });
                      FieldPricingManager().notify();

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("Promo Code '$finalCode' created successfully!"),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBookingDetailsDialog(
    BuildContext context, 
    Booking booking, 
    Field field, 
    String clientName,
    bool isCancelled,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'BOOKING DETAILS',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Colors.white10),
                _buildDialogRow('Invoice ID', 'TX-${booking.id.toUpperCase().substring(0, 8)}'),
                _buildDialogRow('Client Name', clientName),
                _buildDialogRow('Field Arena', field.name),
                _buildDialogRow('Start Time', booking.startTime.replaceAll('T', ' ')),
                _buildDialogRow('End Time', booking.endTime.replaceAll('T', ' ')),
                _buildDialogRow('Payment Total', '${booking.totalPrice.toInt()} ₸'),
                _buildDialogRow('Status', isCancelled ? 'CANCELLED' : booking.status.toUpperCase(), 
                    color: isCancelled ? Colors.redAccent : PremiumTheme.neonGreen),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (!isCancelled) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _canceledBookingIds.add(booking.id);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text("Booking for '$clientName' canceled and refunded successfully."),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            ),
                          ),
                          child: const Text(
                            'REFUND / CANCEL',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? cs.onSurface)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder, TextInputType keyboardType) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.3), fontSize: 12),
            filled: true,
            fillColor: cs.onSurface.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _showRuleUpdatedSnackbar(String ruleName, bool enabled) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: enabled ? Colors.green : Colors.grey.shade800,
        content: Text(
          enabled 
              ? "Rule '$ruleName' activated successfully." 
              : "Rule '$ruleName' deactivated.",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getMockClientName(String id) {
    final names = [
      'Dias Kasimov',
      'Olzhas Smakov',
      'Alisher Karim',
      'Daniyar Nurlan',
      'Kairat Uspanov',
      'Timur Boranbay',
      'Sanzhar Kenes',
      'Madiyar Sadu'
    ];
    // Return deterministic client name based on hash code of ID
    final index = id.hashCode.abs() % names.length;
    return names[index];
  }
}
