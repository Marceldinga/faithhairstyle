import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const supabaseUrl = 'https://lowqtmndtkgwmnyhqszp.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxvd3F0bW5kdGtnd21ueWhxc3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwODgzMjQsImV4cCI6MjA4ODY2NDMyNH0.DAD_IfgcnXSnMfhu0MCl-CBVIVIEUSe9Yh7JbdvOhtw';

const whatsappNumber = '13015419875';
const instagramUrl = 'https://www.instagram.com/faith_styl_/';
const tiktokUrl = 'https://www.tiktok.com/@nfor.ako';
const bookingUrl =
    'https://docs.google.com/forms/d/1vvAIeCi7BZ-kJJff-SzTskWn2u1kD3KBlDpwXl42SpY/viewform';

// Faith Hair Style luxury business palette.
const kPrimary = Color(0xFFD4A437); // Gold
const kPrimaryDark = Color(0xFF8C6518); // Dark gold
const kInk = Color(0xFF17130F); // Luxury black
const kMuted = Color(0xFF756A5E); // Warm muted text
const kSurface = Color(0xFFFFF8EE); // Cream background
const kSoftPink = Color(0xFFF4E7C8); // Soft gold/cream highlight
const kBorder = Color(0xFFE4D3B5); // Warm border
const kCard = Color(0xFFFFFFFF);
const kDarkSurface = Color(0xFF241C13);
const kAccentPink = Color(0xFFD94B78);

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
          onPrimary: kInk,
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
          backgroundColor: kCard,
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
          indicatorColor: kDarkSurface,
          selectedIconTheme: IconThemeData(color: kPrimary, size: 27),
          unselectedIconTheme: IconThemeData(color: Colors.white70, size: 24),
          selectedLabelTextStyle: TextStyle(
            color: kPrimary,
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
            foregroundColor: kInk,
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
          foregroundColor: kInk,
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
        return const AiPage();
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

    return Scaffold(
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 18,
      title: Row(
        children: [
          Tooltip(
            message: 'Faith Hair Style',
            child: GestureDetector(
              onLongPress: () => openPrivateOwnerDashboard(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Instagram',
          icon: const Icon(Icons.camera_alt_rounded),
          onPressed: () => openUrl(instagramUrl),
        ),
        IconButton(
          tooltip: 'TikTok',
          icon: const Icon(Icons.music_note_rounded),
          onPressed: () => openUrl(tiktokUrl),
        ),
        ...extraActions,
        const SizedBox(width: 8),
      ],
    );
  }
}

class HeroSection extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBookTap;

  const HeroSection({
    super.key,
    required this.onSearchChanged,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final wideScreen = MediaQuery.sizeOf(context).width >= 850;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kInk, kDarkSurface, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: MaxWidth(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 34, 18, 34),
          child: wideScreen
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _HeroCopy(
                        onSearchChanged: onSearchChanged,
                        onBookTap: onBookTap,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const HeroInfoCard(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCopy(
                      onSearchChanged: onSearchChanged,
                      onBookTap: onBookTap,
                    ),
                    const SizedBox(height: 18),
                    const HeroInfoCard(),
                  ],
                ),
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Beautiful Braids, Twists & Natural Styles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Riverdale, Maryland • Gentle hands • Clean parts • Polished finish',
          style: TextStyle(color: Colors.white70, fontSize: 16.5, height: 1.5),
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search knotless, cornrows, kids, twists...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(22)),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onBookTap,
              icon: const Icon(Icons.calendar_month_rounded),
              label: const Text('Book Appointment'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: kInk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => openUrl('https://wa.me/$whatsappNumber'),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
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
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white24),
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
            mainAxisExtent: 418,
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
          SizedBox(
            height: 178,
            width: double.infinity,
            child: image.isNotEmpty
                ? Image.network(
                    image,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
          SizedBox(
            height: 196,
            width: double.infinity,
            child: Image.network(
              image,
              fit: BoxFit.cover,
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

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final input = TextEditingController();
  final scrollController = ScrollController();
  List<Map<String, dynamic>> services = [];

  final messages = <Map<String, String>>[
    {
      'bot':
          'Hi! Welcome to Faith Hair Style. I can help you choose a style, check starting prices, and book your appointment.'
    }
  ];

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final result = await Supabase.instance.client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('price', ascending: true);
      if (!mounted) return;
      setState(() => services = List<Map<String, dynamic>>.from(result));
    } catch (_) {
      // Keep the assistant available even if services cannot load.
    }
  }

  @override
  void dispose() {
    input.dispose();
    scrollController.dispose();
    super.dispose();
  }

  String reply(String text) {
    final q = text.toLowerCase().trim();

    if (q.contains('hello') || q.contains('hi') || q.contains('hey')) {
      return 'Hello! Welcome to Faith Hair Style. What style are you interested in today? I can help with prices, duration, hair color, and booking.';
    }

    for (final service in services) {
      final name = (service['name'] ?? '').toString();
      if (name.isNotEmpty && q.contains(name.toLowerCase())) {
        return '$name starts at ${formatPrice(service['price'])} and usually takes ${formatDuration(service['duration_minutes'])}. You can book it from the Book tab or send a picture on WhatsApp for confirmation.';
      }
    }

    if (q.contains('price') || q.contains('cost') || q.contains('how much')) {
      if (services.isEmpty) {
        return 'Prices depend on size, length, and style. Send the hairstyle name or picture for a better quote.';
      }

      final sample = services.take(4).map((s) {
        return '${s['name']}: ${formatPrice(s['price'])}';
      }).join('\n');

      return 'Here are some starting prices:\n$sample\n\nPrices can change based on size, length, color, and hair added. Send a picture for the best quote.';
    }

    if (q.contains('book') ||
        q.contains('appointment') ||
        q.contains('schedule')) {
      return 'To book, choose a service in the Book tab, select an available date/time, then enter your name and phone number. You can also message us on WhatsApp with the style, size, length, preferred date, and a picture.';
    }

    if (q.contains('kids') || q.contains('child') || q.contains('children')) {
      return 'Yes, kids styles are available. We focus on gentle tension, neat parts, and comfortable protective styles for children.';
    }

    if (q.contains('knotless')) {
      return 'Knotless braids are a great protective style. Price and time depend on size and length. Small or long knotless braids usually take longer and cost more.';
    }

    if (q.contains('cornrow') || q.contains('cornrows')) {
      return 'Cornrows are a neat protective style and can be simple or designed. Send a picture if you want a specific pattern.';
    }

    if (q.contains('twist') || q.contains('twists')) {
      return 'Twists are a beautiful natural protective style. Tell me the length and size you want, and whether you want hair added or natural hair only.';
    }

    if (q.contains('loc') || q.contains('locs')) {
      return 'Loc styles may be available depending on the look you want. Please send a picture so we can confirm timing and price.';
    }

    if (q.contains('natural')) {
      return 'Natural styles are perfect for protective styling. Tell me your hair length and the look you want, and I can recommend a style.';
    }

    if (q.contains('color')) {
      return 'Hair color can be selected during booking if available. You can also message us with the color code or picture of the color you want.';
    }

    if (q.contains('hair')) {
      return 'Hair may be provided for some styles. You can also bring your own hair if you prefer a specific color, brand, or length.';
    }

    if (q.contains('location') ||
        q.contains('where') ||
        q.contains('address')) {
      return 'Faith Hair Style is located in Riverdale, Maryland. Appointment details can be shared after booking.';
    }

    if (q.contains('time') || q.contains('long') || q.contains('duration')) {
      return 'The time depends on the style, size, and length. You can see service durations in the app, and the booking page will show available time slots.';
    }

    if (q.contains('cancel') || q.contains('reschedule')) {
      return 'To cancel or reschedule, please message us on WhatsApp as soon as possible with your name and appointment date.';
    }

    return 'I can help with that. Please tell me the hairstyle you want, your hair length, your budget, and when you want to book. A picture is best for an accurate recommendation.';
  }

  void send() {
    final text = input.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({'user': text});
      messages.add({'bot': reply(text)});
      input.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void askQuickQuestion(String question) {
    input.text = question;
    send();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'AI Assistant'),
      body: Column(
        children: [
          MaxWidth(
            width: 860,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kSoftPink,
                          child: Icon(Icons.smart_toy_rounded, color: kPrimary),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ask about styles, starting prices, hair color, duration, and how to book.',
                            style: TextStyle(color: kMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.attach_money_rounded),
                        label: const Text('How much are braids?'),
                        onPressed: () =>
                            askQuickQuestion('How much are braids?'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_month_rounded),
                        label: const Text('How do I book?'),
                        onPressed: () => askQuickQuestion('How do I book?'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.child_care_rounded),
                        label: const Text('Do you do kids styles?'),
                        onPressed: () =>
                            askQuickQuestion('Do you do kids styles?'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: MaxWidth(
              width: 860,
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final item = messages[i];
                  final isBot = item.containsKey('bot');

                  return Align(
                    alignment:
                        isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: const BoxConstraints(maxWidth: 620),
                      decoration: BoxDecoration(
                        color: isBot ? Colors.white : kPrimary,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isBot ? 4 : 20),
                          bottomRight: Radius.circular(isBot ? 20 : 4),
                        ),
                        border: isBot ? Border.all(color: kBorder) : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        isBot ? item['bot']! : item['user']!,
                        style: TextStyle(
                          color: isBot ? kInk : Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: MaxWidth(
              width: 860,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about styles, prices, booking...',
                          prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: send,
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final messageController = TextEditingController();
  final scrollController = ScrollController();
  final formKey = GlobalKey<FormState>();

  String? sessionId;
  bool starting = false;
  bool sending = false;
  String? errorMessage;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> startChat() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      starting = true;
      errorMessage = null;
    });

    try {
      final name = nameController.text.trim();
      final phone = phoneController.text.trim();
      final response = await supabase
          .from('chat_sessions')
          .insert({
            'user_id': 'guest-${DateTime.now().millisecondsSinceEpoch}',
            'customer_name': name,
            'customer_phone': phone,
            'status': 'open',
            'step': 'live_chat',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final id = response['id'].toString();

      await supabase.from('chat_messages').insert({
        'session_id': id,
        'role': 'owner',
        'content':
            'Welcome to Faith Hair Style live chat. Please send your question, style name, or inspiration photo details. We will reply here as soon as possible.',
      });

      if (!mounted) return;
      setState(() => sessionId = id);
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  Future<void> sendMessage() async {
    final id = sessionId;
    final text = messageController.text.trim();
    if (id == null || text.isEmpty || sending) return;

    setState(() => sending = true);
    messageController.clear();

    try {
      await supabase.from('chat_messages').insert({
        'session_id': id,
        'role': 'customer',
        'content': text,
      });

      await supabase.from('chat_sessions').update({
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'open',
      }).eq('id', id);

      WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send message: $e')),
      );
      messageController.text = text;
    } finally {
      if (mounted) setState(() => sending = false);
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

  Future<void> openOwnerInbox() async {
    final controller = TextEditingController();
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Owner Inbox'),
          content: TextField(
            controller: controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter owner PIN',
              prefixIcon: Icon(Icons.lock_rounded),
            ),
            onSubmitted: (_) {
              Navigator.pop(context, controller.text.trim() == ownerChatPin);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                  context, controller.text.trim() == ownerChatPin),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted) return;

    if (allowed == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OwnerChatInboxPage()),
      );
    } else if (allowed == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wrong PIN. Inbox not opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BusinessAppBar(title: 'Live Chat'),
      body: sessionId == null ? buildStartChat() : buildChat(),
    );
  }

  Widget buildStartChat() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 32),
      children: [
        MaxWidth(
          width: 760,
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
                    title: 'Chat with us live',
                    subtitle:
                        'Start an in-app chat for questions about styles, prices, dates, and booking help.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      prefixIcon: Icon(Icons.phone_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: starting ? null : startChat,
                      icon: starting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.support_agent_rounded),
                      label: Text(
                          starting ? 'Starting chat...' : 'Start Live Chat'),
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => openUrl('https://wa.me/$whatsappNumber'),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Or message on WhatsApp'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildChat() {
    final id = sessionId!;

    return Column(
      children: [
        MaxWidth(
          width: 860,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kSoftPink,
                    child: Icon(Icons.support_agent_rounded, color: kPrimary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Live chat is open. Send your question and the owner can reply from the Owner Inbox.',
                      style: TextStyle(color: kMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: MaxWidth(
            width: 860,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('chat_messages')
                  .stream(primaryKey: ['id'])
                  .eq('session_id', id)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const LoadingState(text: 'Opening live chat...');
                }

                if (snapshot.hasError) {
                  return EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load chat',
                    message: snapshot.error.toString(),
                  );
                }

                final messages = snapshot.data ?? [];

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => scrollToBottom());

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => ChatBubble(message: messages[i]),
                );
              },
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: MaxWidth(
            width: 860,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        prefixIcon: Icon(Icons.message_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: sending ? null : sendMessage,
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
        ),
      ],
    );
  }
}

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OwnerBookingsPage(),
            OwnerChatInboxPage(embedded: true),
          ],
        ),
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
          .maybeSingle();

      return (result?['name'] ?? 'Service').toString();
    } catch (_) {
      return 'Service';
    }
  }

  Future<void> updateBookingStatus(
    dynamic bookingId,
    String status,
  ) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': status}).eq('id', bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking marked $status.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update booking: $e')),
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
                    'Testing PIN: 1234. Change ownerChatPin in main.dart before sharing publicly.',
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
