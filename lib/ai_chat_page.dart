import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_page.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  final String functionUrl =
      'https://lowqtmndtkgwmnyhqszp.supabase.co/functions/v1/chat-assistant';

  final String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxvd3F0bW5kdGtnd21ueWhxc3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODgzMjQsImV4cCI6MjA4ODY2NDMyNH0.DAD_IfgcnXSnMfhu0MCl-CBVIVIEUSe9Yh7JbdvOhtw';

  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];

  bool loading = false;
  bool loadingData = true;
  String? lastSuggestedService;

  Color get primaryPink => const Color(0xFFE91E63);
  Color get softPink => const Color(0xFFFFF1F5);
  Color get darkText => const Color(0xFF2D1B24);

  @override
  void initState() {
    super.initState();
    messages.add({
      'role': 'assistant',
      'text':
          'Hello, I am FaithCo. I can help you choose a hairstyle, check prices, explain hair colors, and book your appointment.',
    });
    loadSalonData();
  }

  Future<void> loadSalonData() async {
    try {
      final serviceResponse = await supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .order('name');

      final colorResponse = await supabase
          .from('hair_colors')
          .select()
          .eq('is_active', true)
          .order('code');

      setState(() {
        services = List<Map<String, dynamic>>.from(serviceResponse);
        hairColors = List<Map<String, dynamic>>.from(colorResponse);
        loadingData = false;
      });
    } catch (e) {
      setState(() {
        loadingData = false;
        messages.add({
          'role': 'assistant',
          'text': 'I could not load salon data: $e',
        });
      });
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, dynamic>? findServiceFromText(String text) {
    final lower = text.toLowerCase();

    for (final service in services) {
      final name = service['name']?.toString().toLowerCase() ?? '';
      if (name.isNotEmpty && lower.contains(name)) {
        return service;
      }
    }

    if (lower.contains('knotless')) {
      return services.firstWhere(
        (s) => s['name'].toString().toLowerCase().contains('knotless'),
        orElse: () => {},
      );
    }

    if (lower.contains('fulani')) {
      return services.firstWhere(
        (s) => s['name'].toString().toLowerCase().contains('fulani'),
        orElse: () => {},
      );
    }

    if (lower.contains('lemonade')) {
      return services.firstWhere(
        (s) => s['name'].toString().toLowerCase().contains('lemonade'),
        orElse: () => {},
      );
    }

    if (lower.contains('twist')) {
      return services.firstWhere(
        (s) => s['name'].toString().toLowerCase().contains('twist'),
        orElse: () => {},
      );
    }

    if (lower.contains('braid')) {
      return services.firstWhere(
        (s) => s['category'].toString().toLowerCase().contains('braid'),
        orElse: () => {},
      );
    }

    return null;
  }

  Future<void> openBookingFromAI(String userText) async {
    Map<String, dynamic>? service = findServiceFromText(userText);

    if ((service == null || service.isEmpty) && lastSuggestedService != null) {
      service = services.firstWhere(
        (s) => s['name'] == lastSuggestedService,
        orElse: () => {},
      );
    }

    if (service == null || service.isEmpty) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'text':
              'Which service would you like to book? For example: Fulani Braids, Knotless Braids, Twists, or Kids Styling.',
        });
      });
      scrollToBottom();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(service: service!),
      ),
    );
  }

  bool isBookingRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('book') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reserve');
  }

  Future<void> sendMessage([String? preset]) async {
    final text = (preset ?? controller.text).trim();
    if (text.isEmpty || loading) return;

    setState(() {
      messages.add({'role': 'user', 'text': text});
      loading = true;
    });

    controller.clear();
    scrollToBottom();

    if (isBookingRequest(text)) {
      setState(() {
        loading = false;
        messages.add({
          'role': 'assistant',
          'text': 'Great, I will open the booking page for you now.',
        });
      });
      scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 400));
      await openBookingFromAI(text);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode({
          'message': text,
          'services': services.map((s) {
            return {
              'name': s['name']?.toString() ?? '',
              'description': s['description']?.toString() ?? '',
              'price': s['price']?.toString() ?? '',
              'duration_minutes': s['duration_minutes']?.toString() ?? '',
              'category': s['category']?.toString() ?? '',
            };
          }).toList(),
          'hair_colors': hairColors.map((c) {
            return {
              'code': c['code']?.toString() ?? '',
              'name': c['name']?.toString() ?? '',
            };
          }).toList(),
          'chatHistory': messages.map((m) {
            return {
              'role': m['role'],
              'content': m['text'],
            };
          }).toList(),
        }),
      );

      String reply = 'No reply from FaithCo.';

      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        reply = data['reply']?.toString() ?? reply;
      }

      final detectedService = findServiceFromText(reply);
      if (detectedService != null && detectedService.isNotEmpty) {
        lastSuggestedService = detectedService['name']?.toString();
      }

      setState(() {
        messages.add({'role': 'assistant', 'text': reply});
      });
    } catch (e) {
      setState(() {
        messages.add({
          'role': 'assistant',
          'text': 'Connection error: $e',
        });
      });
    } finally {
      setState(() {
        loading = false;
      });
      scrollToBottom();
    }
  }

  Widget messageBubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 750),
        decoration: BoxDecoration(
          color: isUser ? primaryPink : const Color(0xFFFFF7FA),
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: const Color(0xFFF1D7E2)),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? 'You' : 'FaithCo AI Assistant',
              style: TextStyle(
                color: isUser ? Colors.white70 : primaryPink,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg['text'] ?? '',
              style: TextStyle(
                color: isUser ? Colors.white : darkText,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget promptButton(String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: loading ? null : () => sendMessage(text),
      icon: Icon(icon, color: primaryPink),
      label: Text(text),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('FaithCo')),
        body: Center(child: CircularProgressIndicator(color: primaryPink)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F7),
      appBar: AppBar(
        title: const Text('FaithCo AI Assistant'),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: primaryPink,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can FaithCo help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ask about styles, prices, colors, or say “book it for me.”',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  promptButton('What hairstyles do you offer?', Icons.style),
                  promptButton('How much are knotless braids?', Icons.money),
                  promptButton('What hair color is 1B?', Icons.palette),
                  promptButton('Book Fulani Braids for me', Icons.event),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (_, index) => messageBubble(messages[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask FaithCo for help...',
                        filled: true,
                        fillColor: softPink,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: loading ? null : () => sendMessage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(18),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
