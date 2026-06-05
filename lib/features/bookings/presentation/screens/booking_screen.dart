import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/premium_theme.dart';
import '../../../../core/presentation/widgets/premium_widgets.dart';
import '../../../fields/data/field_pricing_manager.dart';
import '../../../../core/api/api_client.dart';
import '../../../fields/data/models/field.dart';
import '../../../fields/data/repositories/field_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/models/booking_models.dart' as model_bookings;
import '../../data/models/booking_models.dart' show FieldSlot;

// === INTEGRATION CONFIGURATION TEMPLATE ===
// Fill in these credentials once you receive them from Kaspi Pay and Stripe.
class PaymentConfig {
  // Kaspi Pay (Kazakhstan standard QR & invoice payments)
  static const String kaspiMerchantId = "YOUR_KASPI_MERCHANT_ID";
  static const String kaspiServiceId = "YOUR_KASPI_SERVICE_ID";
  static const String kaspiSecretToken = "YOUR_KASPI_SECRET_TOKEN";
  static const String kaspiApiUrl = "https://partner.kaspipay.kz/api/v1/invoices";

  // Stripe Payments (International cards & Apple Pay)
  static const String stripePublishableKey = "pk_test_YOUR_STRIPE_KEY";
  static const String stripeSecretKey = "sk_test_YOUR_STRIPE_SECRET_KEY";
}

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _showMap = false;
  Map<String, dynamic>? _selectedArena;
  bool _isLoadingFields = true;
  List<Field> _backendFields = [];

  late final VoidCallback _pricingListener;

  @override
  void initState() {
    super.initState();
    _pricingListener = () {
      if (mounted) {
        setState(() {});
      }
    };
    FieldPricingManager().addListener(_pricingListener);
    _loadFieldsFromBackend();
  }

  Future<void> _loadFieldsFromBackend() async {
    try {
      final fields = await FieldRepository(ApiClient()).getFields();
      if (mounted) {
        setState(() {
          _backendFields = fields;
          
          // Map backend IDs to local arenas based on name matching
          for (var arena in _arenas) {
            final match = _backendFields.firstWhere(
              (f) => f.name.toUpperCase() == (arena['name'] as String).toUpperCase(),
              orElse: () => Field(id: '', name: '', location: '', ownerId: ''),
            );
            if (match.id.isNotEmpty) {
              arena['id'] = match.id;
            }
          }
          _isLoadingFields = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
      print("Error loading fields from backend: $e");
    }
  }

  @override
  void dispose() {
    FieldPricingManager().removeListener(_pricingListener);
    super.dispose();
  }

  final List<Map<String, dynamic>> _arenas = [
    {
      'name': 'SAIRAN ARENA',
      'type': 'Indoor & Outdoor / 6x6',
      'price': 15000,
      'surface': 'Artificial Turf',
      'hours': '18:00 - 22:00',
      'lat': 51.1345,
      'lng': 71.4082,
      'address': 'Turan Ave 48, Astana',
    },
    {
      'name': 'SPORT CITY PITCHES',
      'type': 'Indoor / 5x5',
      'price': 12000,
      'surface': 'Artificial Turf',
      'hours': '10:00 - 00:00',
      'lat': 51.1118,
      'lng': 71.4328,
      'address': 'Kabanbay Batyr Ave 47, Astana',
    },
    {
      'name': 'ASTANA ARENA',
      'type': 'Stadium & Training / 11x11',
      'price': 25000,
      'surface': 'Hybrid Pro',
      'hours': '08:00 - 23:00',
      'lat': 51.1077,
      'lng': 71.4038,
      'address': 'Kabanbay Batyr Ave 33, Astana',
    },
    {
      'name': 'DUMAN SPORT COMPLEX',
      'type': 'Covered Arena / 5x5',
      'price': 10000,
      'surface': 'Rubber Multi',
      'hours': '12:00 - 22:00',
      'lat': 51.1502,
      'lng': 71.4116,
      'address': 'Kurgalzhyn Highway 2, Astana',
    },
    {
      'name': 'QAZAQSTAN ATHLETIC COMPLEX',
      'type': 'Covered Pro / 7x7',
      'price': 20000,
      'surface': 'Natural Grass',
      'hours': '09:00 - 21:00',
      'lat': 51.1132,
      'lng': 71.4005,
      'address': 'Turan Ave 59, Astana',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: PremiumTheme.surfaceBase(context),
      appBar: AppBar(
        title: Text(
          'field.book_field'.tr(),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_rounded),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
                if (!_showMap) {
                  _selectedArena = null;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _showMap ? _buildMapView(cs, isDark) : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _arenas.length,
      itemBuilder: (context, index) {
        return _buildArenaCard(_arenas[index]);
      },
    );
  }

  Widget _buildMapView(ColorScheme cs, bool isDark) {
    return Stack(
      children: [
        // Astana Map view
        FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(51.1282, 71.4184), // Centered on Astana
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', // Custom Premium Dark Mode Map
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            MarkerLayer(
              markers: _arenas.map((arena) {
                final isSelected = _selectedArena == arena;
                return Marker(
                  point: LatLng(arena['lat'] as double, arena['lng'] as double),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedArena = arena;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? PremiumTheme.neonGreen : const Color(0xFF161B22),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : PremiumTheme.neonGreen.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? PremiumTheme.neonShadow(color: PremiumTheme.neonGreen, opacity: 0.4)
                            : [
                                const BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                      ),
                      child: Icon(
                        Icons.sports_soccer_rounded,
                        color: isSelected ? Colors.black : PremiumTheme.neonGreen,
                        size: 22,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // Floating info card of selected field
        if (_selectedArena != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PremiumTheme.neonGreen.withValues(alpha: 0.3), width: 1.5),
                boxShadow: PremiumTheme.softShadowOf(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedArena!['name'],
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedArena!['address'],
                              style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedArena!['price']} ₸',
                          style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(Icons.grass_rounded, _selectedArena!['surface']),
                      _buildInfoChip(Icons.access_time_filled_rounded, _selectedArena!['hours']),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PremiumButton(
                    text: 'BOOK NOW',
                    onPressed: () => _showCheckoutSheet(context, _selectedArena!),
                    height: 44,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildArenaCard(Map<String, dynamic> arena) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arena['name'],
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: onSurface, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arena['type'],
                      style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(arena['price'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ₸',
                  style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.w900, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(Icons.grass_rounded, arena['surface']),
              _buildInfoChip(Icons.access_time_filled_rounded, arena['hours']),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showCheckoutSheet(context, arena),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: PremiumTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: PremiumTheme.neonShadow(),
              ),
              child: Center(
                child: Text(
                  'field.book_field'.tr(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<FieldSlot>> _fetchAvailableSlots(String fieldId) async {
    if (fieldId.isEmpty) return [];
    try {
      final repo = BookingRepository(ApiClient());
      final slots = await repo.getFieldSlots(fieldId);
      print("DEBUG: Fetched ${slots.length} slots for field $fieldId");
      if (slots.isNotEmpty) {
        print("DEBUG: First slot sample: id=${slots.first.id}, startTime=${slots.first.startTime}, hour=${slots.first.startTime.hour}, isUtc=${slots.first.startTime.isUtc}");
      }
      return slots;
    } catch (e) {
      print("Error loading slots: $e");
      return [];
    }
  }

  void _showCheckoutSheet(BuildContext context, Map<String, dynamic> arena) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double rentPrice = (arena['price'] as num).toDouble();

    // Define state variables outside the builder so they persist
    String selectedPayment = 'KASPI'; // KASPI, STRIPE
    bool isPaying = false;
    bool isSuccess = false;
    bool showQR = false;
    int selectedDateIndex = 0;
    Map<String, dynamic>? selectedSlot;

    Future<void> handleBackendPayment(String method, StateSetter setModalState, double currentTotal, double currentRentPrice) async {
      setModalState(() {
        isPaying = true;
      });
      
      try {
        final bookingRepo = BookingRepository(ApiClient());
        final fieldRepo = FieldRepository(ApiClient());
        
        // 1. Create booking using start_time and end_time
        final booking = await fieldRepo.createBooking(
          arena['id'] as String,
          (selectedSlot!['startTime'] as DateTime).toIso8601String(),
          (selectedSlot!['endTime'] as DateTime).toIso8601String(),
        );
        
        // 2. Create payment
        final payment = await bookingRepo.createPayment({
          'booking_id': booking.id,
          'amount': currentTotal,
          'payment_method': method,
        });
        
        // 3. Confirm payment
        await bookingRepo.confirmPayment(payment.id);
        
        setModalState(() {
          isPaying = false;
          showQR = false;
          isSuccess = true;
        });
        FieldPricingManager().todayRevenue += currentRentPrice;
        FieldPricingManager().notify();
      } catch (e) {
        print("Payment error: $e");
        setModalState(() {
          isPaying = false;
          showQR = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'))
        );
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Recalculate price dynamically based on selected slot
            final double currentRentPrice = selectedSlot != null 
                ? (selectedSlot!['price'] as num).toDouble() 
                : rentPrice;
            final double currentServiceFee = currentRentPrice * 0.05;
            final double currentTotal = currentRentPrice + currentServiceFee;

            return Container(
              height: MediaQuery.of(context).size.height * 0.85, // Height updated to fit slot grid
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0A0E12) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Standard Checkout Screen
                  if (!isPaying && !isSuccess && !showQR) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'CONFIRM BOOKING',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const SizedBox(height: 10),
                          
                          // Arena Summary Card (Static Header Info)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161B22) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: PremiumTheme.neonGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.stadium_rounded, color: PremiumTheme.neonGreen, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        arena['name'],
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        arena['address'],
                                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    arena['surface'],
                                    style: const TextStyle(color: PremiumTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 1. SELECT DATE Section
                          const Text(
                            '1. SELECT DATE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: 7,
                              itemBuilder: (context, index) {
                                final date = DateTime.now().add(Duration(days: index));
                                final isSelected = selectedDateIndex == index;
                                final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      selectedDateIndex = index;
                                      selectedSlot = null; // Reset slot when date changes
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 55,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      gradient: isSelected ? PremiumTheme.primaryGradient : null,
                                      color: isSelected ? null : cs.onSurface.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : (isWeekend ? PremiumTheme.neonGreen.withValues(alpha: 0.2) : cs.onSurface.withValues(alpha: 0.05)),
                                        width: isWeekend && !isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _getDayName(date.weekday),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.black : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? Colors.black : cs.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. SELECT TIME SLOT Section
                          const Text(
                            '2. SELECT TIME SLOT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<List<FieldSlot>>(
                            future: _fetchAvailableSlots(arena['id'] ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(color: PremiumTheme.neonGreen),
                                  ),
                                );
                              }
                              final backendSlots = snapshot.data ?? [];
                              final currentDate = DateTime.now().add(Duration(days: selectedDateIndex));
                              final slots = _generateSlots(arena['name'], currentDate, rentPrice, backendSlots);

                              if (slots.isEmpty) {
                                return const Center(
                                  child: Text("No slots generated", style: TextStyle(color: Colors.white24, fontSize: 12)),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1.35,
                                ),
                                itemCount: slots.length,
                                itemBuilder: (context, index) {
                                  final slot = slots[index];
                                  final time = slot['time'] as String;
                                  final price = slot['price'] as double;
                                  final rateType = slot['rateType'] as String;
                                  final isAvailable = slot['isAvailable'] as bool;
                                  final isSelected = selectedSlot != null && selectedSlot!['time'] == time;

                                  Color cardColor = Colors.transparent;
                                  Color borderColor = cs.onSurface.withValues(alpha: 0.08);
                                  Color textColor = cs.onSurface;
                                  Color badgeColor = Colors.grey;
                                  Color badgeTextColor = Colors.grey;
                                  IconData badgeIcon = Icons.access_time_rounded;

                                  if (isSelected) {
                                    cardColor = PremiumTheme.neonGreen.withValues(alpha: 0.1);
                                    borderColor = PremiumTheme.neonGreen;
                                    textColor = Colors.white;
                                  } else if (!isAvailable) {
                                    borderColor = cs.onSurface.withValues(alpha: 0.03);
                                    textColor = cs.onSurface.withValues(alpha: 0.15);
                                  }

                                  switch (rateType) {
                                    case 'PRIME':
                                      badgeColor = const Color(0xFFFF9800).withValues(alpha: 0.15);
                                      badgeTextColor = const Color(0xFFFF9800);
                                      badgeIcon = Icons.whatshot_rounded;
                                      break;
                                    case 'NIGHT':
                                      badgeColor = const Color(0xFF9C27B0).withValues(alpha: 0.15);
                                      badgeTextColor = const Color(0xFFBA68C8);
                                      badgeIcon = Icons.nights_stay_rounded;
                                      break;
                                    case 'WEEKEND':
                                      badgeColor = const Color(0xFF2196F3).withValues(alpha: 0.15);
                                      badgeTextColor = const Color(0xFF64B5F6);
                                      badgeIcon = Icons.celebration_rounded;
                                      break;
                                    case 'DAY':
                                    default:
                                      badgeColor = const Color(0xFF4CAF50).withValues(alpha: 0.15);
                                      badgeTextColor = const Color(0xFF81C784);
                                      badgeIcon = Icons.wb_sunny_rounded;
                                      break;
                                  }

                                  return GestureDetector(
                                    onTap: isAvailable
                                        ? () {
                                            setModalState(() {
                                              selectedSlot = slot;
                                            });
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: borderColor,
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? PremiumTheme.neonShadow(color: PremiumTheme.neonGreen, opacity: 0.15)
                                            : null,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            time.split(' - ')[0],
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: textColor,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          Text(
                                            '- ${time.split(' - ')[1]}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: textColor.withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(badgeIcon, size: 8, color: badgeTextColor),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k ₸',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.w900,
                                                    color: badgeTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                          const SizedBox(height: 25),

                          // If slot is not selected, display helper info. Otherwise show payment details.
                          if (selectedSlot == null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Please select a date and an available time slot above to calculate payment.',
                                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // 3. PAYMENT DETAILS
                            const Text(
                              '3. PAYMENT DETAILS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161B22) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Field Rental (${selectedSlot!['rateLabel']})',
                                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                      ),
                                      Text(
                                        '${currentRentPrice.toInt()} ₸',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Service Fee (5%)',
                                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                          ),
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message: 'Platform commission fee of 5% applied on transactions for platform maintenance, support, and secure payments',
                                            triggerMode: TooltipTriggerMode.tap,
                                            child: Icon(Icons.info_outline_rounded, size: 12, color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${currentServiceFee.toInt()} ₸',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, color: Colors.white10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'TOTAL AMOUNT',
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                                      ),
                                      Text(
                                        '${currentTotal.toInt()} ₸',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: PremiumTheme.neonGreen, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. SELECT PAYMENT METHOD
                            const Text(
                              '4. SELECT PAYMENT METHOD',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 8),
                            _buildPaymentMethodTile(
                              id: 'KASPI',
                              title: 'Kaspi QR / Kaspi Pay',
                              subtitle: 'Каспи QR (Kazakhstan primary pay)',
                              icon: Icons.qr_code_scanner_rounded,
                              isSelected: selectedPayment == 'KASPI',
                              onTap: () => setModalState(() => selectedPayment = 'KASPI'),
                            ),
                            _buildPaymentMethodTile(
                              id: 'STRIPE',
                              title: 'Stripe Payments',
                              subtitle: 'Visa, MasterCard, Apple Pay (International)',
                              icon: Icons.credit_card_rounded,
                              isSelected: selectedPayment == 'STRIPE',
                              onTap: () => setModalState(() => selectedPayment = 'STRIPE'),
                            ),
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    
                    // Pay Action Area
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF161B22) : Colors.white,
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: selectedSlot == null 
                          ? Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cs.onSurface.withValues(alpha: 0.05)),
                              ),
                              child: const Center(
                                child: Text(
                                  'SELECT A TIME SLOT',
                                  style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                                ),
                              ),
                            )
                          : PremiumButton(
                              text: selectedPayment == 'KASPI' ? 'PROCEED TO KASPI QR' : 'PROCEED TO STRIPE CHECKOUT',
                              onPressed: () {
                                if (selectedPayment == 'KASPI') {
                                  setModalState(() {
                                    isPaying = true;
                                  });
                                  Future.delayed(const Duration(milliseconds: 1500), () {
                                    setModalState(() {
                                      isPaying = false;
                                      showQR = true;
                                    });
                                  });
                                } else {
                                  handleBackendPayment('CARD', setModalState, currentTotal, currentRentPrice);
                                }
                              },
                            ),
                    ),
                  ]

                  // Pay invoice load / scan step
                  else if (isPaying) ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: PremiumTheme.neonGreen),
                            const SizedBox(height: 20),
                            Text(
                              selectedPayment == 'KASPI'
                                  ? 'Generating Kaspi QR invoice...'
                                  : 'Opening Stripe secure checkout...',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please hold on a moment',
                              style: TextStyle(color: Colors.white24, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  ]

                  // Kaspi QR Invoice Screen
                  else if (showQR) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF14635), // Kaspi Red
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'kaspi pay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'IP Champion Sports',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Payment for field booking: ${arena['name']}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Mock QR Code Box
                            Container(
                              width: 180,
                              height: 180,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: 49,
                                itemBuilder: (context, index) {
                                  // Create a simulated QR pattern
                                  final isCorner = (index % 7 == 0 && index < 21) ||
                                      (index % 7 == 6 && index < 21) ||
                                      (index >= 42 && index % 7 == 0) ||
                                      (index == 0 || index == 1 || index == 2 || index == 4 || index == 5 || index == 6 ||
                                       index == 7 || index == 13 || index == 14 || index == 20 ||
                                       index == 28 || index == 34 || index == 35 || index == 41 ||
                                       index == 42 || index == 43 || index == 44 || index == 47 || index == 48);
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isCorner ? const Color(0xFFF14635) : (index % 3 == 0 ? Colors.black : Colors.transparent),
                                      borderRadius: BorderRadius.circular(1.5),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '${currentTotal.toInt()} ₸',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan this QR code using Kaspi.kz app\nor press the button below to pay',
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            PremiumButton(
                              text: 'SIMULATE SUCCESSFUL PAYMENT',
                              onPressed: () {
                                handleBackendPayment('WALLET', setModalState, currentTotal, currentRentPrice);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]

                  // Success Invoice Receipt Screen
                  else ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Successful checkmark anim
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: PremiumTheme.neonGreen.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: PremiumTheme.neonGreen, width: 2),
                              ),
                              child: const Icon(Icons.check_rounded, color: PremiumTheme.neonGreen, size: 36),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'TRANSACTION SUCCESSFUL!',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedPayment == 'KASPI'
                                  ? 'Paid securely via Kaspi QR invoice'
                                  : 'Paid securely via Stripe Checkout',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                            ),
                            const SizedBox(height: 30),

                            // Receipt Details
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF161B22) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                              ),
                              child: Column(
                                children: [
                                  _buildReceiptRow('Invoice ID', 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}'),
                                  const Divider(height: 20, color: Colors.white10),
                                  _buildReceiptRow('Merchant Name', 'IP Champion Sports (Kaspi Pay)'),
                                  const Divider(height: 20, color: Colors.white10),
                                  _buildReceiptRow('Arena booked', arena['name']),
                                  const Divider(height: 20, color: Colors.white10),
                                  _buildReceiptRow('Date & Slot', '${_getDayName(DateTime.now().add(Duration(days: selectedDateIndex)).weekday)}, ${DateTime.now().add(Duration(days: selectedDateIndex)).day} June @ ${selectedSlot!['time']}'),
                                  const Divider(height: 20, color: Colors.white10),
                                  _buildReceiptRow('Total Amount', '${currentTotal.toInt()} ₸'),
                                  const Divider(height: 20, color: Colors.white10),
                                  _buildReceiptRow('Status', 'COMPLETED', color: PremiumTheme.neonGreen),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            PremiumButton(
                              text: 'CLOSE RECEIPT',
                              onPressed: () {
                                Navigator.pop(context);
                                if (_showMap) {
                                  setState(() {
                                    _selectedArena = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildReceiptRow(String label, String value, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? PremiumTheme.neonGreen.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isSelected ? PremiumTheme.neonGreen : cs.onSurfaceVariant, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : cs.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        ),
        trailing: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? PremiumTheme.neonGreen : cs.onSurfaceVariant.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Center(
                  child: CircleAvatar(radius: 4, backgroundColor: PremiumTheme.neonGreen),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _generateSlots(
    String arenaName, 
    DateTime date, 
    double basePrice,
    List<FieldSlot> backendSlots,
  ) {
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    final manager = FieldPricingManager();
    
    final slotsConfig = [
      {'time': '08:00 - 09:30', 'hour': 8},
      {'time': '10:00 - 11:30', 'hour': 10},
      {'time': '12:00 - 13:30', 'hour': 12},
      {'time': '14:00 - 15:30', 'hour': 14},
      {'time': '16:00 - 17:30', 'hour': 16},
      {'time': '18:00 - 19:30', 'hour': 18},
      {'time': '20:00 - 21:30', 'hour': 20},
      {'time': '22:00 - 23:30', 'hour': 22},
      {'time': '00:00 - 01:30', 'hour': 0},
    ];

    // Filter backend slots for the selected day
    final daySlots = backendSlots.where((slot) {
      final localStart = slot.startTime.toLocal();
      final localDate = date.toLocal();
      return DateUtils.isSameDay(localStart, localDate) || 
             (localStart.hour == 0 && DateUtils.isSameDay(localStart, localDate.add(const Duration(days: 1))));
    }).toList();

    print("DEBUG: _generateSlots date=$date, daySlots count=${daySlots.length}, total slots=${backendSlots.length}");

    return slotsConfig.map((config) {
      final time = config['time'] as String;
      final hour = config['hour'] as int;
      
      double price = basePrice;
      String rateType = 'DAY';
      String rateLabel = 'Day Rate';

      if (hour >= 23 || hour == 0) {
        price = basePrice * manager.nightOwlMultiplier;
        rateType = 'NIGHT';
        final int discountPct = ((1.0 - manager.nightOwlMultiplier) * 100).round();
        rateLabel = 'Night Owl (-$discountPct%)';
      } else if (isWeekend) {
        price = basePrice * manager.weekendMultiplier;
        rateType = 'WEEKEND';
        final int surchargePct = ((manager.weekendMultiplier - 1.0) * 100).round();
        rateLabel = 'Weekend Rate (+$surchargePct%)';
      } else if (hour >= 17 && hour < 23) {
        price = basePrice * manager.primeTimeMultiplier;
        rateType = 'PRIME';
        final int surchargePct = ((manager.primeTimeMultiplier - 1.0) * 100).round();
        rateLabel = 'Prime Rate (+$surchargePct%)';
      } else {
        price = basePrice;
        rateType = 'DAY';
        rateLabel = 'Day Rate';
      }

      price = (price / 100).round() * 100.0;

      // Find matching backend slot
      final matchingBackendSlot = daySlots.firstWhere(
        (slot) => slot.startTime.toLocal().hour == hour,
        orElse: () => FieldSlot(id: '', fieldId: '', startTime: DateTime.now(), endTime: DateTime.now(), price: 0, isAvailable: false),
      );

      final bool isAvailable = matchingBackendSlot.id.isNotEmpty && matchingBackendSlot.isAvailable;

      return {
        'id': matchingBackendSlot.id, // Real database slot ID
        'time': time,
        'price': price,
        'rateType': rateType,
        'rateLabel': rateLabel,
        'isAvailable': isAvailable,
        'startTime': matchingBackendSlot.startTime,
        'endTime': matchingBackendSlot.endTime,
      };
    }).toList();
  }

  int _parseTimeToMinutes(String timeStr) {
    final cleanStr = timeStr.trim();
    final parts = cleanStr.split(':');
    if (parts.length < 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  bool _intervalsOverlap(String range1, String range2) {
    final p1 = range1.split('-');
    final p2 = range2.split('-');
    if (p1.length < 2 || p2.length < 2) return false;

    final start1 = _parseTimeToMinutes(p1[0]);
    final end1 = _parseTimeToMinutes(p1[1]);

    final start2 = _parseTimeToMinutes(p2[0]);
    final end2 = _parseTimeToMinutes(p2[1]);

    int actualEnd1 = end1;
    if (actualEnd1 <= start1) actualEnd1 += 24 * 60;

    int actualEnd2 = end2;
    if (actualEnd2 <= start2) actualEnd2 += 24 * 60;

    return start1 < actualEnd2 && start2 < actualEnd1;
  }

  String _getDayName(int day) {
    return ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][day - 1];
  }
}
