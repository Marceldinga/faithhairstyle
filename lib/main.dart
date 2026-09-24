import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

const supabaseUrl = 'https://lowqtmndtkgwmnyhqszp.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxvd3F0bW5kdGtnd21ueWhxc3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODgzMjQsImV4cCI6MjA4ODY2NDMyNH0.DAD_IfgcnXSnMfhu0MCl-CBVIVIEUSe9Yh7JbdvOhtw';

const whatsappNumber = '13015419875';
const instagramUrl = 'https://www.instagram.com/faith_styl_/';
const tiktokUrl = 'https://www.tiktok.com/@nfor.ako';
const bookingUrl =
    'https://docs.google.com/forms/d/1vvAIeCi7BZ-kJJff-SzTskWn2u1kD3KBlDpwXl42SpY/viewform';
const heroVideoUrl =
    'https://lowqtmndtkgwmnyhqszp.supabase.co/storage/v1/object/public/faith-videos/faith-hairstyle-hero.mp4';

// Faith Hair Style luxury business palette.
const kPrimary = Color(0xFFE4AD16); // Shining salon gold
const kPrimaryDark = Color(0xFF9A6800); // Deep gold
const kInk = Color(0xFF071A42); // Luxury navy
const kMuted = Color(0xFF667085); // Clean readable gray
const kSurface = Color(0xFFF5F8FF); // Cool premium surface
const kSoftPink = Color(0xFFFFE9A8); // Champagne gold highlight
const kBorder = Color(0xFFD8B649); // Gold border
const kCard = Color(0xFFFFFFFF);
const kDarkSurface = Color(0xFF0A2D6E);
const kAccentPink = Color(0xFFB83B68);
const kRoyalBlue = Color(0xFF0754AD);
const kRoyalBlueBright = Color(0xFF1477DE);

// Booking time display settings.
// This shows the whole business day instead of only a few fixed slots.
const bookingStartHour = 8;
const bookingEndHour = 20;
const bookingIntervalMinutes = 30;

// Simple owner PIN for opening the in-app live chat inbox.
// Change this before sharing the admin side publicly.
const ownerChatPin = '199900';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const FaithHairApp());
}

Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

  if (!opened) {
    throw Exception('Could not open $url');
  }
}

Future<void> openPrivateOwnerDashboard(BuildContext context) async {
  final pinController = TextEditingController();

  final allowed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Owner access'),
        content: TextField(
          controller: pinController,
          autofocus: true,
          obscureText: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Owner PIN',
            prefixIcon: Icon(Icons.lock_rounded),
          ),
          onSubmitted: (_) {
            Navigator.pop(
              dialogContext,
              pinController.text.trim() == ownerChatPin,
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                pinController.text.trim() == ownerChatPin,
              );
            },
            child: const Text('Open dashboard'),
          ),
        ],
      );
    },
  );

  pinController.dispose();
  if (!context.mounted) return;

  if (allowed == true) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerDashboardPage()),
    );
  } else if (allowed == false) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wrong owner PIN.')),
    );
  }
}

class FaithHairApp extends StatelessWidget {
  const FaithHairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Faith Hair Style',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          onPrimary: Colors.white,
          secondary: kInk,
          onSecondary: Colors.white,
          tertiary: kAccentPink,
          onTertiary: Colors.white,
          surface: kCard,
          onSurface: kInk,
          outline: kBorder,
          error: Color(0xFFB3261E),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: kSurface,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: kSurface,
          foregroundColor: kInk,
          centerTitle: false,
          iconTheme: IconThemeData(color: kPrimaryDark),
          actionsIconTheme: IconThemeData(color: kPrimaryDark),
          titleTextStyle: TextStyle(
            color: kInk,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: kInk,
          indicatorColor: kPrimary,
          selectedIconTheme: IconThemeData(color: Colors.white, size: 27),
          unselectedIconTheme: IconThemeData(color: Colors.white70, size: 24),
          selectedLabelTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelTextStyle: TextStyle(color: Colors.white70),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: kInk,
          indicatorColor: kDarkSurface,
          iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: kPrimary),
          ),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        cardTheme: CardThemeData(
          color: kCard,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: kBorder),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kInk,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kInk,
            side: const BorderSide(color: kPrimary, width: 1.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: kPrimaryDark,
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCard,
          prefixIconColor: kPrimaryDark,
          suffixIconColor: kPrimaryDark,
          hintStyle: const TextStyle(color: kMuted),
          labelStyle: const TextStyle(color: kMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: kPrimary, width: 1.6),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kSoftPink,
          selectedColor: kPrimary,
          checkmarkColor: kInk,
          labelStyle: const TextStyle(
            color: kInk,
            fontWeight: FontWeight.w700,
          ),
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: kCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: kInk,
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: kPrimary,
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(
          color: kBorder,
          thickness: 1,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kPrimary,
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int page = 0;
  Map<String, dynamic>? selectedService;

  static const bottomDestinations = [
    NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(
        icon: Icon(Icons.photo_library_rounded), label: 'Gallery'),
    NavigationDestination(
        icon: Icon(Icons.smart_toy_rounded), label: 'AI Help'),
    NavigationDestination(
        icon: Icon(Icons.calendar_month_rounded), label: 'Book'),
    NavigationDestination(
        icon: Icon(Icons.support_agent_rounded), label: 'Live Chat'),
    NavigationDestination(icon: Icon(Icons.share_rounded), label: 'Social'),
  ];

  static const railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.photo_library_rounded),
      label: Text('Gallery'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.smart_toy_rounded),
      label: Text('AI Help'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_month_rounded),
      label: Text('Book'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.support_agent_rounded),
      label: Text('Live Chat'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.share_rounded),
      label: Text('Social'),
    ),
  ];

  void goToBooking([Map<String, dynamic>? service]) {
    setState(() {
      selectedService = service;
      page = 3;
    });
  }

  Widget currentPage() {
    switch (page) {
      case 0:
        return HomePage(
          onBook: goToBooking,
          onOpenBooking: () => goToBooking(),
        );
      case 1:
        return GalleryPage(onBook: goToBooking);
      case 2:
        return AiPage(onBook: goToBooking);
      case 3:
        return BookingPage(initialService: selectedService);
      case 4:
        return const LiveChatPage();
      case 5:
        return const SocialPage();
      default:
        return HomePage(
          onBook: goToBooking,
          onOpenBooking: () => goToBooking(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wideScreen = MediaQuery.sizeOf(context).width >= 950;

    final appScaffold = Scaffold(
      body: Row(
        children: [
          if (wideScreen)
            NavigationRail(
              minWidth: 94,
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() => page = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              destinations: railDestinations,
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(page),
                child: currentPage(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wideScreen
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: (i) => setState(() => page = i),
              destinations: bottomDestinations,
            ),
    );

    // The AI Help tab already shows the full Faithi page, so the floating
    // launcher is hidden there. On mobile it sits above the bottom nav bar.
    return FaithAICopilotShell(
      onBook: goToBooking,
      enabled: page != 2,
      bottomOffset: wideScreen ? 16 : 88,
      child: appScaffold,
    );
  }
}

class HomePage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onBook;
  final VoidCallback onOpenBooking;

  const HomePage({
    super.key,
    required this.onBook,
    required this.onOpenBooking,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  String search = '';
  String category = 'All';
  late Future<List<Map<String, dynamic>>> servicesFuture;

  final categories = const [
    'All',
    'Braids',
    'Kids',
    'Natural',
    'Twists',
    'Locs',
  ];

  @override
  void initState() {
    super.initState();
    servicesFuture = getServices();
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    final result = await supabase
        .from('services')
        .select()
        .eq('is_active', true)
        .order('price', ascending: true);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> refreshServices() async {
    setState(() {
      servicesFuture = getServices();
    });
    await servicesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'Faith Hair Style'),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: refreshServices,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HeroSection(
              onSearchChanged: (v) => setState(() => search = v.toLowerCase()),
              onBookTap: widget.onOpenBooking,
            ),
            FaithAdvertisingBanner(onBookTap: widget.onOpenBooking),
            FaithBrandSection(onBookTap: widget.onOpenBooking),
            MaxWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: CategoryBar(
                  categories: categories,
                  selected: category,
                  onSelected: (value) => setState(() => category = value),
                ),
              ),
            ),
            MaxWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: servicesFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const LoadingState(text: 'Loading services...');
                    }

                    if (snap.hasError) {
                      return ErrorState(
                        title: 'Could not load services',
                        message: '${snap.error}',
                        onRetry: refreshServices,
                      );
                    }

                    final data = snap.data ?? [];
                    final services = data.where((s) {
                      final name = (s['name'] ?? '').toString().toLowerCase();
                      final description =
                          (s['description'] ?? '').toString().toLowerCase();
                      final cat = (s['category'] ?? '').toString();

                      final matchesSearch =
                          name.contains(search) || description.contains(search);
                      final matchesCategory = category == 'All' ||
                          cat.toLowerCase() == category.toLowerCase();

                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (services.isEmpty) {
                      return const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No services found',
                        message:
                            'Try another search or add active services in Supabase.',
                      );
                    }

                    return ServicesGrid(
                      services: services,
                      onBook: widget.onBook,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> extraActions;

  const BusinessAppBar({
    super.key,
    required this.title,
    this.extraActions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return AppBar(
      toolbarHeight: 88,
      backgroundColor: kRoyalBlue,
      foregroundColor: Colors.white,
      titleSpacing: wide ? 28 : 14,
      title: Row(
        children: [
          Tooltip(
            message: 'Faith Hair Style',
            child: GestureDetector(
              onLongPress: () => openPrivateOwnerDashboard(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              if (wide) const Text('RIVERDALE, MARYLAND',
                style: TextStyle(color: kPrimary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
            ],
          ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Instagram',
          icon: const Icon(Icons.camera_alt_rounded, color: kPrimary),
          onPressed: () => openUrl(instagramUrl),
        ),
        IconButton(
          tooltip: 'TikTok',
          icon: const Icon(Icons.music_note_rounded, color: kPrimary),
          onPressed: () => openUrl(tiktokUrl),
        ),
        ...extraActions,
        const SizedBox(width: 8),
      ],
    );
  }
}

class HeroSection extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBookTap;

  const HeroSection({
    super.key,
    required this.onSearchChanged,
    required this.onBookTap,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  late final Future<String?> heroImageFuture;
  late final VideoPlayerController videoController;
  bool videoReady = false;

  @override
  void initState() {
    super.initState();
    heroImageFuture = loadHeroImage();
    videoController = VideoPlayerController.networkUrl(
      Uri.parse(heroVideoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      await videoController.initialize();
      await videoController.setVolume(0);
      await videoController.setLooping(true);
      await videoController.play();
      if (mounted) setState(() => videoReady = true);
    } catch (_) {
      // Keep the Supabase service image as the hero fallback.
    }
  }

  @override
  void dispose() {
    videoController.dispose();
    super.dispose();
  }

  Future<String?> loadHeroImage() async {
    try {
      final rows = await Supabase.instance.client
          .from('services')
          .select('image_url')
          .eq('is_active', true)
          .limit(12);
      for (final row in List<Map<String, dynamic>>.from(rows)) {
        final url = (row['image_url'] ?? '').toString().trim();
        if (url.isNotEmpty) return url;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wideScreen = MediaQuery.sizeOf(context).width >= 850;
    return FutureBuilder<String?>(
      future: heroImageFuture,
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: wideScreen ? 650 : 610),
          color: kInk,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: imageUrl == null
                    ? Container(color: kInk)
                    : Image.network(imageUrl, fit: BoxFit.cover),
              ),
              if (videoReady)
                Positioned.fill(
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: videoController.value.size.width,
                        height: videoController.value.size.height,
                        child: VideoPlayer(videoController),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xA6071A42), Color(0x520A3C86), Color(0x8C071A42)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wideScreen ? 42 : 18,
                  vertical: wideScreen ? 72 : 42,
                ),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1450),
                    padding: EdgeInsets.all(wideScreen ? 42 : 22),
                    decoration: BoxDecoration(
                      border: Border.all(color: kPrimary.withValues(alpha: .55)),
                    ),
                    child: _HeroCopy(
                      onSearchChanged: widget.onSearchChanged,
                      onBookTap: widget.onBookTap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBookTap;

  const _HeroCopy({
    required this.onSearchChanged,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('PROTECTIVE STYLES • RIVERDALE, MARYLAND',
          textAlign: TextAlign.center,
          style: TextStyle(color: kPrimary, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 3.2)),
        const SizedBox(height: 22),
        Text(
          'Beautiful hair.\nMade for you.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 82 : 48,
            height: 1.0,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Neat parts, gentle hands, and beautiful protective styles.\nChoose your style, then request your appointment.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18, height: 1.55),
        ),
        const SizedBox(height: 30),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onBookTap,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('BOOK YOUR APPOINTMENT  →'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: kInk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 19),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openUrl('https://wa.me/$whatsappNumber'),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('WHATSAPP'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: kPrimary, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openUrl('tel:+13015419875'),
              icon: const Icon(Icons.call_rounded),
              label: const Text('CALL +1 301-541-9875'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: kPrimary, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: wide ? 680 : double.infinity,
          child: TextField(
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              filled: true, fillColor: Colors.white,
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search braids, cornrows, kids styles, twists...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kPrimary, width: 2)),
            ),
          ),
        ),
      ],
    );
  }
}

class HeroInfoCard extends StatelessWidget {
  const HeroInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4B3621).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kPrimary.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrustRow(
            icon: Icons.verified_rounded,
            title: 'Professional finish',
            text: 'Neat protective styles with clean parts.',
          ),
          SizedBox(height: 16),
          _TrustRow(
            icon: Icons.favorite_rounded,
            title: 'Comfort first',
            text: 'Gentle tension for kids and adults.',
          ),
          SizedBox(height: 16),
          _TrustRow(
            icon: Icons.photo_camera_rounded,
            title: 'Send a picture',
            text: 'Share your inspiration photo on WhatsApp.',
          ),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TrustRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          child: Icon(icon, color: kPrimary, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class FaithAdvertisingBanner extends StatefulWidget {
  final VoidCallback onBookTap;

  const FaithAdvertisingBanner({
    super.key,
    required this.onBookTap,
  });

  @override
  State<FaithAdvertisingBanner> createState() => _FaithAdvertisingBannerState();
}

class _FaithAdvertisingBannerState extends State<FaithAdvertisingBanner> {
  int currentMessage = 0;
  Timer? timer;

  static const messages = [
    (
      icon: Icons.auto_awesome_rounded,
      title: 'YOUR NEXT LOOK STARTS HERE',
      message:
          'Beautiful protective styles, neat parts, and a polished finish created with care at Faith Hair Style.',
      action: 'BOOK YOUR STYLE',
    ),
    (
      icon: Icons.favorite_rounded,
      title: 'BRAIDS MADE WITH CARE',
      message:
          'Comfort matters. Choose a style you love and let Faith Hair Style create a clean, confident look for you.',
      action: 'EXPLORE & BOOK',
    ),
    (
      icon: Icons.location_on_rounded,
      title: 'FAITH HAIR STYLE • RIVERDALE, MD',
      message:
          'Professional protective styling for adults and kids. Browse styles, check starting prices, and request your appointment online.',
      action: 'BOOK NOW',
    ),
    (
      icon: Icons.photo_camera_rounded,
      title: 'HAVE A STYLE IN MIND?',
      message:
          'Send your inspiration photo on WhatsApp and Faith Hair Style can help you choose the right size, length, and finish.',
      action: 'MESSAGE US',
    ),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        currentMessage = (currentMessage + 1) % messages.length;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = messages[currentMessage];
    final compact = MediaQuery.sizeOf(context).width < 650;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kRoyalBlue, kDarkSurface, kInk],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: MaxWidth(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 18 : 28,
            vertical: compact ? 20 : 24,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.03, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(currentMessage),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kPrimary.withValues(alpha: .65)),
              ),
              child: compact
                  ? Column(
                      children: [
                        _AdvertisingMessageContent(item: item),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: item.action == 'MESSAGE US'
                                ? () => openUrl('https://wa.me/$whatsappNumber')
                                : widget.onBookTap,
                            icon: Icon(
                              item.action == 'MESSAGE US'
                                  ? Icons.chat_rounded
                                  : Icons.calendar_month_rounded,
                            ),
                            label: Text(item.action),
                            style: FilledButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: kInk,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _AdvertisingMessageContent(item: item)),
                        const SizedBox(width: 24),
                        FilledButton.icon(
                          onPressed: item.action == 'MESSAGE US'
                              ? () => openUrl('https://wa.me/$whatsappNumber')
                              : widget.onBookTap,
                          icon: Icon(
                            item.action == 'MESSAGE US'
                                ? Icons.chat_rounded
                                : Icons.calendar_month_rounded,
                          ),
                          label: Text(item.action),
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: kInk,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdvertisingMessageContent extends StatelessWidget {
  final ({IconData icon, String title, String message, String action}) item;

  const _AdvertisingMessageContent({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(item.icon, color: kInk, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FaithBrandSection extends StatelessWidget {
  final VoidCallback onBookTap;

  const FaithBrandSection({
    super.key,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return MaxWidth(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 6),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(compact ? 20 : 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .06),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'DISCOVER FAITH HAIR STYLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kPrimaryDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 2.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Protective styles that look beautiful and feel like you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kInk,
                      fontSize: compact ? 27 : 38,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'From braids and twists to kids styles and natural looks, Faith Hair Style makes it easy to explore your options, see starting prices, and request your appointment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kMuted,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (_, constraints) {
                      final oneColumn = constraints.maxWidth < 680;
                      final cards = [
                        const _BrandBenefitCard(
                          icon: Icons.content_cut_rounded,
                          title: 'Neat, polished styles',
                          text:
                              'Clean parts and beautiful finishing for a confident look.',
                        ),
                        const _BrandBenefitCard(
                          icon: Icons.favorite_outline_rounded,
                          title: 'Comfort focused',
                          text:
                              'Protective styling with attention to gentle tension and care.',
                        ),
                        const _BrandBenefitCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Easy online booking',
                          text:
                              'Choose your style, preferred date, and time right from your phone.',
                        ),
                      ];

                      if (oneColumn) {
                        return Column(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i != cards.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            Expanded(child: cards[i]),
                            if (i != cards.length - 1)
                              const SizedBox(width: 14),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: onBookTap,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('BOOK AN APPOINTMENT'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: kInk,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => openUrl('https://wa.me/$whatsappNumber'),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('SEND YOUR STYLE PHOTO'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(
              eyebrow: 'FIND YOUR STYLE',
              title: 'Browse styles & starting prices',
              subtitle:
                  'Choose a category or search below to find the look you want.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _BrandBenefitCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder.withValues(alpha: .75)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kSoftPink,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: kPrimaryDark),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: kInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              color: kMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kPrimaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kInk,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kMuted, height: 1.4),
        ),
      ],
    );
  }
}

class CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = categories[i];
          return ChoiceChip(
            label: Text(c),
            selected: selected == c,
            selectedColor: kSoftPink,
            checkmarkColor: kPrimary,
            side: const BorderSide(color: kBorder),
            labelStyle: TextStyle(
              color: selected == c ? kPrimaryDark : kInk,
              fontWeight: selected == c ? FontWeight.w800 : FontWeight.w500,
            ),
            onSelected: (_) => onSelected(c),
          );
        },
      ),
    );
  }
}

class ServicesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final ValueChanged<Map<String, dynamic>> onBook;

  const ServicesGrid({
    super.key,
    required this.services,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1180
            ? 4
            : width >= 850
                ? 3
                : width >= 560
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 458,
          ),
          itemBuilder: (_, i) {
            return ServiceCard(
              service: services[i],
              onBook: () => onBook(services[i]),
            );
          },
        );
      },
    );
  }
}

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onBook;

  const ServiceCard({super.key, required this.service, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final image = (service['image_url'] ?? '').toString().trim();
    final name = (service['name'] ?? 'Service').toString();
    final category = (service['category'] ?? 'Style').toString();
    final duration = formatDuration(service['duration_minutes']);
    final price = formatPrice(service['price']);
    final description = (service['description'] ??
            'Beautiful protective style with clean parts, gentle tension, and a polished finish.')
        .toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 218,
            width: double.infinity,
            color: const Color(0xFFFFF4D3),
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    width: double.infinity,
                    height: 218,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const ServicePlaceholder(),
                  )
                : const ServicePlaceholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7),
                        child: Text('•', style: TextStyle(color: kMuted)),
                      ),
                      Text(
                        duration,
                        style: const TextStyle(
                          color: kMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, height: 1.35),
                  ),
                  const Spacer(),
                  Text(
                    price,
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ServicePlaceholder extends StatelessWidget {
  const ServicePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kSoftPink,
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onBook;

  const GalleryPage({super.key, required this.onBook});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<Map<String, dynamic>>> galleryFuture;

  @override
  void initState() {
    super.initState();
    galleryFuture = getGallery();
  }

  Future<List<Map<String, dynamic>>> getGallery() async {
    final result = await Supabase.instance.client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> refreshGallery() async {
    setState(() => galleryFuture = getGallery());
    await galleryFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'Gallery'),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: refreshGallery,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            const MaxWidth(
              child: PageHeader(
                title: 'See Our Work',
                subtitle:
                    'Photos help customers choose the right style before booking.',
              ),
            ),
            const SizedBox(height: 18),
            MaxWidth(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: galleryFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LoadingState(text: 'Loading gallery...');
                  }

                  if (snap.hasError) {
                    return ErrorState(
                      title: 'Could not load gallery',
                      message: '${snap.error}',
                      onRetry: refreshGallery,
                    );
                  }

                  final items = (snap.data ?? [])
                      .where((item) => (item['image_url'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty)
                      .toList();

                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.photo_library_outlined,
                      title: 'No gallery yet',
                      message:
                          'Add image_url to your services table in Supabase to show photos here.',
                    );
                  }

                  return GalleryGrid(items: items, onBook: widget.onBook);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onBook;

  const GalleryGrid({super.key, required this.items, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final width = constraints.maxWidth;
      final count = width >= 1000
          ? 3
          : width >= 650
              ? 2
              : 1;

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          mainAxisExtent: 356,
        ),
        itemBuilder: (_, i) => GalleryCard(
          item: items[i],
          onBook: () => onBook(items[i]),
        ),
      );
    });
  }
}

class GalleryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onBook;

  const GalleryCard({super.key, required this.item, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final image = (item['image_url'] ?? '').toString().trim();
    final name = (item['name'] ?? 'Hairstyle').toString();
    final description = (item['description'] ??
            'Neat, beautiful, customer-friendly protective style.')
        .toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 226,
            width: double.infinity,
            color: const Color(0xFFFFF4D3),
            child: Image.network(
              image,
              width: double.infinity,
              height: 226,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const ServicePlaceholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted, height: 1.35),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.calendar_month_rounded),
                    label: const Text('Book This Style'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class AiPage extends StatelessWidget {
  final ValueChanged<Map<String, dynamic>> onBook;

  const AiPage({
    super.key,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return AIChatPage(onBook: onBook);
  }
}

// ============================================================
// FAITH AI / FAITHI COPILOT
// Current frontend for Faithi backend v4.4+
//
// - Uses current Railway production endpoint
// - Voice input + TTS output
// - Live Supabase services/colors for UI + booking
// - Uses exactly one AI model: meta-llama/Llama-3.1-8B-Instruct
// - One-model AI path only
// - Displays real service images returned/matched from Supabase
// - Preserves conversation history and customer preferences
// ============================================================

// ============================================================
// 1. SHELL
// ============================================================

class FaithAICopilotShell extends StatefulWidget {
  const FaithAICopilotShell({
    super.key,
    required this.child,
    required this.onBook,
    this.enabled = true,
    this.bottomOffset = 16,
  });

  final Widget child;
  final ValueChanged<Map<String, dynamic>> onBook;
  final bool enabled;
  final double bottomOffset;

  @override
  State<FaithAICopilotShell> createState() => _FaithAICopilotShellState();
}

class _FaithAICopilotShellState extends State<FaithAICopilotShell> {
  bool _isOpen = false;

  void _toggleChat() => setState(() => _isOpen = !_isOpen);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            right: 16,
            bottom: widget.bottomOffset,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      alignment: Alignment.bottomRight,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: _isOpen
                      ? FaithAICopilotPanel(
                          key: const ValueKey('panel'),
                          onBook: widget.onBook,
                          onClose: _toggleChat,
                          onMinimize: _toggleChat,
                        )
                      : _CopilotLauncher(
                          key: const ValueKey('launcher'),
                          hasActiveChat:
                              FaithCopilotController.instance.hasChatHistory,
                          onTap: _toggleChat,
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// 2. LAUNCHER
// ============================================================

class _CopilotLauncher extends StatelessWidget {
  const _CopilotLauncher({
    super.key,
    required this.onTap,
    required this.hasActiveChat,
  });

  final VoidCallback onTap;
  final bool hasActiveChat;

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
            colors: [AppColors.navy, AppColors.royalBlue],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gold, width: 1.4),
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
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.navy,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Faithi',
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

// ============================================================
// 3. FULL PAGE
// ============================================================

class AIChatPage extends StatelessWidget {
  const AIChatPage({
    super.key,
    required this.onBook,
  });

  final ValueChanged<Map<String, dynamic>> onBook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('Faithi'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: FaithAICopilotPanel(onBook: onBook),
        ),
      ),
    );
  }
}

// ============================================================
// 4. MAIN PANEL
// ============================================================

class FaithAICopilotPanel extends StatefulWidget {
  const FaithAICopilotPanel({
    super.key,
    required this.onBook,
    this.onClose,
    this.onMinimize,
  });

  final ValueChanged<Map<String, dynamic>> onBook;
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;

  @override
  State<FaithAICopilotPanel> createState() => _FaithAICopilotPanelState();
}

class _FaithAICopilotPanelState extends State<FaithAICopilotPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FaithCopilotController _controller;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _speechReady = false;
  bool _isListening = false;
  String? _speechError;

  @override
  void initState() {
    super.initState();
    _controller = FaithCopilotController.instance;
    _controller.addListener(_onControllerChanged);
    _initializeSpeech();

    if (_controller.services.isEmpty) {
      _controller.loadSalonData();
    }

    _controller.initializeVoice();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _speech.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() => _scrollToBottom();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 400,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
            _speechError = error.errorMsg;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _speechReady = available;
        _speechError = available ? null : 'Voice input is not available.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _speechReady = false;
        _speechError = 'Voice input could not be initialized.';
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_controller.isLoading) return;

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    await _controller.stopSpeaking();

    if (!_speechReady) {
      await _initializeSpeech();
      if (!_speechReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_speechError ?? 'Microphone unavailable.')),
        );
        return;
      }
    }

    setState(() {
      _isListening = true;
      _speechError = null;
    });

    await _speech.listen(
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        if (!mounted) return;
        final words = _removeDuplicatedSpeech(result.recognizedWords.trim());

        if (words.isNotEmpty) {
          _textController.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
        }

        if (result.finalResult) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  String _removeDuplicatedSpeech(String input) {
    if (input.length < 2) return input;
    if (input.length.isEven) {
      final half = input.length ~/ 2;
      final first = input.substring(0, half);
      final second = input.substring(half);
      if (first.toLowerCase() == second.toLowerCase()) return first;
    }
    return input;
  }

  void _sendMessage([String? preset]) {
    final text = (preset ?? _textController.text).trim();
    if (text.isEmpty || _controller.isLoading) return;
    _textController.clear();
    _controller.sendMessage(text);
  }

  Future<void> _openBooking() async {
    final service = _controller.getSuggestedService();

    if (service == null) {
      _controller.addSystemMessage(
        'Tell me which hairstyle you want first. I can also recommend one for you.',
      );
      return;
    }

    // Use the website's existing booking flow. MainPage stores the selected
    // service and opens BookingPage(initialService: service).
    widget.onBook(service);
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = math.min(430.0, math.max(280.0, screen.width - 24));
    final height = math.min(650.0, math.max(320.0, screen.height - 32));

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 1.3),
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
              _buildHeader(),
              _buildQuickActions(),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  itemCount: _controller.messages.length +
                      (_controller.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_controller.isLoading &&
                        index == _controller.messages.length) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: _controller.messages[index]);
                  },
                ),
              ),
              if (_controller.showBookingButton && !_controller.isLoading)
                _buildBookingButton(),
              if (_isListening) _buildListeningBanner(),
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navy,
            AppColors.deepBlue,
            AppColors.royalBlue,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.navy,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FAITHI AI COPILOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                Text(
                  _controller.isLoadingData
                      ? 'Loading live salon info...'
                      : 'Styles • prices • colors • availability',
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
            tooltip:
                _controller.voiceEnabled ? 'Turn voice off' : 'Turn voice on',
            onPressed: _controller.toggleVoice,
            icon: Icon(
              _controller.voiceEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: _controller.voiceEnabled
                  ? const Color(0xFFFFD761)
                  : Colors.white70,
              size: 21,
            ),
          ),
          IconButton(
            tooltip: 'Refresh salon data',
            onPressed:
                _controller.isLoadingData ? null : _controller.loadSalonData,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 20,
            ),
          ),
          if (widget.onMinimize != null)
            IconButton(
              tooltip: 'Minimize',
              onPressed: widget.onMinimize,
              icon: const Icon(
                Icons.remove_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Close',
              onPressed: widget.onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _QuickChip(
            label: 'Choose for me',
            icon: Icons.auto_awesome_rounded,
            onTap: () => _sendMessage(
              'Recommend a hairstyle for me using the live Faith Hairstyle services.',
            ),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Under my budget',
            icon: Icons.savings_outlined,
            onTap: () =>
                _sendMessage('Help me find a hairstyle within my budget.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Colors',
            icon: Icons.palette_outlined,
            onTap: () => _sendMessage('Show me the available hair colors.'),
            isLoading: _controller.isLoading,
          ),
          const SizedBox(width: 7),
          _QuickChip(
            label: 'Open times',
            icon: Icons.schedule_rounded,
            onTap: () =>
                _sendMessage('Show me the next available appointment times.'),
            isLoading: _controller.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton() {
    final name = _controller.lastSuggestedServiceName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _openBooking,
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(
            name == null ? 'OPEN BOOKING' : 'BOOK ${name.toUpperCase()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListeningBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: const Row(
        children: [
          _VoicePulse(),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Listening... speak naturally.',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: !_controller.isLoading,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask Faithi anything...',
                filled: true,
                fillColor: AppColors.pageBackground,
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
                  borderSide:
                      const BorderSide(color: AppColors.gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: IconButton.filled(
              tooltip: _isListening ? 'Stop listening' : 'Voice input',
              onPressed: _controller.isLoading ? null : _toggleListening,
              style: IconButton.styleFrom(
                backgroundColor:
                    _isListening ? const Color(0xFFD84A4A) : Colors.white,
                foregroundColor:
                    _isListening ? Colors.white : AppColors.deepGold,
                side: const BorderSide(color: AppColors.borderGold),
              ),
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 46,
            height: 46,
            child: FilledButton(
              onPressed: _controller.isLoading ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. MESSAGE UI
// ============================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(13),
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [AppColors.gold, Color(0xFFF0BC27)],
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.deepGold,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  isUser ? 'You' : 'Faithi',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            _MarkdownText(text: message.text),
            if (!isUser && message.serviceImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ServiceRecommendationImages(images: message.serviceImages),
            ],
            if (!isUser && message.colors.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ColorResults(colors: message.colors),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 6. SERVICE IMAGES
// ============================================================

class _ServiceRecommendationImages extends StatelessWidget {
  const _ServiceRecommendationImages({required this.images});

  final List<ServiceImageAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < images.length; i++) ...[
          _ServiceImageCard(image: images[i]),
          if (i != images.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ServiceImageCard extends StatelessWidget {
  const _ServiceImageCard({required this.image});

  final ServiceImageAttachment image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Image.network(
              image.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                );
              },
              errorBuilder: (_, __, ___) {
                return Container(
                  alignment: Alignment.center,
                  color: AppColors.pageBackground,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.muted,
                        size: 34,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Style image unavailable',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.serviceName,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (image.price != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Starting at ${image.price}',
                      style: const TextStyle(
                        color: AppColors.deepGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 7. COLORS
// ============================================================

class _ColorResults extends StatelessWidget {
  const _ColorResults({required this.colors});

  final List<HairColorResult> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((color) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGold),
          ),
          child: Text(
            '${color.code} • ${color.name}',
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================
// 8. MARKDOWN-LIKE TEXT
// ============================================================

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final split = text.split('**');

    for (int i = 0; i < split.length; i++) {
      if (split[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: split[i],
          style: TextStyle(
            fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
            color: AppColors.navy,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

// ============================================================
// 9. QUICK CHIP
// ============================================================

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: AppColors.deepGold),
      label: Text(label),
      onPressed: isLoading ? null : onTap,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.borderGold),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelStyle: const TextStyle(
        color: AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ============================================================
// 10. VOICE PULSE
// ============================================================

class _VoicePulse extends StatefulWidget {
  const _VoicePulse();

  @override
  State<_VoicePulse> createState() => _VoicePulseState();
}

class _VoicePulseState extends State<_VoicePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: .85, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFD84A4A),
        child: Icon(Icons.mic_rounded, size: 14, color: Colors.white),
      ),
    );
  }
}

// ============================================================
// 11. TYPING INDICATOR
// ============================================================

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = index * .2;
                final progress =
                    (_controller.value - delay).clamp(0.0, 1.0);
                final offset = math.sin(progress * math.pi * 2) * -4;

                return Transform.translate(
                  offset: Offset(0, offset < 0 ? offset : 0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ============================================================
// 12. CONTROLLER — ONE PRIMARY MODEL + NATURAL VOICE
// ============================================================

class FaithCopilotController extends ChangeNotifier {
  static final FaithCopilotController instance =
      FaithCopilotController._internal();

  FaithCopilotController._internal() {
    _messages.add(
      const ChatMessage(
        text:
            'Hi! I’m Faithi, your Faith Hairstyle salon copilot. '
            'Tell me the look you want, your budget, your preferred color, '
            'or when you want to come in.',
        isUser: false,
      ),
    );
  }

  // CURRENT Railway production backend.
  static const String _apiBase =
      'https://theyoungshallgrow-api-production.up.railway.app';

  static const String _aiEndpoint = '$_apiBase/chat';

  // ONE MODEL ONLY. The backend should honor this model policy.
  static const String _primaryModel =
      'meta-llama/Llama-3.1-8B-Instruct';

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterTts _tts = FlutterTts();
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasChatHistory => _messages.length > 1;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingData = false;
  bool get isLoadingData => _isLoadingData;

  bool _showBookingButton = false;
  bool get showBookingButton => _showBookingButton;

  bool _voiceEnabled = true;
  bool get voiceEnabled => _voiceEnabled;

  bool _voiceInitialized = false;

  final CustomerPreferences preferences = CustomerPreferences();

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> hairColors = [];

  String? lastSuggestedServiceName;
  String? lastSuggestedServiceId;
  DateTime? _lastSendAt;

  // ==========================================================
  // TTS / NATURAL ENGLISH VOICE
  // ==========================================================

  Future<void> initializeVoice() async {
    if (_voiceInitialized) return;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      // Makes long answers sound more continuous when supported.
      try {
        await _tts.awaitSpeakCompletion(true);
      } catch (_) {}

      try {
        final dynamic rawVoices = await _tts.getVoices;

        if (rawVoices is List && rawVoices.isNotEmpty) {
          final voices = rawVoices
              .whereType<Map>()
              .map((voice) => Map<dynamic, dynamic>.from(voice))
              .where((voice) {
                final locale =
                    (voice['locale'] ?? '').toString().toLowerCase();
                return locale.startsWith('en');
              })
              .toList();

          voices.sort((a, b) => _voiceScore(b).compareTo(_voiceScore(a)));

          if (voices.isNotEmpty) {
            final selected = voices.first;
            final name = (selected['name'] ?? '').toString();
            final locale = (selected['locale'] ?? 'en-US').toString();

            if (name.isNotEmpty) {
              await _tts.setVoice({
                'name': name,
                'locale': locale,
              });
            }
          }
        }
      } catch (_) {
        // If the platform does not expose voices, use its normal English voice.
      }

      _voiceInitialized = true;
    } catch (_) {
      _voiceInitialized = false;
    }
  }

  int _voiceScore(Map<dynamic, dynamic> voice) {
    final name = (voice['name'] ?? '').toString().toLowerCase();
    final locale = (voice['locale'] ?? '').toString().toLowerCase();

    var score = 0;

    if (locale == 'en-us' || locale == 'en_us') score += 60;
    if (locale.startsWith('en-us') || locale.startsWith('en_us')) score += 35;
    if (locale.startsWith('en')) score += 15;

    // Prefer names commonly used by high-quality natural/neural voices.
    for (final word in [
      'natural',
      'neural',
      'premium',
      'enhanced',
      'online',
      'wavenet',
      'jenny',
      'aria',
      'ava',
      'samantha',
      'zira',
      'susan',
      'victoria',
      'karen',
      'moira',
      'female',
    ]) {
      if (name.contains(word)) score += 20;
    }

    // De-prioritize obviously basic/legacy synthesizers when alternatives exist.
    for (final word in ['compact', 'legacy', 'espeak']) {
      if (name.contains(word)) score -= 30;
    }

    return score;
  }

  Future<void> toggleVoice() async {
    _voiceEnabled = !_voiceEnabled;

    if (!_voiceEnabled) {
      await _tts.stop();
    } else {
      await initializeVoice();
    }

    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;

    final cleaned = _textForSpeech(text);
    if (cleaned.isEmpty) return;

    try {
      await initializeVoice();
      await _tts.stop();

      for (final chunk in _speechChunks(cleaned)) {
        if (!_voiceEnabled) break;
        await _tts.speak(chunk);
      }
    } catch (_) {}
  }

  List<String> _speechChunks(String text, {int maxChars = 1200}) {
    if (text.length <= maxChars) return [text];

    final words = text.split(RegExp(r'\s+'));
    final chunks = <String>[];
    var current = StringBuffer();

    for (final word in words) {
      if (word.isEmpty) continue;

      if (current.isNotEmpty && current.length + word.length + 1 > maxChars) {
        chunks.add(current.toString().trim());
        current = StringBuffer();
      }

      if (current.isNotEmpty) current.write(' ');
      current.write(word);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trim());
    }

    return chunks.where((chunk) => chunk.isNotEmpty).toList();
  }

  String _textForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAllMapped(
          RegExp(r'`([^`]*)`'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'https?:\/\/\S+', caseSensitive: false), '')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '')
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]*\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^[•*\-]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ==========================================================
  // PUBLIC SALON DATA FOR UI
  // ==========================================================

  Future<void> loadSalonData() async {
    _isLoadingData = true;
    notifyListeners();

    try {
      final rows = await _supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);

      services = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      services = [];
    }

    try {
      final rows = await _supabase
          .from('hair_colors')
          .select()
          .eq('is_active', true)
          .order('code', ascending: true);

      hairColors = List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      hairColors = [];
    }

    _isLoadingData = false;
    notifyListeners();
  }

  // ==========================================================
  // SEND MESSAGE
  // ==========================================================

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || _isLoading) return;

    final now = DateTime.now();
    if (_lastSendAt != null &&
        now.difference(_lastSendAt!).inMilliseconds < 450) {
      return;
    }
    _lastSendAt = now;

    await stopSpeaking();
    preferences.extractAndRemember(cleanText);

    _messages.add(ChatMessage(text: cleanText, isUser: true));

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _fetchAIResponse(cleanText);
      final reply = _removeRepeatedGreeting(result.reply);

      _processAIResponse(
        userText: cleanText,
        reply: reply,
        structuredRows: result.rows,
        meta: result.meta,
      );

      await _speak(reply);
    } catch (error) {
      const message =
          'I could not reach the Faithi AI service right now. Please try again.';

      _messages.add(
        const ChatMessage(text: message, isUser: false),
      );

      await _speak(message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // API
  // ==========================================================

  Future<FaithiApiResult> _fetchAIResponse(String customerMessage) async {
    final historySource = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <ChatMessage>[];

    final recentHistory = historySource.length > 12
        ? historySource.sublist(historySource.length - 12)
        : historySource;

    final history = recentHistory
        .map(
          (message) => {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();

    final body = {
      'message': customerMessage,
      'history': history,

      // ONE PRIMARY MODEL ONLY.
      'model': _primaryModel,
      'primary_model': _primaryModel,
      'single_model_only': true,

      'domain': 'hair_salon',
      'page': 'ai_chat',
      'safe_mode': true,
      'advanced_mode': true,
      'context': {
        'app': 'faith_hairstyle',
        'assistant': 'faithi',
        'backend_generation': 'v4.4+',
        'model_policy': {
          'primary_model': _primaryModel,
          'single_model_only': true,
        },
        'response_style': {
          'natural_conversation': true,
          'chatgpt_like': true,
          'context_aware': true,
          'warm_and_professional': true,
          'answer_directly': true,
          'avoid_repeated_greetings': true,
          'avoid_robotic_language': true,
          'avoid_unnecessary_disclaimers': true,
          'ask_follow_up_only_when_needed': true,
          'use_conversation_history': true,
          'use_live_salon_data_for_business_facts': true,
          'do_not_invent_prices_services_colors_or_availability': true,
        },
        'customer_preferences': preferences.toMap(),
        'frontend_capabilities': {
          'service_images': true,
          'booking_navigation': true,
          'voice_input': true,
          'voice_output': true,
        },
      },
    };

    final response = await http
        .post(
          Uri.parse(_aiEndpoint),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Faithi server returned ${response.statusCode}: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid Faithi response.');
    }

    final reply = (decoded['reply'] ?? '').toString().trim();
    if (reply.isEmpty) {
      throw Exception('Faithi returned no reply.');
    }

    final rows = _extractDataframeRows(decoded['dataframe']);

    final meta = decoded['meta'] is Map
        ? Map<String, dynamic>.from(decoded['meta'])
        : <String, dynamic>{};

    return FaithiApiResult(reply: reply, rows: rows, meta: meta);
  }

  // ==========================================================
  // DATAFRAME PARSER
  // ==========================================================

  List<Map<String, dynamic>> _extractDataframeRows(dynamic dataframe) {
    if (dataframe == null) return [];

    if (dataframe is Map) {
      final rawRows = dataframe['rows'];

      if (rawRows is List) {
        return rawRows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }

      final columns = dataframe['columns'];
      final data = dataframe['data'];

      if (columns is List && data is List) {
        final names = columns.map((e) => e.toString()).toList();
        final output = <Map<String, dynamic>>[];

        for (final raw in data) {
          if (raw is! List) continue;
          final row = <String, dynamic>{};

          for (int i = 0; i < names.length && i < raw.length; i++) {
            row[names[i]] = raw[i];
          }

          output.add(row);
        }

        return output;
      }

      if (dataframe.containsKey('name') ||
          dataframe.containsKey('image_url')) {
        return [Map<String, dynamic>.from(dataframe)];
      }
    }

    if (dataframe is List) {
      return dataframe
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    return [];
  }

  // ==========================================================
  // PROCESS BACKEND RESULT
  // ==========================================================

  void _processAIResponse({
    required String userText,
    required String reply,
    required List<Map<String, dynamic>> structuredRows,
    required Map<String, dynamic> meta,
  }) {
    final serviceMatches = <Map<String, dynamic>>[];
    final colorMatches = <HairColorResult>[];
    final seenServices = <String>{};
    final seenColors = <String>{};

    for (final row in structuredRows) {
      final table =
          (row['_table'] ?? row['source_table'] ?? '').toString().toLowerCase();

      final name = (row['name'] ?? '').toString().trim();
      final imageUrl = (row['image_url'] ?? '').toString().trim();
      final code = (row['code'] ?? row['detail'] ?? '').toString().trim();

      final looksLikeColor = table.contains('color') ||
          (code.isNotEmpty &&
              imageUrl.isEmpty &&
              _findLocalColor(code, name) != null);

      if (looksLikeColor && name.isNotEmpty) {
        final key = '$code|$name'.toLowerCase();

        if (seenColors.add(key)) {
          colorMatches.add(HairColorResult(code: code, name: name));
        }
        continue;
      }

      final localService = _matchStructuredService(row);

      if (localService != null) {
        final key = localService['id']?.toString() ??
            localService['name']?.toString() ??
            '';

        if (seenServices.add(key)) {
          serviceMatches.add(localService);
        }
      }
    }

    if (serviceMatches.isEmpty) {
      serviceMatches.addAll(_findServicesFromText(reply));
    }

    if (serviceMatches.isEmpty) {
      serviceMatches.addAll(_findServicesFromText(userText));
    }

    if (colorMatches.isEmpty && _isColorIntent(userText)) {
      final specific = _findColorsFromText('$userText $reply');

      if (specific.isNotEmpty) {
        colorMatches.addAll(specific);
      } else if (_asksToShowColors(userText)) {
        colorMatches.addAll(
          hairColors.take(32).map(
                (row) => HairColorResult(
                  code: (row['code'] ?? '').toString(),
                  name: (row['name'] ?? '').toString(),
                ),
              ),
        );
      }
    }

    final images = <ServiceImageAttachment>[];

    for (final service in serviceMatches) {
      final imageUrl = (service['image_url'] ?? '').toString().trim();
      if (!_isHttpUrl(imageUrl)) continue;

      images.add(
        ServiceImageAttachment(
          serviceId: service['id']?.toString(),
          serviceName: (service['name'] ?? 'Hairstyle').toString(),
          url: imageUrl,
          price: _money(service['price']),
        ),
      );

      if (images.length >= 3) break;
    }

    _messages.add(
      ChatMessage(
        text: reply,
        isUser: false,
        serviceImages: images,
        colors: colorMatches,
      ),
    );

    if (serviceMatches.isNotEmpty) {
      final selected = serviceMatches.first;
      lastSuggestedServiceName = selected['name']?.toString();
      lastSuggestedServiceId = selected['id']?.toString();
    }

    final intent = (meta['intent'] ?? '').toString().toLowerCase();

    if (_isBookingIntent(userText) ||
        _isBookingIntent(reply) ||
        intent == 'booking' ||
        serviceMatches.isNotEmpty) {
      _showBookingButton =
          serviceMatches.isNotEmpty || getSuggestedService() != null;
    }
  }

  Map<String, dynamic>? _matchStructuredService(Map<String, dynamic> row) {
    final id = (row['id'] ?? row['service_id'] ?? '').toString();

    if (id.isNotEmpty) {
      for (final service in services) {
        if (service['id']?.toString() == id) return service;
      }
    }

    final name = (row['name'] ?? row['service_name'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    if (name.isNotEmpty) {
      for (final service in services) {
        final localName =
            (service['name'] ?? '').toString().trim().toLowerCase();
        if (localName == name) return service;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _findServicesFromText(String text) {
    final lower = text.toLowerCase();
    final matches = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final service in services) {
      final name = (service['name'] ?? '').toString().trim();
      if (name.isEmpty) continue;

      if (lower.contains(name.toLowerCase())) {
        final id = service['id']?.toString() ?? name.toLowerCase();
        if (seen.add(id)) matches.add(service);
      }
    }

    return matches.take(5).toList();
  }

  bool _isColorIntent(String text) {
    final lower = text.toLowerCase();

    return lower.contains('color') ||
        lower.contains('colour') ||
        lower.contains('burgundy') ||
        lower.contains('blonde') ||
        lower.contains('auburn') ||
        lower.contains('copper') ||
        lower.contains('black') ||
        lower.contains('brown') ||
        lower.contains('purple') ||
        lower.contains('pink') ||
        lower.contains('blue') ||
        lower.contains('green') ||
        lower.contains('mahogany') ||
        RegExp(
          r'\b(?:1b|99j|613|350|425|530|t1b\/\w+)\b',
          caseSensitive: false,
        ).hasMatch(lower);
  }

  bool _asksToShowColors(String text) {
    final lower = text.toLowerCase();

    return lower.contains('show color') ||
        lower.contains('show me color') ||
        lower.contains('available color') ||
        lower.contains('what color') ||
        lower.trim() == 'colors' ||
        lower.trim() == 'colours';
  }

  List<HairColorResult> _findColorsFromText(String text) {
    final lower = text.toLowerCase();
    final output = <HairColorResult>[];
    final seen = <String>{};

    for (final row in hairColors) {
      final code = (row['code'] ?? '').toString().trim();
      final name = (row['name'] ?? '').toString().trim();

      if (code.isEmpty && name.isEmpty) continue;

      final codeMatch = code.isNotEmpty &&
          RegExp(
            r'(^|[^a-z0-9])' +
                RegExp.escape(code.toLowerCase()) +
                r'([^a-z0-9]|$)',
          ).hasMatch(lower);

      final nameMatch =
          name.isNotEmpty && lower.contains(name.toLowerCase());

      if (codeMatch || nameMatch) {
        final key = '$code|$name'.toLowerCase();

        if (seen.add(key)) {
          output.add(HairColorResult(code: code, name: name));
        }
      }
    }

    return output;
  }

  Map<String, dynamic>? _findLocalColor(String code, String name) {
    for (final row in hairColors) {
      final localCode = (row['code'] ?? '').toString().trim();
      final localName = (row['name'] ?? '').toString().trim();

      if (code.isNotEmpty &&
          localCode.toLowerCase() == code.toLowerCase()) {
        return row;
      }

      if (name.isNotEmpty &&
          localName.toLowerCase() == name.toLowerCase()) {
        return row;
      }
    }

    return null;
  }

  Map<String, dynamic>? getSuggestedService() {
    if (lastSuggestedServiceId != null) {
      for (final service in services) {
        if (service['id']?.toString() == lastSuggestedServiceId) {
          return service;
        }
      }
    }

    if (lastSuggestedServiceName != null) {
      for (final service in services) {
        if ((service['name'] ?? '').toString().toLowerCase() ==
            lastSuggestedServiceName!.toLowerCase()) {
          return service;
        }
      }
    }

    return null;
  }

  bool _isBookingIntent(String text) {
    final lower = text.toLowerCase();

    return lower.contains('book') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('reserve') ||
        lower.contains('availability') ||
        lower.contains('available time') ||
        lower.contains('open time');
  }


  void addSystemMessage(String text) {
    _messages.add(ChatMessage(text: text, isUser: false));
    notifyListeners();
    _speak(text);
  }

  String _removeRepeatedGreeting(String text) {
    var cleaned = text.trimLeft();

    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:good\s+(?:morning|afternoon|evening)|hello(?:\s+again)?|hi(?:\s+again)?)[!,.:\-\s]*',
        caseSensitive: false,
      ),
      '',
    );

    cleaned = cleaned.replaceFirst(
      RegExp(
        r"^(?:i['’]?m|i am)\s+(?:faith\s+ai|faithi)(?:,\s*your\s+salon\s+copilot)?[!,.:\-\s]*",
        caseSensitive: false,
      ),
      '',
    );

    if (cleaned.trim().isEmpty) return text.trim();
    return cleaned.trimLeft();
  }

  bool _isHttpUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _money(dynamic value) {
    if (value == null) return null;

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return value.toString();

    if (parsed == parsed.roundToDouble()) {
      return '\$${parsed.toStringAsFixed(0)}';
    }

    return '\$${parsed.toStringAsFixed(2)}';
  }
}

// ============================================================
// 13. API RESULT
// ============================================================

class FaithiApiResult {
  const FaithiApiResult({
    required this.reply,
    required this.rows,
    required this.meta,
  });

  final String reply;
  final List<Map<String, dynamic>> rows;
  final Map<String, dynamic> meta;
}

// ============================================================
// 14. MESSAGE DATA
// ============================================================

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.serviceImages = const [],
    this.colors = const [],
  });

  final String text;
  final bool isUser;
  final List<ServiceImageAttachment> serviceImages;
  final List<HairColorResult> colors;
}

// ============================================================
// 15. SERVICE IMAGE
// ============================================================

class ServiceImageAttachment {
  const ServiceImageAttachment({
    required this.serviceName,
    required this.url,
    this.serviceId,
    this.price,
  });

  final String? serviceId;
  final String serviceName;
  final String url;
  final String? price;
}

// ============================================================
// 16. HAIR COLOR
// ============================================================

class HairColorResult {
  const HairColorResult({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;
}

// ============================================================
// 17. CUSTOMER PREFERENCES
// ============================================================

class CustomerPreferences {
  String? budget;
  String? length;
  String? size;
  String? color;
  String? occasion;
  String? datePreference;

  void extractAndRemember(String text) {
    final lower = text.toLowerCase();

    final budgetMatch = RegExp(
      r'(?:\$\s*|budget(?:\s+is|\s+of|\s+around|\s+about|\s+under)?\s*\$?)(\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);

    if (budgetMatch != null) {
      budget = '\$${budgetMatch.group(1)}';
    }

    for (final value in [
      'shoulder',
      'midback',
      'mid back',
      'waist',
      'top butt',
      'mid butt',
      'under butt',
      'butt length',
    ]) {
      if (lower.contains(value)) length = value;
    }

    for (final value in [
      'jumbo',
      'large',
      'small medium',
      'semi-medium',
      'semi medium',
      'medium',
      'small',
    ]) {
      if (lower.contains(value)) size = value;
    }

    final colorMatch = RegExp(
      r'(?:color|colour)\s*(?:#|number|no\.?|code)?\s*([a-z0-9\/]+)',
      caseSensitive: false,
    ).firstMatch(text);

    if (colorMatch != null) {
      color = colorMatch.group(1);
    }

    for (final value in [
      'birthday',
      'wedding',
      'vacation',
      'work',
      'school',
      'party',
      'photoshoot',
      'photo shoot',
    ]) {
      if (lower.contains(value)) occasion = value;
    }

    final dateWords = [
      'today',
      'tomorrow',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
      'morning',
      'afternoon',
      'evening',
    ];

    final mentioned = dateWords.where(lower.contains).toList();

    if (mentioned.isNotEmpty) {
      datePreference = mentioned.join(', ');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (budget != null) 'budget': budget,
      if (length != null) 'length': length,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (occasion != null) 'occasion': occasion,
      if (datePreference != null) 'date_time_preference': datePreference,
    };
  }
}

// ============================================================
// 18. COLORS
// ============================================================

class AppColors {
  static const Color navy = Color(0xFF071A42);
  static const Color deepBlue = Color(0xFF0A2D6E);
  static const Color royalBlue = Color(0xFF0754AD);
  static const Color gold = Color(0xFFE4AD16);
  static const Color deepGold = Color(0xFF9A6800);
  static const Color pageBackground = Color(0xFFF6F8FC);
  static const Color borderGold = Color(0xFFD8B649);
  static const Color borderLight = Color(0xFFE6EAF2);
  static const Color muted = Color(0xFF667085);
}

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kInk,
          foregroundColor: Colors.white,
          title: const Text('Owner Dashboard'),
          bottom: const TabBar(
            indicatorColor: kPrimary,
            labelColor: kPrimary,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                icon: Icon(Icons.calendar_month_rounded),
                text: 'Bookings',
              ),
              Tab(
                icon: Icon(Icons.forum_rounded),
                text: 'Messages',
              ),
              Tab(
                icon: Icon(Icons.campaign_rounded),
                text: 'Marketing',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OwnerBookingsPage(),
            OwnerChatInboxPage(embedded: true),
            OwnerMarketingPage(),
          ],
        ),
      ),
    );
  }
}

class OwnerMarketingPage extends StatefulWidget {
  const OwnerMarketingPage({super.key});

  @override
  State<OwnerMarketingPage> createState() => _OwnerMarketingPageState();
}

class _OwnerMarketingPageState extends State<OwnerMarketingPage> {
  final supabase = Supabase.instance.client;
  final promotionController = TextEditingController();
  final bookingLinkController = TextEditingController(text: bookingUrl);

  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> history = [];
  String? selectedServiceId;
  String platform = 'Instagram & Facebook';
  String frequency = '3 times a week';
  TimeOfDay postTime = const TimeOfDay(hour: 10, minute: 0);
  bool approvalRequired = true;
  bool automationEnabled = false;
  bool loading = true;
  bool saving = false;
  String generatedPost = '';

  @override
  void initState() {
    super.initState();
    loadMarketingData();
  }

  @override
  void dispose() {
    promotionController.dispose();
    bookingLinkController.dispose();
    super.dispose();
  }

  Future<void> loadMarketingData() async {
    try {
      final results = await Future.wait([
        supabase.from('services').select().eq('is_active', true).order('name'),
        supabase
            .from('marketing_posts')
            .select()
            .order('created_at', ascending: false)
            .limit(20),
        supabase.from('marketing_settings').select().eq('id', 1).maybeSingle(),
      ]);

      final loadedServices = List<Map<String, dynamic>>.from(results[0] as List);
      final loadedHistory = List<Map<String, dynamic>>.from(results[1] as List);
      final settings = results[2] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        services = loadedServices;
        history = loadedHistory;
        selectedServiceId = services.isEmpty ? null : services.first['id'].toString();
        if (settings != null) {
          platform = settings['platform']?.toString() ?? platform;
          frequency = settings['frequency']?.toString() ?? frequency;
          approvalRequired = settings['approval_required'] as bool? ?? true;
          automationEnabled = settings['automation_enabled'] as bool? ?? false;
          final parts = (settings['post_time']?.toString() ?? '10:00').split(':');
          postTime = TimeOfDay(
            hour: int.tryParse(parts.first) ?? 10,
            minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          );
        }
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create the marketing tables in Supabase to save schedules and posts.'),
        ),
      );
    }
  }

  Map<String, dynamic>? get selectedService {
    for (final service in services) {
      if (service['id'].toString() == selectedServiceId) return service;
    }
    return services.isEmpty ? null : services.first;
  }

  String createPost() {
    final service = selectedService;
    final name = service?['name']?.toString() ?? 'beautiful protective styles';
    final price = service == null
        ? ''
        : ' starting at ${formatPrice(service['price']).replaceFirst('From ', '')}';
    final promotion = promotionController.text.trim();
    final extras = promotion.isEmpty ? '' : '\n\n✨ $promotion';
    final openings = [
      'Your next beautiful look is waiting ✨',
      'Fresh hair, fresh confidence ✨',
      'Ready for a neat protective style? 💛',
      'Let Faith Hair Style bring your vision to life ✨',
    ];
    final opening = openings[Random().nextInt(openings.length)];
    return '$opening\n\nBook $name$price with Faith Hair Style in Riverdale, Maryland.$extras\n\nChoose your appointment online, check your email for confirmation, and send a picture of the style you want through WhatsApp.\n\nBook now: ${bookingLinkController.text.trim()}\n\n#FaithHairStyle #RiverdaleMD #MarylandBraider #ProtectiveStyles #Braids';
  }

  void generatePreview() {
    setState(() => generatedPost = createPost());
  }

  Future<void> copyPost() async {
    if (generatedPost.isEmpty) generatePreview();
    final text = generatedPost.isEmpty ? createPost() : generatedPost;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marketing post copied.')),
    );
  }

  Future<void> saveDraft() async {
    final content = generatedPost.isEmpty ? createPost() : generatedPost;
    setState(() => saving = true);
    try {
      await supabase.from('marketing_posts').insert({
        'service_id': selectedService?['id']?.toString(),
        'platform': platform,
        'content': content,
        'status': approvalRequired ? 'pending' : 'approved',
        'scheduled_for': null,
      });
      if (!mounted) return;
      setState(() => generatedPost = content);
      await loadMarketingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marketing post saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save post: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveAutomation() async {
    setState(() => saving = true);
    try {
      await supabase.from('marketing_settings').upsert({
        'id': 1,
        'automation_enabled': automationEnabled,
        'approval_required': approvalRequired,
        'platform': platform,
        'frequency': frequency,
        'post_time': '${postTime.hour.toString().padLeft(2, '0')}:${postTime.minute.toString().padLeft(2, '0')}:00',
        'booking_link': bookingLinkController.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(automationEnabled
              ? 'Marketing automation settings saved.'
              : 'Marketing automation is paused.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save settings: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> chooseTime() async {
    final selected = await showTimePicker(context: context, initialTime: postTime);
    if (selected != null) setState(() => postTime = selected);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: loadMarketingData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          MaxWidth(
            width: 980,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Automated Marketing', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Create, approve, schedule, and track Faith Hair Style promotions.', style: TextStyle(color: kMuted)),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Marketing automation', style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(automationEnabled ? 'Automation is active' : 'Automation is paused'),
                          value: automationEnabled,
                          onChanged: (value) => setState(() => automationEnabled = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Require approval before posting'),
                          subtitle: const Text('Recommended while testing the system.'),
                          value: approvalRequired,
                          onChanged: (value) => setState(() => approvalRequired = value),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: platform,
                          decoration: const InputDecoration(labelText: 'Platform', prefixIcon: Icon(Icons.public_rounded)),
                          items: const ['Instagram & Facebook', 'Instagram', 'Facebook'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                          onChanged: (value) => setState(() => platform = value ?? platform),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: frequency,
                          decoration: const InputDecoration(labelText: 'Posting frequency', prefixIcon: Icon(Icons.repeat_rounded)),
                          items: const ['Every day', '3 times a week', 'Once a week'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                          onChanged: (value) => setState(() => frequency = value ?? frequency),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_rounded, color: kPrimary),
                          title: const Text('Posting time'),
                          subtitle: Text(postTime.format(context)),
                          trailing: OutlinedButton(onPressed: chooseTime, child: const Text('Change')),
                        ),
                        TextField(
                          controller: bookingLinkController,
                          decoration: const InputDecoration(labelText: 'Booking link', prefixIcon: Icon(Icons.link_rounded)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: saving ? null : saveAutomation,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save automation settings'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create a campaign', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedServiceId,
                          decoration: const InputDecoration(labelText: 'Service to promote', prefixIcon: Icon(Icons.auto_awesome_rounded)),
                          items: services.map((service) => DropdownMenuItem(value: service['id'].toString(), child: Text(service['name']?.toString() ?? 'Service'))).toList(),
                          onChanged: (value) => setState(() => selectedServiceId = value),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: promotionController,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Optional promotion', hintText: 'Example: \$20 off appointments booked this week', prefixIcon: Icon(Icons.local_offer_rounded)),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(onPressed: generatePreview, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('Generate post')),
                            OutlinedButton.icon(onPressed: copyPost, icon: const Icon(Icons.copy_rounded), label: const Text('Copy')),
                            OutlinedButton.icon(onPressed: saving ? null : saveDraft, icon: const Icon(Icons.save_alt_rounded), label: const Text('Save draft')),
                          ],
                        ),
                        if (generatedPost.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorder)),
                            child: SelectableText(generatedPost, style: const TextStyle(height: 1.5)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Recent marketing posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                if (history.isEmpty)
                  const EmptyState(icon: Icons.campaign_outlined, title: 'No marketing posts yet', message: 'Generate and save your first campaign above.')
                else
                  ...history.map((post) => Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: kSoftPink, child: Icon(Icons.campaign_rounded, color: kPrimaryDark)),
                          title: Text(post['platform']?.toString() ?? 'Marketing post'),
                          subtitle: Text(post['content']?.toString() ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                          trailing: Chip(label: Text(post['status']?.toString() ?? 'draft')),
                        ),
                      )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key});

  @override
  State<OwnerBookingsPage> createState() => _OwnerBookingsPageState();
}

class _OwnerBookingsPageState extends State<OwnerBookingsPage> {
  final supabase = Supabase.instance.client;

  Future<String> serviceName(dynamic serviceId) async {
    if (serviceId == null) return 'Unknown service';

    try {
      final result = await supabase
          .from('services')
          .select('name')
          .eq('id', serviceId)
          .limit(1);

      if (result.isEmpty) {
        return 'Service';
      }

      final service = Map<String, dynamic>.from(result.first);
      return (service['name'] ?? 'Service').toString();
    } catch (e) {
      debugPrint('Could not load service name: $e');
      return 'Service';
    }
  }

  Future<void> updateBookingStatus(
    dynamic bookingId,
    String status,
  ) async {
    if (bookingId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update booking: missing booking ID.'),
        ),
      );
      return;
    }

    try {
      debugPrint(
        'Updating booking ID: $bookingId to status: $status',
      );

      final result = await supabase
          .from('bookings')
          .update({
            'status': status,
          })
          .eq('id', bookingId)
          .select();

      if (result.isEmpty) {
        throw Exception(
          'No booking was updated. Check the booking ID and Supabase update policy.',
        );
      }

      final booking = Map<String, dynamic>.from(result.first);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking marked $status.')),
      );

      if (status != 'confirmed') {
        return;
      }

      var phone =
          (booking['phone'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');

      if (phone.length == 10) {
        phone = '1$phone';
      }

      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking confirmed, but the customer has no phone number.',
            ),
          ),
        );
        return;
      }

      final customer = (booking['customer_name'] ?? 'Customer').toString();
      final bookingDate = (booking['booking_date'] ?? '').toString();
      final startTime = (booking['start_time'] ?? '').toString();

      final message = Uri.encodeComponent(
        'Hello $customer, your appointment at Faith Hair Style '
        'for $bookingDate at $startTime has been confirmed. '
        'We look forward to seeing you!',
      );

      final whatsappUri = Uri.parse(
        'https://wa.me/$phone?text=$message',
      );

      final opened = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Booking confirmed, but WhatsApp could not be opened.',
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Booking update failed: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update booking: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('bookings')
          .stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingState(text: 'Loading bookings...');
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load bookings',
            message: snapshot.error.toString(),
          );
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.event_available_rounded,
            title: 'No bookings yet',
            message: 'New customer booking requests will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final booking = bookings[index];
            final id = booking['id'];
            final customer =
                (booking['customer_name'] ?? 'Customer').toString();
            final phone = (booking['phone'] ?? '').toString();
            final email = (booking['email'] ?? '').toString();
            final date = (booking['booking_date'] ?? '').toString();
            final start = (booking['start_time'] ?? '').toString();
            final end = (booking['end_time'] ?? '').toString();
            final notes = (booking['notes'] ?? '').toString();
            final status = (booking['status'] ?? 'pending').toString();
            final colorCode = (booking['hair_color_code'] ?? '').toString();

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: kSoftPink,
                          child: Icon(
                            Icons.person_rounded,
                            color: kPrimaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer,
                                style: const TextStyle(
                                  color: kInk,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              FutureBuilder<String>(
                                future: serviceName(booking['service_id']),
                                builder: (_, serviceSnapshot) {
                                  return Text(
                                    serviceSnapshot.data ??
                                        'Loading service...',
                                    style: const TextStyle(
                                      color: kPrimaryDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        _BookingStatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 18,
                      runSpacing: 10,
                      children: [
                        _OwnerDetail(
                          icon: Icons.calendar_today_rounded,
                          text: date.isEmpty ? 'No date' : date,
                        ),
                        _OwnerDetail(
                          icon: Icons.schedule_rounded,
                          text: start.isEmpty
                              ? 'No time'
                              : '$start${end.isEmpty ? '' : ' – $end'}',
                        ),
                        if (phone.isNotEmpty)
                          _OwnerDetail(
                            icon: Icons.phone_rounded,
                            text: phone,
                          ),
                        if (email.isNotEmpty)
                          _OwnerDetail(
                            icon: Icons.email_rounded,
                            text: email,
                          ),
                        if (colorCode.isNotEmpty)
                          _OwnerDetail(
                            icon: Icons.palette_rounded,
                            text: 'Hair color $colorCode',
                          ),
                      ],
                    ),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Notes: $notes',
                        style: const TextStyle(
                          color: kMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: status == 'confirmed'
                              ? null
                              : () => updateBookingStatus(id, 'confirmed'),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Confirm'),
                        ),
                        OutlinedButton.icon(
                          onPressed: status == 'cancelled'
                              ? null
                              : () => updateBookingStatus(id, 'cancelled'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancel'),
                        ),
                        if (phone.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => openUrl(
                              'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
                            ),
                            icon: const Icon(Icons.chat_rounded),
                            label: const Text('WhatsApp'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OwnerDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _OwnerDetail({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: kPrimaryDark),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: kMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  final String status;

  const _BookingStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'confirmed'
        ? Colors.green
        : normalized == 'cancelled'
            ? Colors.redAccent
            : kPrimaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        normalized.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class OwnerInboxGatePage extends StatefulWidget {
  const OwnerInboxGatePage({super.key});

  @override
  State<OwnerInboxGatePage> createState() => _OwnerInboxGatePageState();
}

class _OwnerInboxGatePageState extends State<OwnerInboxGatePage> {
  final pinController = TextEditingController();
  bool unlocked = false;
  String? error;

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  void unlock() {
    final pin = pinController.text.trim();
    if (pin == ownerChatPin) {
      setState(() {
        unlocked = true;
        error = null;
      });
    } else {
      setState(() => error = 'Wrong PIN. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (unlocked) return const OwnerChatInboxPage();

    return Scaffold(
      appBar: const BusinessAppBar(title: 'Owner Inbox'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 32),
        children: [
          MaxWidth(
            width: 620,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: 'Owner Inbox',
                    subtitle:
                        'Enter your owner PIN to open customer live chat conversations and reply inside the app.',
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: pinController,
                    autofocus: true,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Owner PIN',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                    onSubmitted: (_) => unlock(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: unlock,
                      icon: const Icon(Icons.admin_panel_settings_rounded),
                      label: const Text('Open Owner Inbox'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Owner access is private. Keep your PIN secure and do not display it publicly.',
                    style: TextStyle(color: kMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerChatInboxPage extends StatefulWidget {
  final bool embedded;

  const OwnerChatInboxPage({
    super.key,
    this.embedded = false,
  });

  @override
  State<OwnerChatInboxPage> createState() => _OwnerChatInboxPageState();
}

class _OwnerChatInboxPageState extends State<OwnerChatInboxPage> {
  final supabase = Supabase.instance.client;
  String? selectedSessionId;
  Map<String, dynamic>? selectedSession;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;

    final content = wide
        ? Row(
            children: [
              SizedBox(width: 360, child: buildSessionsList()),
              const VerticalDivider(width: 1),
              Expanded(child: buildSelectedChat()),
            ],
          )
        : selectedSessionId == null
            ? buildSessionsList()
            : buildSelectedChat(showBack: true);

    if (widget.embedded) return content;

    return Scaffold(
      appBar: const BusinessAppBar(title: 'Owner Chat Inbox'),
      body: content,
    );
  }

  Widget buildSessionsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('chat_sessions')
          .stream(primaryKey: ['id']).order('updated_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingState(text: 'Loading conversations...');
        }

        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Inbox error',
            message: snapshot.error.toString(),
          );
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No live chats yet',
            message: 'Customer conversations will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final session = sessions[i];
            final id = session['id'].toString();
            final name = (session['customer_name'] ?? 'Customer').toString();
            final phone = (session['customer_phone'] ?? '').toString();
            final status = (session['status'] ?? 'open').toString();
            final selected = selectedSessionId == id;

            return Material(
              color: selected ? kSoftPink : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    selectedSessionId = id;
                    selectedSession = session;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? kPrimary : kBorder),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: kPrimary,
                        child: Icon(Icons.person_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kInk,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              phone.isEmpty ? 'No phone provided' : phone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: TextStyle(
                          color: status == 'closed' ? kMuted : kPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSelectedChat({bool showBack = false}) {
    final id = selectedSessionId;
    if (id == null) {
      return const EmptyState(
        icon: Icons.forum_rounded,
        title: 'Select a conversation',
        message: 'Open a customer chat to reply in real time.',
      );
    }

    return OwnerChatThread(
      sessionId: id,
      session: selectedSession,
      showBack: showBack,
      onBack: () {
        setState(() {
          selectedSessionId = null;
          selectedSession = null;
        });
      },
    );
  }
}

class OwnerChatThread extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? session;
  final bool showBack;
  final VoidCallback onBack;

  const OwnerChatThread({
    super.key,
    required this.sessionId,
    required this.session,
    required this.showBack,
    required this.onBack,
  });

  @override
  State<OwnerChatThread> createState() => _OwnerChatThreadState();
}

class _OwnerChatThreadState extends State<OwnerChatThread> {
  final supabase = Supabase.instance.client;
  final replyController = TextEditingController();
  final scrollController = ScrollController();
  bool sending = false;

  @override
  void dispose() {
    replyController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> sendReply() async {
    final text = replyController.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);
    replyController.clear();

    try {
      await supabase.from('chat_messages').insert({
        'session_id': widget.sessionId,
        'role': 'owner',
        'content': text,
      });
      await supabase.from('chat_sessions').update({
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'open',
      }).eq('id', widget.sessionId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send reply: $e')),
      );
      replyController.text = text;
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> closeChat() async {
    try {
      await supabase.from('chat_sessions').update({
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat marked closed.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not close chat: $e')),
      );
    }
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.session?['customer_name'] ?? 'Customer').toString();
    final phone = (widget.session?['customer_phone'] ?? '').toString();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Row(
            children: [
              if (widget.showBack) ...[
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 6),
              ],
              const CircleAvatar(
                backgroundColor: kSoftPink,
                child: Icon(Icons.person_rounded, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                    ),
                    if (phone.isNotEmpty)
                      Text(phone, style: const TextStyle(color: kMuted)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: closeChat,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabase
                .from('chat_messages')
                .stream(primaryKey: ['id'])
                .eq('session_id', widget.sessionId)
                .order('created_at', ascending: true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingState(text: 'Loading messages...');
              }

              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load messages',
                  message: snapshot.error.toString(),
                );
              }

              final messages = snapshot.data ?? [];
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => scrollToBottom());

              return ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                itemCount: messages.length,
                itemBuilder: (_, i) => ChatBubble(message: messages[i]),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: replyController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendReply(),
                    decoration: const InputDecoration(
                      hintText: 'Reply to customer...',
                      prefixIcon: Icon(Icons.reply_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: sending ? null : sendReply,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final role = (message['role'] ?? '').toString().toLowerCase();
    final isCustomer = role == 'customer' || role == 'user';
    final content = (message['content'] ?? '').toString();
    final createdAt = (message['created_at'] ?? '').toString();
    final created = DateTime.tryParse(createdAt)?.toLocal();

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 620),
        decoration: BoxDecoration(
          color: isCustomer ? kPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isCustomer ? 20 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 20),
          ),
          border: isCustomer ? null : Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isCustomer ? Colors.white : kInk,
                height: 1.4,
              ),
            ),
            if (created != null) ...[
              const SizedBox(height: 6),
              Text(
                formatChatTime(created),
                style: TextStyle(
                  color: isCustomer ? Colors.white70 : kMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? initialService;

  const BookingPage({super.key, this.initialService});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final notesController = TextEditingController();

  late Future<List<Map<String, dynamic>>> servicesFuture;
  late Future<List<Map<String, dynamic>>> hairColorsFuture;
  Future<List<Map<String, dynamic>>>? slotsFuture;

  Map<String, dynamic>? selectedService;
  DateTime? selectedDate;
  String? selectedStartTime;
  String? selectedEndTime;
  String? selectedHairColorCode;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    selectedService = widget.initialService;
    servicesFuture = getServices();
    hairColorsFuture = getHairColors();
  }

  @override
  void didUpdateWidget(covariant BookingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialService != oldWidget.initialService) {
      setState(() => selectedService = widget.initialService);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    final result = await supabase
        .from('services')
        .select()
        .eq('is_active', true)
        .order('price', ascending: true);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getHairColors() async {
    final result = await supabase
        .from('hair_colors')
        .select()
        .eq('is_active', true)
        .order('code', ascending: true);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<List<Map<String, dynamic>>> getSlots(DateTime date) async {
    // Generate a full list of start times for the business day.
    // The end time is calculated from the selected service duration.
    // This means customers see many time choices instead of only a few fixed slots.
    final durationMinutes = selectedServiceDurationMinutes();
    final startOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      bookingStartHour,
    );
    final endOfDay = DateTime(
      date.year,
      date.month,
      date.day,
      bookingEndHour,
    );

    final slots = <Map<String, dynamic>>[];
    var start = startOfDay;

    while (start.isBefore(endOfDay)) {
      final end = start.add(Duration(minutes: durationMinutes));

      // Do not show a start time if the service would finish after closing time.
      if (end.isAfter(endOfDay)) break;

      slots.add({
        'start_time': timeToSql(start),
        'end_time': timeToSql(end),
      });

      start = start.add(const Duration(minutes: bookingIntervalMinutes));
    }

    return slots;
  }

  int selectedServiceDurationMinutes() {
    final raw = selectedService?['duration_minutes'];

    if (raw is int) return raw;
    if (raw is num) return raw.toInt();

    final parsed = int.tryParse((raw ?? '').toString());
    return parsed ?? 180;
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 120)),
      helpText: 'Select appointment date',
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      selectedStartTime = null;
      selectedEndTime = null;
      slotsFuture = getSlots(picked);
    });
  }

  Future<void> submitBooking() async {
    if (submitting) return;

    if (!formKey.currentState!.validate()) return;

    if (selectedService == null) {
      showMessage('Please choose a service.');
      return;
    }

    if (selectedDate == null) {
      showMessage('Please choose a date.');
      return;
    }

    if (selectedStartTime == null || selectedEndTime == null) {
      showMessage('Please choose an available time.');
      return;
    }

    setState(() => submitting = true);

    try {
      final notes = notesController.text.trim();
      final email = emailController.text.trim();

      await supabase.from('bookings').insert({
        'customer_name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': email.isEmpty ? null : email,
        'service_id': selectedService!['id'],
        'booking_date': dateToSql(selectedDate!),
        'start_time': selectedStartTime,
        'end_time': selectedEndTime,
        'status': 'pending',
        'notes': notes.isEmpty ? null : notes,
        'hair_color_code': selectedHairColorCode,
      });

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Booking request sent'),
          content: Text(
            'Thank you, ${nameController.text.trim()}! Your appointment request is pending confirmation. You can also message us on WhatsApp if you want to send a style picture.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                final serviceName = selectedService?['name'] ?? 'a hairstyle';
                openUrl(
                  'https://wa.me/$whatsappNumber?text=Hello%20Faith%20Hair%20Style,%20I%20booked%20$serviceName%20for%20${dateToSql(selectedDate!)}%20at%20$selectedStartTime.%20I%20want%20to%20send%20a%20picture.',
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open WhatsApp'),
            ),
          ],
        ),
      );

      setState(() {
        selectedStartTime = null;
        selectedEndTime = null;
        slotsFuture = selectedDate == null ? null : getSlots(selectedDate!);
      });
    } catch (e) {
      showMessage('Booking failed: $e');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'Book Appointment'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          MaxWidth(
            width: 980,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageHeader(
                      title: 'Ready for your new look?',
                      subtitle:
                          'Choose a service, pick a start time from the full business day, and send your booking request.',
                    ),
                    const SizedBox(height: 22),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: servicesFuture,
                      builder: (_, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const LinearProgressIndicator(color: kPrimary);
                        }

                        if (snap.hasError) {
                          return Text(
                            'Could not load services: ${snap.error}',
                            style: const TextStyle(color: Colors.red),
                          );
                        }

                        final services = snap.data ?? [];

                        return DropdownButtonFormField<String>(
                          value: selectedService == null
                              ? null
                              : selectedService!['id'].toString(),
                          decoration: const InputDecoration(
                            labelText: 'Service',
                            prefixIcon: Icon(Icons.content_cut_rounded),
                          ),
                          items: services.map((service) {
                            return DropdownMenuItem<String>(
                              value: service['id'].toString(),
                              child: Text(
                                '${service['name']} • ${formatPrice(service['price'])} • ${formatDuration(service['duration_minutes'])}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            final found = services.firstWhere(
                              (service) => service['id'].toString() == id,
                            );
                            setState(() {
                              selectedService = found;
                              selectedStartTime = null;
                              selectedEndTime = null;
                              if (selectedDate != null) {
                                slotsFuture = getSlots(selectedDate!);
                              }
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a service' : null,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: hairColorsFuture,
                      builder: (_, snap) {
                        final colors = snap.data ?? [];
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }

                        if (colors.isEmpty) {
                          return const Text(
                            'Hair color is optional. Add active colors in the hair_colors table to show a color dropdown.',
                            style: TextStyle(color: kMuted),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedHairColorCode,
                          decoration: const InputDecoration(
                            labelText: 'Hair color code optional',
                            prefixIcon: Icon(Icons.palette_rounded),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('No color selected'),
                            ),
                            ...colors.map((color) {
                              final code = color['code'].toString();
                              final name = color['name'].toString();
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Text('$code • $name'),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => selectedHairColorCode = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email optional',
                        prefixIcon: Icon(Icons.email_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: Text(
                        selectedDate == null
                            ? 'Choose appointment date'
                            : 'Date: ${dateToSql(selectedDate!)}',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimaryDark,
                        side: const BorderSide(color: kPrimary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (slotsFuture != null)
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: slotsFuture,
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const LoadingState(
                                text: 'Loading day times...');
                          }

                          if (snap.hasError) {
                            return Text(
                              'Could not load day times: ${snap.error}',
                              style: const TextStyle(color: Colors.red),
                            );
                          }

                          final slots = snap.data ?? [];
                          if (slots.isEmpty) {
                            return const EmptyState(
                              icon: Icons.event_busy_rounded,
                              title: 'No times available',
                              message:
                                  'This service duration does not fit inside the business day. Choose a shorter service or message us on WhatsApp.',
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose start time • ${formatDuration(selectedServiceDurationMinutes())} service',
                                style: const TextStyle(
                                  color: kMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: slots.map((slot) {
                                  final start = slot['start_time'].toString();
                                  final end = slot['end_time'].toString();
                                  final selected = selectedStartTime == start;

                                  return ChoiceChip(
                                    label: Text(formatTime(start)),
                                    selected: selected,
                                    selectedColor: kSoftPink,
                                    checkmarkColor: kPrimary,
                                    side: const BorderSide(color: kBorder),
                                    onSelected: (_) {
                                      setState(() {
                                        selectedStartTime = start;
                                        selectedEndTime = end;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              if (selectedStartTime != null &&
                                  selectedEndTime != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Selected: ${formatTime(selectedStartTime!)} - ${formatTime(selectedEndTime!)}',
                                  style: const TextStyle(
                                    color: kPrimaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Notes optional',
                        hintText:
                            'Example: medium size, waist length, color 1B, I will send a picture.',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: submitting ? null : submitBooking,
                          icon: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                              submitting ? 'Sending...' : 'Submit Booking'),
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              openUrl('https://wa.me/$whatsappNumber'),
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('Message on WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kPrimaryDark,
                            side: const BorderSide(color: kPrimary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => openUrl(bookingUrl),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Google Booking Form'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const MaxWidth(
            width: 980,
            child: ResponsiveInfoCards(
              cards: [
                InfoData(
                  icon: Icons.content_cut_rounded,
                  title: 'Services',
                  text:
                      'Knotless braids, cornrows, Fulani braids, twists, loc styles, natural styles, and kids braiding.',
                ),
                InfoData(
                  icon: Icons.favorite_rounded,
                  title: 'Customer Promise',
                  text:
                      'Clean parts, gentle hands, polished finish, and a friendly customer experience.',
                ),
                InfoData(
                  icon: Icons.place_rounded,
                  title: 'Location',
                  text: 'Riverdale, Maryland.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'Social Media'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
        children: [
          const MaxWidth(
            child: PageHeader(
              title: 'Follow Our Latest Styles',
              subtitle:
                  'Tap below to see our newest braid photos and videos on Instagram and TikTok.',
            ),
          ),
          const SizedBox(height: 18),
          MaxWidth(
            child: ResponsiveInfoCards(
              cards: [
                InfoData(
                  icon: Icons.camera_alt_rounded,
                  title: 'Instagram',
                  text: 'Photos, reels, and new hairstyle inspiration.',
                  buttonLabel: 'Open Instagram',
                  onTap: () => openUrl(instagramUrl),
                ),
                InfoData(
                  icon: Icons.music_note_rounded,
                  title: 'TikTok',
                  text: 'Short videos, fresh looks, and style ideas.',
                  buttonLabel: 'Open TikTok',
                  onTap: () => openUrl(tiktokUrl),
                ),
                InfoData(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp',
                  text: 'Send your inspiration photo and booking request.',
                  buttonLabel: 'Message Now',
                  onTap: () => openUrl('https://wa.me/$whatsappNumber'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: kInk,
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: kMuted, fontSize: 16, height: 1.45),
        ),
      ],
    );
  }
}

class ResponsiveInfoCards extends StatelessWidget {
  final List<InfoData> cards;

  const ResponsiveInfoCards({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth >= 760;

      if (!wide) {
        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(data: card),
                  ))
              .toList(),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: InfoCard(data: cards[i])),
            if (i != cards.length - 1) const SizedBox(width: 14),
          ],
        ],
      );
    });
  }
}

class InfoData {
  final IconData icon;
  final String title;
  final String text;
  final String? buttonLabel;
  final VoidCallback? onTap;

  const InfoData({
    required this.icon,
    required this.title,
    required this.text,
    this.buttonLabel,
    this.onTap,
  });
}

class InfoCard extends StatelessWidget {
  final InfoData data;

  const InfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: kSoftPink,
              child: Icon(data.icon, color: kPrimary),
            ),
            const SizedBox(height: 14),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: kInk,
              ),
            ),
            const SizedBox(height: 7),
            Text(data.text, style: const TextStyle(color: kMuted, height: 1.4)),
            if (data.buttonLabel != null && data.onTap != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: data.onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(data.buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  final String text;

  const LoadingState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kPrimary),
            const SizedBox(height: 14),
            Text(text, style: const TextStyle(color: kMuted)),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kSoftPink,
                child: Icon(icon, color: kPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function() onRetry;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EmptyState(
          icon: Icons.error_outline_rounded,
          title: title,
          message: message,
        ),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
          style: FilledButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class MaxWidth extends StatelessWidget {
  final Widget child;
  final double width;

  const MaxWidth({
    super.key,
    required this.child,
    this.width = 1240,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: child,
      ),
    );
  }
}

String timeToSql(DateTime value) {
  final h = value.hour.toString().padLeft(2, '0');
  final m = value.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

String dateToSql(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String formatTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;

  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

String formatChatTime(DateTime value) {
  final hour = value.hour;
  final minute = value.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

String formatDuration(dynamic value) {
  if (value == null) return 'Duration varies';

  final text = value.toString().trim();
  if (text.isEmpty) return 'Duration varies';

  final minutes = int.tryParse(text);
  if (minutes == null) {
    final lower = text.toLowerCase();
    if (lower.contains('min') ||
        lower.contains('hr') ||
        lower.contains('hour')) {
      return text;
    }
    return '$text min';
  }

  if (minutes < 60) return '$minutes min';

  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) return '$hours hr';
  return '$hours hr $remaining min';
}

String formatPrice(dynamic value) {
  if (value == null) return 'Price varies';

  if (value is num) {
    final amount =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return 'From \$$amount';
  }

  final text = value.toString().trim();
  if (text.isEmpty) return 'Price varies';
  if (text.startsWith(r'$')) return 'From $text';

  final numeric = num.tryParse(text);
  if (numeric != null) {
    final amount = numeric % 1 == 0
        ? numeric.toInt().toString()
        : numeric.toStringAsFixed(2);
    return 'From \$$amount';
  }

  return text;
}
