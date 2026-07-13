import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_success_page.dart';

class BookingPage extends StatefulWidget {
  final Map service;

  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  List<Map<String, dynamic>> hairColors = [];
  String? selectedHairColor;

  @override
  void initState() {
    super.initState();
    loadHairColors();
  }

  Future<void> loadHairColors() async {
    final response = await supabase
        .from('hair_colors')
        .select()
        .eq('is_active', true)
        .order('code');

    setState(() {
      hairColors = List<Map<String, dynamic>>.from(response);
    });
  }

  String databaseTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  String displayTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay endTimeFromStart(TimeOfDay start) {
    final endHour = (start.hour + 1) % 24;
    return TimeOfDay(hour: endHour, minute: start.minute);
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  Future<void> submitBooking() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        selectedHairColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final endTime = endTimeFromStart(selectedTime!);

    try {
      await supabase.from('bookings').insert({
        'customer_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'service_id': widget.service['id'],
        'booking_date': selectedDate!.toIso8601String().split('T')[0],
        'start_time': databaseTime(selectedTime!),
        'end_time': databaseTime(endTime),
        'status': 'pending',
        'hair_color_code': selectedHairColor,
        'notes': '',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSuccessPage(
            serviceName: widget.service['name'].toString(),
            price: widget.service['price'].toString(),
            bookingDate: selectedDate!.toString().split(' ')[0],
            start: displayTime(selectedTime!),
            end: displayTime(endTime),
            hairColor: selectedHairColor!,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.service['name']?.toString() ?? 'Service';
    final servicePrice = widget.service['price']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: Text('Book $serviceName'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.pink.shade50,
              child: ListTile(
                leading: const Icon(Icons.content_cut, color: Colors.pink),
                title: Text(
                  serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Price: \$$servicePrice'),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 15),

            ListTile(
              title: Text(
                selectedDate == null
                    ? 'Select Date'
                    : selectedDate!.toString().split(' ')[0],
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: pickDate,
            ),

            ListTile(
              title: Text(
                selectedTime == null
                    ? 'Select Time'
                    : selectedTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: pickTime,
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Hair Color'),
              value: selectedHairColor,
              items: hairColors.map<DropdownMenuItem<String>>((color) {
                final code = color['code'].toString();
                final name = color['name'].toString();

                return DropdownMenuItem<String>(
                  value: code,
                  child: Text('$code - $name'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedHairColor = value;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: submitBooking,
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}