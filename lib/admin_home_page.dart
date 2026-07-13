import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_home_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? error;

  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];

  String selectedStatusFilter = 'All';

  Color get primaryPink => const Color(0xFFE91E63);
  Color get softBackground => const Color(0xFFF8F5F7);
  Color get darkText => const Color(0xFF2D1B24);
  Color get mutedText => const Color(0xFF7A6870);
  Color get softPink => const Color(0xFFFFF1F5);
  Color get softBorder => const Color(0xFFF1D7E2);

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final bookingsResponse = await supabase
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      final servicesResponse = await supabase
          .from('services')
          .select()
          .order('name', ascending: true);

      final hairColorsResponse = await supabase
          .from('hair_colors')
          .select()
          .order('code', ascending: true);

      if (!mounted) return;

      setState(() {
        bookings = List<Map<String, dynamic>>.from(bookingsResponse);
        services = List<Map<String, dynamic>>.from(servicesResponse);
        hairColors = List<Map<String, dynamic>>.from(hairColorsResponse);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Failed to load admin data: $e';
        loading = false;
      });
    }
  }

  Map<dynamic, Map<String, dynamic>> get serviceMap {
    final map = <dynamic, Map<String, dynamic>>{};
    for (final service in services) {
      map[service['id']] = service;
    }
    return map;
  }

  Map<String, String> get hairColorMap {
    final map = <String, String>{};
    for (final color in hairColors) {
      final code = color['code']?.toString() ?? '';
      final name = color['name']?.toString() ?? '';
      if (code.isNotEmpty) {
        map[code] = name;
      }
    }
    return map;
  }

  int get totalBookings => bookings.length;

  int get pendingBookings =>
      bookings.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'pending').length;

  int get confirmedBookings =>
      bookings.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'confirmed').length;

  int get completedBookings =>
      bookings.where((b) => (b['status'] ?? '').toString().toLowerCase() == 'completed').length;

  List<String> get statusFilters => const [
        'All',
        'pending',
        'confirmed',
        'completed',
        'cancelled',
      ];

  List<Map<String, dynamic>> get filteredBookings {
    if (selectedStatusFilter == 'All') return bookings;
    return bookings.where((booking) {
      final status = (booking['status'] ?? '').toString().toLowerCase();
      return status == selectedStatusFilter.toLowerCase();
    }).toList();
  }

  String formatDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'No date';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.month}/${parsed.day}/${parsed.year}';
  }

  String formatTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--';
    try {
      final parts = raw.split(':');
      if (parts.length < 2) return raw;

      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final suffix = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;

      return '$hour:$minute $suffix';
    } catch (_) {
      return raw;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Future<void> updateBookingStatus(dynamic bookingId, String newStatus) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      if (!mounted) return;

      setState(() {
        bookings = bookings.map((booking) {
          if (booking['id'] == bookingId) {
            return {
              ...booking,
              'status': newStatus,
            };
          }
          return booking;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking updated to $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $e')),
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerHomePage()),
      (route) => false,
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Review bookings, approve appointments, and manage salon activity from one place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatsGrid() {
    final items = [
      buildStatCard(
        title: 'Total Bookings',
        value: '$totalBookings',
        icon: Icons.calendar_month_rounded,
        color: primaryPink,
      ),
      buildStatCard(
        title: 'Pending',
        value: '$pendingBookings',
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFF59E0B),
      ),
      buildStatCard(
        title: 'Confirmed',
        value: '$confirmedBookings',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2563EB),
      ),
      buildStatCard(
        title: 'Completed',
        value: '$completedBookings',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF16A34A),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1100) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: constraints.maxWidth < 700 ? 3.0 : 2.4,
          ),
          itemBuilder: (_, index) => items[index],
        );
      },
    );
  }

  Widget buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, color: primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedStatusFilter,
              decoration: InputDecoration(
                labelText: 'Filter by status',
                filled: true,
                fillColor: const Color(0xFFFFFCFD),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: softBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: softBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryPink),
                ),
              ),
              items: statusFilters
                  .map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  selectedStatusFilter = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildBookingCard(Map<String, dynamic> booking) {
    final service = serviceMap[booking['service_id']];
    final serviceName = service?['name']?.toString() ?? 'Service #${booking['service_id']}';
    final serviceCategory = service?['category']?.toString() ?? 'General';
    final customerName = booking['customer_name']?.toString() ?? 'Customer';
    final phone = booking['phone']?.toString() ?? 'No phone';
    final email = booking['email']?.toString() ?? '';
    final status = booking['status']?.toString() ?? 'pending';
    final bookingDate = booking['booking_date']?.toString();
    final startTime = booking['start_time']?.toString();
    final endTime = booking['end_time']?.toString();
    final notes = booking['notes']?.toString() ?? '';
    final colorCode = booking['hair_color_code']?.toString() ?? '';
    final colorName = hairColorMap[colorCode];
    final colorText = colorCode.isEmpty
        ? 'No color selected'
        : colorName == null || colorName.isEmpty
            ? colorCode
            : '$colorCode - $colorName';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 840;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerName,
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                serviceName,
                style: TextStyle(
                  color: primaryPink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(Icons.category_rounded, serviceCategory),
                  _chip(Icons.calendar_today_rounded, formatDate(bookingDate)),
                  _chip(
                    Icons.access_time_rounded,
                    '${formatTime(startTime)} - ${formatTime(endTime)}',
                  ),
                  _chip(Icons.palette_outlined, colorText),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Phone: $phone',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 14,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Email: $email',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: $notes',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          );

          final right = Column(
            crossAxisAlignment:
                isSmall ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status.toLowerCase() != 'confirmed')
                    buildActionButton(
                      text: 'Approve',
                      color: const Color(0xFF2563EB),
                      onTap: () => updateBookingStatus(booking['id'], 'confirmed'),
                    ),
                  if (status.toLowerCase() != 'completed')
                    buildActionButton(
                      text: 'Complete',
                      color: const Color(0xFF16A34A),
                      onTap: () => updateBookingStatus(booking['id'], 'completed'),
                    ),
                  if (status.toLowerCase() != 'cancelled')
                    buildActionButton(
                      text: 'Cancel',
                      color: const Color(0xFFDC2626),
                      onTap: () => updateBookingStatus(booking['id'], 'cancelled'),
                    ),
                ],
              ),
            ],
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 16),
                right,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              right,
            ],
          );
        },
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: softPink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: primaryPink),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: darkText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: softBackground,
        body: Center(
          child: CircularProgressIndicator(color: primaryPink),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: softBackground,
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: softBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadAdminData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadAdminData,
        color: primaryPink,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  children: [
                    buildHeader(),
                    const SizedBox(height: 20),
                    buildStatsGrid(),
                    const SizedBox(height: 20),
                    buildStatusFilter(),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bookings',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Approve and manage customer appointments from here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: mutedText,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (filteredBookings.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFCFD),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: softBorder),
                              ),
                              child: Text(
                                'No bookings found for this status.',
                                style: TextStyle(color: mutedText),
                              ),
                            )
                          else
                            Column(
                              children: filteredBookings
                                  .map((booking) => buildBookingCard(booking))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}