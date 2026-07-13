import 'package:flutter/material.dart';
import 'customer_home_page.dart';

class BookingSuccessPage extends StatelessWidget {
  final String serviceName;
  final String price;
  final String bookingDate;
  final String start;
  final String end;
  final String hairColor;

  const BookingSuccessPage({
    super.key,
    required this.serviceName,
    required this.price,
    required this.bookingDate,
    required this.start,
    required this.end,
    required this.hairColor,
  });

  Color get primaryPink => const Color(0xFFE91E63);
  Color get softBackground => const Color(0xFFF8F5F7);
  Color get darkText => const Color(0xFF2D1B24);
  Color get mutedText => const Color(0xFF7A6870);
  Color get softPink => const Color(0xFFFFF1F5);
  Color get softBorder => const Color(0xFFF1D7E2);

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: softBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: softPink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryPink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: darkText,
                    fontSize: 16,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 850;

    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        backgroundColor: softBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Booking Confirmed',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: softPink,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: primaryPink,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Appointment Booked Successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thank you for booking with Faith Hairstyle. Your appointment has been received and is currently pending confirmation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Summary',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            serviceName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '\$$price',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    isDesktop
                        ? Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Booking Date',
                                  value: bookingDate,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _infoCard(
                                  icon: Icons.access_time_rounded,
                                  label: 'Appointment Time',
                                  value: '$start - $end',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _infoCard(
                                icon: Icons.calendar_month_rounded,
                                label: 'Booking Date',
                                value: bookingDate,
                              ),
                              const SizedBox(height: 14),
                              _infoCard(
                                icon: Icons.access_time_rounded,
                                label: 'Appointment Time',
                                value: '$start - $end',
                              ),
                            ],
                          ),
                    const SizedBox(height: 14),
                    _infoCard(
                      icon: Icons.palette_outlined,
                      label: 'Selected Hair Color',
                      value: hairColor,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CustomerHomePage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text('Go to Home'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}