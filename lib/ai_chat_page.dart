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

  // ============================================================
  // DINMAX AI
  // ============================================================

  static const String dinMaxUrl =
      'https://dinmax-ai-production.up.railway.app/chat';

  // ============================================================
  // FAITH HAIR STYLE CONTACT
  // ============================================================

  static const String contactNumber = '3015419875';
  static const String displayContactNumber = '+1 301-541-9875';

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, String>> messages = [];

  List<Map<String, dynamic>> services = [];

  List<Map<String, dynamic>> hairColors = [];

  bool loading = false;
  bool loadingData = true;

  String? lastSuggestedService;

  // ============================================================
  // COLORS
  // ============================================================

  Color get primaryPink => const Color(0xFFE91E63);

  Color get softPink => const Color(0xFFFFF1F5);

  Color get darkText => const Color(0xFF2D1B24);

  // ============================================================
  // INITIALIZE
  // ============================================================

  @override
  void initState() {
    super.initState();

    messages.add({
      'role': 'assistant',
      'text':
          'Hello! 👋 I am the Faith Hair Style AI Assistant powered by DinMax AI.\n\n'
              'I can help you choose a hairstyle, check prices, learn about '
              'hair colors, and start your appointment booking.\n\n'
              '📞 Call or text $displayContactNumber for direct assistance.',
    });

    loadSalonData();
  }

  // ============================================================
  // LOAD LIVE SALON DATA FROM SUPABASE
  // ============================================================

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

      if (!mounted) return;

      setState(() {
        services =
            List<Map<String, dynamic>>.from(serviceResponse);

        hairColors =
            List<Map<String, dynamic>>.from(colorResponse);

        loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingData = false;

        messages.add({
          'role': 'assistant',
          'text':
              'I could not load all salon information right now. '
                  'You can still ask me questions or call/text '
                  '$displayContactNumber.',
        });
      });
    }
  }

  // ============================================================
  // SCROLL CHAT
  // ============================================================

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 150,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // FIND SERVICE
  // ============================================================

  Map<String, dynamic>? findServiceFromText(String text) {
    final lower = text.toLowerCase();

    // Try exact service name first.

    for (final service in services) {
      final name =
          service['name']?.toString().toLowerCase() ?? '';

      if (name.isNotEmpty && lower.contains(name)) {
        return service;
      }
    }

    // Knotless

    if (lower.contains('knotless')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('knotless'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Fulani

    if (lower.contains('fulani')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('fulani'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Lemonade

    if (lower.contains('lemonade')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('lemonade'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Senegalese

    if (lower.contains('senegalese')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('senegalese'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Twists

    if (lower.contains('twist')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('twist'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Ponytail

    if (lower.contains('ponytail')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('ponytail'),
        orElse: () => <String, dynamic>{},
      );
    }

    // Cornrows

    if (lower.contains('cornrow')) {
      return services.firstWhere(
        (service) =>
            service['name']
                .toString()
                .toLowerCase()
                .contains('cornrow'),
        orElse: () => <String, dynamic>{},
      );
    }

    // General braid

    if (lower.contains('braid')) {
      return services.firstWhere(
        (service) =>
            service['category']
                ?.toString()
                .toLowerCase()
                .contains('braid') ??
            false,
        orElse: () => <String, dynamic>{},
      );
    }

    return null;
  }

  // ============================================================
  // DETECT BOOKING REQUEST
  // ============================================================

  bool isBookingRequest(String text) {
    final lower = text.toLowerCase();

    return lower.contains('book') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reserve');
  }

  // ============================================================
  // OPEN BOOKING PAGE
  // ============================================================

  Future<void> openBookingFromAI(String userText) async {
    Map<String, dynamic>? service =
        findServiceFromText(userText);

    if ((service == null || service.isEmpty) &&
        lastSuggestedService != null) {
      service = services.firstWhere(
        (item) =>
            item['name']?.toString() ==
            lastSuggestedService,
        orElse: () => <String, dynamic>{},
      );
    }

    if (service == null || service.isEmpty) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'assistant',
          'text':
              'Which hairstyle would you like to book?\n\n'
                  'For example:\n'
                  '• Knotless Braids\n'
                  '• Fulani Braids\n'
                  '• Senegalese Twists\n'
                  '• Cornrows\n'
                  '• Kids Styling',
        });
      });

      scrollToBottom();

      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          service: service!,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD SERVICE CONTEXT FOR DINMAX
  // ============================================================

  String buildServiceContext() {
    if (services.isEmpty) {
      return 'No live service information is currently available.';
    }

    return services.map((service) {
      final name =
          service['name']?.toString() ?? '';

      final description =
          service['description']?.toString() ?? '';

      final price =
          service['price']?.toString() ?? '';

      final duration =
          service['duration_minutes']?.toString() ?? '';

      final category =
          service['category']?.toString() ?? '';

      return '''
SERVICE: $name
CATEGORY: $category
PRICE: $price
DURATION: $duration minutes
DESCRIPTION: $description
''';
    }).join('\n');
  }

  // ============================================================
  // BUILD HAIR COLOR CONTEXT
  // ============================================================

  String buildColorContext() {
    if (hairColors.isEmpty) {
      return 'No hair color information is currently available.';
    }

    return hairColors.map((color) {
      final code =
          color['code']?.toString() ?? '';

      final name =
          color['name']?.toString() ?? '';

      return '$code = $name';
    }).join('\n');
  }

  // ============================================================
  // BUILD RECENT CHAT HISTORY
  // ============================================================

  String buildChatHistory() {
    if (messages.isEmpty) return '';

    final start =
        messages.length > 12
            ? messages.length - 12
            : 0;

    final recentMessages =
        messages.sublist(start);

    return recentMessages.map((message) {
      final role =
          message['role'] ?? 'unknown';

      final text =
          message['text'] ?? '';

      return '$role: $text';
    }).join('\n');
  }

  // ============================================================
  // ASK DINMAX AI
  // ============================================================

  Future<String> askDinMax(String customerMessage) async {
    final serviceContext =
        buildServiceContext();

    final colorContext =
        buildColorContext();

    final history =
        buildChatHistory();

    /*
      IMPORTANT:

      DinMax /chat accepts:

      {
        "message": "..."
      }

      Therefore ALL Faith Hair Style information goes
      inside the message.
    */

    final aiMessage = '''
You are the official AI assistant for Faith Hair Style.

============================================================
BUSINESS
============================================================

Business name:
Faith Hair Style

Location:
Riverdale, Maryland

Phone / Text:
$displayContactNumber

============================================================
YOUR JOB
============================================================

You help Faith Hair Style customers with:

- Hairstyles
- Protective hairstyles
- Braids
- Knotless braids
- Senegalese twists
- Fulani braids
- Cornrows
- Ponytails
- Kids hairstyles
- Hair colors
- Prices
- Service durations
- Appointment preparation
- Choosing hairstyles
- Booking questions

============================================================
IMPORTANT RULES
============================================================

1. You are Faith Hair Style's customer assistant.

2. Do NOT introduce yourself as a study assistant.

3. Do NOT ask customers what they want to study,
   research, code, or build.

4. Keep conversations focused on Faith Hair Style
   unless the customer specifically asks something else.

5. Be warm, friendly, professional, and concise.

6. Use the LIVE SERVICES information below when
   answering questions about services and prices.

7. NEVER invent a price.

8. If a price is not available, tell the customer
   to call or text:

   $displayContactNumber

9. If a customer wants to book, tell them they can say:

   "Book [service name] for me."

10. Do NOT tell a customer that an appointment is
    confirmed unless the booking system actually
    confirms the appointment.

11. If a customer asks for recommendations, help them
    choose an appropriate hairstyle.

12. When appropriate, encourage customers to book
    with Faith Hair Style.

============================================================
LIVE FAITH HAIR STYLE SERVICES
============================================================

$serviceContext

============================================================
AVAILABLE HAIR COLORS
============================================================

$colorContext

============================================================
RECENT CONVERSATION
============================================================

$history

============================================================
CUSTOMER MESSAGE
============================================================

$customerMessage
''';

    try {
      final response = await http
          .post(
            Uri.parse(dinMaxUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': aiMessage,
            }),
          )
          .timeout(
            const Duration(seconds: 40),
          );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        if (response.body.isEmpty) {
          return 'I did not receive a response from the AI. '
              'Please call or text $displayContactNumber.';
        }

        final dynamic decoded =
            jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final reply =
              decoded['reply']?.toString();

          if (reply != null &&
              reply.trim().isNotEmpty) {
            return reply.trim();
          }
        }

        return 'I could not read the AI response. '
            'Please call or text $displayContactNumber.';
      }

      return 'Faith Hair Style AI is temporarily unavailable '
          '(server ${response.statusCode}). '
          'Please call or text $displayContactNumber.';
    } catch (e) {
      return 'I could not connect to Faith Hair Style AI. '
          'Please call or text $displayContactNumber.';
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage([
    String? preset,
  ]) async {
    final text =
        (preset ?? controller.text).trim();

    if (text.isEmpty || loading) return;

    setState(() {
      messages.add({
        'role': 'user',
        'text': text,
      });

      loading = true;
    });

    controller.clear();

    scrollToBottom();

    // ----------------------------------------------------------
    // BOOKING REQUEST
    // ----------------------------------------------------------

    if (isBookingRequest(text)) {
      setState(() {
        loading = false;

        messages.add({
          'role': 'assistant',
          'text':
              'Great! 💕 I will help you start your booking.',
        });
      });

      scrollToBottom();

      await Future.delayed(
        const Duration(
          milliseconds: 400,
        ),
      );

      await openBookingFromAI(text);

      return;
    }

    // ----------------------------------------------------------
    // ASK DINMAX
    // ----------------------------------------------------------

    final reply =
        await askDinMax(text);

    if (!mounted) return;

    // Remember hairstyle DinMax mentioned.

    final detectedService =
        findServiceFromText(reply);

    if (detectedService != null &&
        detectedService.isNotEmpty) {
      lastSuggestedService =
          detectedService['name']
              ?.toString();
    }

    setState(() {
      messages.add({
        'role': 'assistant',
        'text': reply,
      });

      loading = false;
    });

    scrollToBottom();
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget messageBubble(
    Map<String, String> message,
  ) {
    final isUser =
        message['role'] == 'user';

    return Align(
      alignment:
          isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 7,
        ),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 750,
        ),
        decoration: BoxDecoration(
          color:
              isUser
                  ? primaryPink
                  : const Color(0xFFFFF7FA),
          borderRadius:
              BorderRadius.circular(18),
          border:
              isUser
                  ? null
                  : Border.all(
                      color:
                          const Color(
                            0xFFF1D7E2,
                          ),
                    ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                    alpha: 0.04,
                  ),
              blurRadius: 8,
              offset:
                  const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Text(
              isUser
                  ? 'You'
                  : 'Faith Hair Style AI',
              style: TextStyle(
                color:
                    isUser
                        ? Colors.white70
                        : primaryPink,
                fontSize: 12,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message['text'] ?? '',
              style: TextStyle(
                color:
                    isUser
                        ? Colors.white
                        : darkText,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUICK PROMPT BUTTON
  // ============================================================

  Widget promptButton(
    String text,
    IconData icon,
  ) {
    return OutlinedButton.icon(
      onPressed:
          loading
              ? null
              : () =>
                  sendMessage(text),
      icon: Icon(
        icon,
        color: primaryPink,
      ),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        side: BorderSide(
          color:
              primaryPink.withValues(
                alpha: 0.35,
              ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.dispose();

    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (loadingData) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text(
                'Faith Hair Style AI',
              ),
        ),
        body: Center(
          child:
              CircularProgressIndicator(
                color: primaryPink,
              ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F5F7),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title:
            const Text(
              'Faith Hair Style AI Assistant',
            ),
        backgroundColor:
            primaryPink,
        foregroundColor:
            Colors.white,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // AI HEADER
            // ==================================================

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                    20,
                  ),
              decoration: BoxDecoration(
                color: primaryPink,
              ),
              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can Faith Hair Style help?',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 7),

                  Text(
                    'Ask about styles, prices, colors, or appointments.',
                    style: TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 15,
                    ),
                  ),

                  SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color:
                            Colors.white,
                        size: 17,
                      ),

                      SizedBox(width: 6),

                      Text(
                        '+1 301-541-9875',
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================================
            // QUICK QUESTIONS
            // ==================================================

            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(
                    12,
                  ),
              color: Colors.white,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  promptButton(
                    'What hairstyles do you offer?',
                    Icons.style,
                  ),

                  promptButton(
                    'How much are knotless braids?',
                    Icons.attach_money,
                  ),

                  promptButton(
                    'What hair color is 1B?',
                    Icons.palette,
                  ),

                  promptButton(
                    'Book Fulani Braids for me',
                    Icons.event,
                  ),
                ],
              ),
            ),

            // ==================================================
            // CHAT
            // ==================================================

            Expanded(
              child:
                  ListView.builder(
                    controller:
                        scrollController,
                    padding:
                        const EdgeInsets.all(
                          16,
                        ),
                    itemCount:
                        messages.length +
                        (loading ? 1 : 0),
                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                      if (loading &&
                          index ==
                              messages.length) {
                        return Align(
                          alignment:
                              Alignment
                                  .centerLeft,
                          child: Container(
                            margin:
                                const EdgeInsets
                                    .symmetric(
                                  vertical: 7,
                                ),
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                      18,
                                  vertical: 14,
                                ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                        18,
                                      ),
                              border:
                                  Border.all(
                                color:
                                    const Color(
                                      0xFFF1D7E2,
                                    ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                SizedBox(
                                  width: 17,
                                  height: 17,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        primaryPink,
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Text(
                                  'Faith AI is thinking...',
                                  style:
                                      TextStyle(
                                    color:
                                        darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return messageBubble(
                        messages[index],
                      );
                    },
                  ),
            ),

            // ==================================================
            // INPUT
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(
                    14,
                  ),
              decoration:
                  const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color:
                        Color(
                          0x12000000,
                        ),
                    blurRadius: 10,
                    offset:
                        Offset(
                          0,
                          -3,
                        ),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                          controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction:
                          TextInputAction.send,
                      onSubmitted:
                          (_) {
                        if (!loading) {
                          sendMessage();
                        }
                      },
                      decoration:
                          InputDecoration(
                        hintText:
                            'Ask Faith Hair Style AI...',
                        filled: true,
                        fillColor:
                            softPink,
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                    22,
                                  ),
                          borderSide:
                              BorderSide
                                  .none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  ElevatedButton(
                    onPressed:
                        loading
                            ? null
                            : () =>
                                sendMessage(),
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryPink,
                      foregroundColor:
                          Colors.white,
                      minimumSize:
                          const Size(
                            56,
                            56,
                          ),
                      padding:
                          EdgeInsets.zero,
                      shape:
                          const CircleBorder(),
                    ),
                    child:
                        const Icon(
                          Icons.send,
                        ),
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