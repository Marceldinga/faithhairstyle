import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_page.dart';

/// Put this around the Navigator using MaterialApp.builder so Faith AI floats
/// over every customer-facing page and keeps the same conversation while the
/// customer navigates around the website.
///
/// Example in main.dart:
///
/// final navigatorKey = GlobalKey<NavigatorState>();
///
/// MaterialApp(
///   navigatorKey: navigatorKey,
///   builder: (context, child) => FaithAICopilotShell(
///     navigatorKey: navigatorKey,
///     child: child ?? const SizedBox.shrink(),
///   ),
///   home: const HomePage(),
/// );
class FaithAICopilotShell extends StatefulWidget {
  const FaithAICopilotShell({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FaithAICopilotShell> createState() => _FaithAICopilotShellState();
}

class _FaithAICopilotShellState extends State<FaithAICopilotShell> {
  bool _open = false;
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Offstage(
                    offstage: !_open || _minimized,
                    child: FaithAICopilotPanel(
                      navigatorKey: widget.navigatorKey,
                      onClose: () {
                        setState(() {
                          _open = false;
                          _minimized = false;
                        });
                      },
                      onMinimize: () {
                        setState(() => _minimized = true);
                      },
                    ),
                  ),
                  if (!_open || _minimized)
                    _CopilotLauncher(
                      hasActiveChat: _open,
                      onTap: () {
                        setState(() {
                          _open = true;
                          _minimized = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CopilotLauncher extends StatelessWidget {
  const _CopilotLauncher({
    super.key,
    required this.onTap,
    required this.hasActiveChat,
  });

  final VoidCallback onTap;
  final bool hasActiveChat;

  static const Color navy = Color(0xFF071A42);
  static const Color gold = Color(0xFFE4AD16);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF071A42), Color(0xFF0754AD)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: gold, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: navy,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Faith AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  hasActiveChat ? 'Continue your chat' : 'Ask your salon copilot',
                  style: const TextStyle(
                    color: Color(0xFFFFD761),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FaithAICopilotPanel extends StatefulWidget {
  const FaithAICopilotPanel({
    super.key,
    this.onClose,
    this.onMinimize,
    this.navigatorKey,
  });

  final VoidCallback? onClose;
  final VoidCallback? onMinimize;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<FaithAICopilotPanel> createState() => _FaithAICopilotPanelState();
}

class _FaithAICopilotPanelState extends State<FaithAICopilotPanel> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  static const String dinMaxUrl =
      'https://dinmax-ai-production.up.railway.app/chat';
  static const String displayContactNumber = '+1 301-541-9875';

  static const Color navy = Color(0xFF071A42);
  static const Color deepBlue = Color(0xFF0A2D6E);
  static const Color royalBlue = Color(0xFF0754AD);
  static const Color gold = Color(0xFFE4AD16);
  static const Color deepGold = Color(0xFF9A6800);
  static const Color pageBackground = Color(0xFFF6F8FC);
  static const Color borderGold = Color(0xFFD8B649);
  static const Color muted = Color(0xFF667085);

  final List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];
  List<Map<String, dynamic>> availabilitySlots = [];
  List<Map<String, dynamic>> bookingSignals = [];

  bool loading = false;
  bool loadingData = true;
  bool showBookingButton = false;
  String? lastSuggestedService;

  // Lightweight customer consultation memory. This helps the copilot behave
  // more like an assistant instead of restarting its reasoning on every turn.
  String? rememberedBudget;
  String? rememberedLength;
  String? rememberedSize;
  String? rememberedColor;
  String? rememberedOccasion;

  @override
  void initState() {
    super.initState();
    messages.add({
      'role': 'assistant',
      'text':
          'Hi! I’m Faith AI, your salon copilot. Tell me the look you want, your budget, or when you want to come in — I’ll help you narrow it down and get ready to book.',
    });
    loadSalonData();
  }

  String dateOnly(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadSalonData() async {
    try {
      final today = dateOnly(DateTime.now());
      final results = await Future.wait([
        supabase
            .from('services')
            .select(
              'id,name,description,price,duration_minutes,category,is_active,image_url',
            )
            .eq('is_active', true)
            .order('price', ascending: true),
        supabase
            .from('hair_colors')
            .select('id,code,name,is_active')
            .eq('is_active', true)
            .order('code', ascending: true),
        supabase
            .from('availability_slots')
            .select('id,slot_date,start_time,end_time,is_available')
            .eq('is_available', true)
            .gte('slot_date', today)
            .order('slot_date', ascending: true)
            .order('start_time', ascending: true)
            .limit(100),
        // Customer-safe booking signals only. Never load names, phone numbers,
        // emails, or notes into the Copilot context.
        supabase
            .from('bookings')
            .select(
              'id,service_id,booking_date,start_time,end_time,status,hair_color_code,created_at',
            )
            .gte('booking_date', today)
            .inFilter('status', ['pending', 'confirmed'])
            .order('booking_date', ascending: true)
            .order('start_time', ascending: true)
            .limit(120),
      ]);

      if (!mounted) return;
      setState(() {
        services = List<Map<String, dynamic>>.from(results[0] as List);
        hairColors = List<Map<String, dynamic>>.from(results[1] as List);
        availabilitySlots = List<Map<String, dynamic>>.from(results[2] as List);
        bookingSignals = List<Map<String, dynamic>>.from(results[3] as List);
        loadingData = false;
      });
    } catch (_) {
      try {
        final serviceResponse = await supabase
            .from('services')
            .select()
            .eq('is_active', true)
            .order('price', ascending: true);

        if (!mounted) return;
        setState(() {
          services = List<Map<String, dynamic>>.from(serviceResponse);
          loadingData = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => loadingData = false);
      }
    }
  }

  Future<void> refreshSalonData() async {
    if (mounted) setState(() => loadingData = true);
    await loadSalonData();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String money(dynamic value) {
    if (value == null) return 'not listed';
    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();
    if (parsed == parsed.roundToDouble()) {
      return '\$${parsed.toStringAsFixed(0)}';
    }
    return '\$${parsed.toStringAsFixed(2)}';
  }

  String duration(dynamic value) {
    final minutes = int.tryParse(value?.toString() ?? '');
    if (minutes == null || minutes <= 0) return 'not listed';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$minutes minutes';
    if (remainder == 0) return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    return '$hours hr $remainder min';
  }

  Map<String, dynamic>? findServiceFromText(String text) {
    final lower = text.toLowerCase();

    for (final service in services) {
      final name = service['name']?.toString().trim().toLowerCase() ?? '';
      if (name.isNotEmpty && lower.contains(name)) return service;
    }

    const aliases = <String, List<String>>{
      'knotless': ['knotless'],
      'fulani': ['fulani'],
      'lemonade': ['lemonade'],
      'senegalese': ['senegalese'],
      'twist': ['twist'],
      'ponytail': ['ponytail'],
      'cornrow': ['cornrow'],
      'boho': ['boho'],
      'spring': ['spring'],
      'kids': ['kids', 'kid', 'child'],
    };

    for (final entry in aliases.entries) {
      if (!entry.value.any(lower.contains)) continue;
      final matches = services.where((service) {
        final name = service['name']?.toString().toLowerCase() ?? '';
        final category = service['category']?.toString().toLowerCase() ?? '';
        return name.contains(entry.key) || category.contains(entry.key);
      }).toList();
      if (matches.isNotEmpty) return matches.first;
    }

    if (lower.contains('braid')) {
      final matches = services.where((service) {
        final name = service['name']?.toString().toLowerCase() ?? '';
        final category = service['category']?.toString().toLowerCase() ?? '';
        return name.contains('braid') || category.contains('braid');
      }).toList();
      if (matches.isNotEmpty) return matches.first;
    }

    return null;
  }

  bool isBookingIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('book') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reserve') ||
        lower.contains('available time') ||
        lower.contains('availability') ||
        lower.contains('ready');
  }

  bool isPriceIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('price') ||
        lower.contains('cost') ||
        lower.contains('budget') ||
        lower.contains('how much') ||
        RegExp(r'\$\s*\d+').hasMatch(lower);
  }

  void rememberCustomerPreferences(String text) {
    final lower = text.toLowerCase();

    final budgetMatch = RegExp(
      r'(?:\$\s*|budget(?:\s+is|\s+of|\s+around|\s+about)?\s*\$?)(\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (budgetMatch != null) rememberedBudget = '\$${budgetMatch.group(1)}';

    const lengths = [
      'shoulder',
      'midback',
      'mid back',
      'waist',
      'top butt',
      'mid butt',
      'under butt',
      'butt length',
    ];
    for (final item in lengths) {
      if (lower.contains(item)) rememberedLength = item;
    }

    const sizes = [
      'jumbo',
      'large',
      'medium',
      'small medium',
      'semi-medium',
      'semi medium',
      'small',
    ];
    for (final item in sizes) {
      if (lower.contains(item)) rememberedSize = item;
    }

    final colorMatch = RegExp(
      r'(?:color|colour)\s*(?:#|number|no\.?|code)?\s*([0-9]{1,3}[a-z]?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (colorMatch != null) rememberedColor = colorMatch.group(1);

    const occasions = [
      'birthday',
      'wedding',
      'vacation',
      'work',
      'school',
      'party',
      'photoshoot',
      'photo shoot',
    ];
    for (final item in occasions) {
      if (lower.contains(item)) rememberedOccasion = item;
    }
  }

  String buildServiceContext() {
    if (services.isEmpty) return 'No live service records are currently available.';
    return services.map((service) {
      final name = (service['name'] ?? '').toString().trim();
      final category = (service['category'] ?? '').toString().trim();
      final description = (service['description'] ?? '').toString().trim();
      return '- $name | category: $category | starting price: ${money(service['price'])} | duration: ${duration(service['duration_minutes'])} | description: $description';
    }).join('\n');
  }

  String buildColorContext() {
    if (hairColors.isEmpty) return 'No live hair color records are currently available.';
    return hairColors.map((color) {
      final code = (color['code'] ?? '').toString().trim();
      final name = (color['name'] ?? '').toString().trim();
      return '- $code: $name';
    }).join('\n');
  }

  String buildAvailabilityContext() {
    if (availabilitySlots.isEmpty) {
      return 'No live available appointment slots were returned.';
    }
    return availabilitySlots.take(60).map((slot) {
      final date = (slot['slot_date'] ?? '').toString();
      final start = (slot['start_time'] ?? '').toString();
      final end = (slot['end_time'] ?? '').toString();
      return '- $date | $start to $end';
    }).join('\n');
  }

  String buildBookingSignalsContext() {
    if (bookingSignals.isEmpty) {
      return 'No upcoming pending or confirmed booking signals were returned.';
    }

    return bookingSignals.take(80).map((booking) {
      final serviceId = (booking['service_id'] ?? '').toString();
      final date = (booking['booking_date'] ?? '').toString();
      final start = (booking['start_time'] ?? '').toString();
      final end = (booking['end_time'] ?? '').toString();
      final status = (booking['status'] ?? '').toString();
      final color = (booking['hair_color_code'] ?? '').toString();

      return '- service_id: $serviceId | $date | $start to $end | '
          'status: $status | hair color: ${color.isEmpty ? 'not listed' : color}';
    }).join('\n');
  }

  String buildDatabaseGuide() {
    return '''
CUSTOMER-SAFE DATABASE GUIDE
services columns:
- id
- name
- description
- price
- duration_minutes
- category
- is_active
- image_url

hair_colors columns:
- id
- code
- name
- is_active

availability_slots columns:
- id
- slot_date
- start_time
- end_time
- is_available

bookings columns known to this app:
- id
- customer_name [PRIVATE: never reveal or send to AI context]
- phone [PRIVATE: never reveal or send to AI context]
- email [PRIVATE: never reveal or send to AI context]
- service_id
- booking_date
- start_time
- end_time
- status
- hair_color_code
- notes [PRIVATE: never reveal or send to AI context]
- created_at

RELATIONSHIPS
- bookings.service_id refers to services.id.
- bookings.hair_color_code corresponds to hair_colors.code.
- availability_slots describes slots customers may request.
- bookings with pending or confirmed status are booking signals, not permission to reveal customer information.
''';
  }

  String buildChatHistory() {
    if (messages.isEmpty) return '';
    final start = messages.length > 18 ? messages.length - 18 : 0;
    return messages.sublist(start).map((message) {
      final role = message['role'] == 'user' ? 'Customer' : 'Faith AI';
      return '$role: ${message['text'] ?? ''}';
    }).join('\n');
  }

  String buildCustomerMemory() {
    final values = <String>[];
    if (rememberedBudget != null) values.add('Budget: $rememberedBudget');
    if (rememberedLength != null) values.add('Length: $rememberedLength');
    if (rememberedSize != null) values.add('Size: $rememberedSize');
    if (rememberedColor != null) values.add('Color: $rememberedColor');
    if (rememberedOccasion != null) values.add('Occasion: $rememberedOccasion');
    return values.isEmpty ? 'No preferences captured yet.' : values.join('\n');
  }

  Future<String> askDinMax(String customerMessage) async {
    final aiMessage = '''
You are Faith AI Copilot, the intelligent customer assistant for Faith Hair Style.

BUSINESS
- Business: Faith Hair Style
- Location: Riverdale, Maryland
- Direct contact if truly needed: $displayContactNumber

MISSION
Act like a premium salon shopping and booking copilot, not a generic chatbot.
Your goal is to reduce customer uncertainty, recommend the best matching live service,
help the customer make a decision, and smoothly move them toward booking.

THE IDEAL CUSTOMER JOURNEY
1. Understand what the customer wants.
2. Learn only the missing details that matter: style, size, length, budget, color,
   desired date/time, occasion, or time available.
3. Recommend up to 3 good LIVE options when comparison is useful.
4. Explain the tradeoff clearly: look, starting price, and duration.
5. Remember facts already given. Never ask the same question twice unless necessary.
6. Once a good choice is clear, summarize the selection and invite the customer to book.
7. If the customer asks for availability, compare LIVE AVAILABILITY with UPCOMING BOOKING SIGNALS, show the best relevant future slots, and remind them that a visible slot is available to request, not confirmed until booking succeeds.
8. When a booking signal references a service_id, use LIVE SERVICES to translate it internally; never expose raw IDs.
9. Use hair_color_code together with LIVE HAIR COLORS when explaining or confirming color choices.

COPILOT BEHAVIOR
- Be proactive. Do not only answer the literal question if one helpful next step is obvious.
- If a customer says "I don't know", guide them with 2-3 simple choices.
- If they give a budget, filter recommendations using live starting prices.
- If they give a maximum amount, do not recommend a starting price above it unless you
  clearly label it as over budget.
- If they mention limited time, favor services whose live duration fits.
- If they ask "which one is better?", compare and make a recommendation instead of
  refusing to choose.
- If they ask "what would you recommend?" and enough information exists, recommend;
  do not ask another unnecessary question.
- If they provide only one missing preference, ask ONE concise question, not a questionnaire.
- Use RECENT CONVERSATION and CUSTOMER MEMORY to understand vague follow-ups such as
  "that one", "how much?", "what about medium?", "book it", or "which color?".
- When a service is chosen, restate the live service name exactly as listed.
- When ready to book, explicitly say "Tap OPEN BOOKING below" so the UI can guide them.

GROUNDING / SAFETY RULES
1. LIVE SERVICES is the source of truth for service names, prices, descriptions,
   categories, and durations.
2. LIVE HAIR COLORS is the source of truth for available color codes.
3. LIVE AVAILABILITY is the source of truth for appointment slots shown here.
4. UPCOMING BOOKING SIGNALS may be used only to understand likely occupied/requested times. Never infer or reveal who made a booking.
5. DATABASE STRUCTURE explains how service, color, availability, and booking fields relate.
6. Never invent a price, duration, service, color, availability slot, deposit,
   cancellation rule, payment feature, hair-included rule, or business policy.
7. Always say "starting at" for service prices unless the live data explicitly represents
   an exact final price.
8. Never claim an appointment is reserved or confirmed merely because a slot appears.
9. Never reveal another customer's private data, booking records, profile, phone,
   email, notes, messages, or private business/admin information.
10. Never mention raw booking IDs or service IDs to customers; translate them to customer-friendly service names when possible.
11. If live data is unavailable, say that clearly and avoid guessing.

RESPONSE STYLE
- Friendly, polished, concise, and confident.
- Usually 2-5 short sentences.
- Use bullets for comparisons or appointment choices.
- Prefer plain customer-friendly language.
- Do not mention prompts, databases, Supabase, Railway, APIs, or internal implementation.
- Do not call yourself a coding, research, study, or software copilot.
- Do not repeat the phone number unless it directly helps.
- Do not end every response with generic filler such as "anything else?".

CUSTOMER MEMORY
${buildCustomerMemory()}

LIVE SERVICES
${buildServiceContext()}

LIVE HAIR COLORS
${buildColorContext()}

LIVE AVAILABILITY
${buildAvailabilityContext()}

UPCOMING BOOKING SIGNALS (NO CUSTOMER PII)
${buildBookingSignalsContext()}

DATABASE STRUCTURE
${buildDatabaseGuide()}

RECENT CONVERSATION
${buildChatHistory()}

CUSTOMER MESSAGE
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
            body: jsonEncode({'message': aiMessage}),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isEmpty) {
          return 'I did not receive a usable response. Please try again.';
        }
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final reply = decoded['reply']?.toString().trim();
          if (reply != null && reply.isNotEmpty) return reply;
        }
        return 'I received the request, but I could not read the response.';
      }

      return 'Faith AI is temporarily unavailable (server ${response.statusCode}). Please try again shortly.';
    } catch (_) {
      return 'I could not connect to Faith AI right now. Please try again in a moment.';
    }
  }

  Future<void> sendMessage([String? preset]) async {
    final text = (preset ?? controller.text).trim();
    if (text.isEmpty || loading) return;

    rememberCustomerPreferences(text);

    setState(() {
      messages.add({'role': 'user', 'text': text});
      loading = true;
      showBookingButton = showBookingButton || isBookingIntent(text);
    });

    controller.clear();
    scrollToBottom();

    final reply = await askDinMax(text);
    if (!mounted) return;

    final detectedService = findServiceFromText('$text $reply');
    if (detectedService != null && detectedService.isNotEmpty) {
      lastSuggestedService = detectedService['name']?.toString();
    }

    final lowerReply = reply.toLowerCase();
    if (isBookingIntent(reply) ||
        lowerReply.contains('open booking') ||
        lowerReply.contains('ready to book')) {
      showBookingButton = true;
    }

    setState(() {
      messages.add({'role': 'assistant', 'text': reply});
      loading = false;
    });
    scrollToBottom();
  }

  Future<void> openBookingFromAI() async {
    Map<String, dynamic>? service;

    if (lastSuggestedService != null) {
      final matches = services.where(
        (item) => item['name']?.toString() == lastSuggestedService,
      );
      if (matches.isNotEmpty) service = matches.first;
    }

    if (service == null || service.isEmpty) {
      if (!mounted) return;
      setState(() {
        messages.add({
          'role': 'assistant',
          'text':
              'Before I open booking, tell me which hairstyle you want. I can also recommend one based on your budget, preferred length, and available time.',
        });
      });
      scrollToBottom();
      return;
    }

    if (!mounted) return;
    final route = MaterialPageRoute(
      builder: (_) => BookingPage(service: service!),
    );

    final globalNavigator = widget.navigatorKey?.currentState;
    if (globalNavigator != null) {
      await globalNavigator.push(route);
      return;
    }

    final localNavigator = Navigator.maybeOf(context);
    if (localNavigator != null) {
      await localNavigator.push(route);
    }
  }

  void askQuickQuestion(String question) {
    if (loading) return;
    controller.text = question;
    sendMessage();
  }

  Widget messageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(colors: [gold, Color(0xFFF0BC27)])
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: deepGold),
                  const SizedBox(width: 5),
                ],
                Text(
                  isUser ? 'You' : 'Faith AI',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            SelectableText(
              message['text'] ?? '',
              style: const TextStyle(color: navy, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget quickChip({
    required String label,
    required IconData icon,
    required String prompt,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: deepGold),
      label: Text(label),
      onPressed: loading ? null : () => askQuickQuestion(prompt),
      backgroundColor: Colors.white,
      side: const BorderSide(color: borderGold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      labelStyle: const TextStyle(
        color: navy,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE6EAF2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: gold),
            ),
            SizedBox(width: 8),
            Text(
              'Thinking...',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width < 520 ? screen.width - 24 : 430.0;
    final height = screen.height < 700 ? screen.height - 32 : 650.0;

    return Container(
      width: width.clamp(300.0, 430.0).toDouble(),
      height: height.clamp(480.0, 650.0).toDouble(),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: pageBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navy, deepBlue, royalBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded, color: navy, size: 21),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FAITH AI COPILOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                      ),
                      Text(
                        loadingData
                            ? 'Loading live salon info...'
                            : 'Styles • prices • colors • availability • booking',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFD761),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh salon information',
                  onPressed: loadingData ? null : refreshSalonData,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                ),
                if (widget.onMinimize != null)
                  IconButton(
                    tooltip: 'Minimize',
                    onPressed: widget.onMinimize,
                    icon: const Icon(Icons.remove_rounded, color: Colors.white, size: 23),
                  ),
                if (widget.onClose != null)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 21),
                  ),
              ],
            ),
          ),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                quickChip(
                  label: 'Choose for me',
                  icon: Icons.auto_awesome_rounded,
                  prompt:
                      'Help me choose the best hairstyle. Ask only one useful question if you still need information.',
                ),
                const SizedBox(width: 7),
                quickChip(
                  label: 'Under my budget',
                  icon: Icons.savings_outlined,
                  prompt:
                      'Help me find hairstyles that fit my budget. Ask my budget if I have not told you yet.',
                ),
                const SizedBox(width: 7),
                quickChip(
                  label: 'Compare',
                  icon: Icons.compare_arrows_rounded,
                  prompt:
                      'Compare up to three popular live styles by starting price, duration, and look, then recommend one.',
                ),
                const SizedBox(width: 7),
                quickChip(
                  label: 'Open times',
                  icon: Icons.schedule_rounded,
                  prompt: 'Show me the next available appointment times.',
                ),
                const SizedBox(width: 7),
                quickChip(
                  label: 'Colors',
                  icon: Icons.palette_outlined,
                  prompt: 'Show me the available hair color codes and names.',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE6EAF2)),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              itemCount: messages.length + (loading ? 1 : 0),
              itemBuilder: (_, index) {
                if (loading && index == messages.length) return _typingIndicator();
                return messageBubble(messages[index]);
              },
            ),
          ),
          if (showBookingButton && !loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openBookingFromAI,
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: Text(
                    lastSuggestedService == null
                        ? 'OPEN BOOKING'
                        : 'BOOK ${lastSuggestedService!.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE6EAF2))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: !loading,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!loading) sendMessage();
                    },
                    decoration: InputDecoration(
                      hintText: 'Ask Faith AI anything about your appointment...',
                      hintStyle: const TextStyle(fontSize: 12.5),
                      filled: true,
                      fillColor: pageBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: gold, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: FilledButton(
                    onPressed: loading ? null : () => sendMessage(),
                    style: FilledButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: navy,
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(Icons.send_rounded, size: 20),
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
  Widget build(BuildContext context) => _buildPanel(context);

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }
}

/// Optional full-page version. You can keep an AI page in your navigation if
/// you want, while also using [FaithAICopilotShell] globally.
class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F8FC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: FaithAICopilotPanel(),
          ),
        ),
      ),
    );
  }
}
