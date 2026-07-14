import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_page.dart';
import 'ai_chat_page.dart';
import 'admin_login_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  bool loading = true;
  String? error;
  List<Map<String, dynamic>> services = [];
  String selectedCategory = 'All';

  Color get primaryPink => const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    loadServices();
  }

  Future<void> loadServices() async {
    try {
      final response = await supabase
          .from('services')
          .select()
          .eq('is_active', true)
          .order('price');

      setState(() {
        services = List<Map<String, dynamic>>.from(response);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load services: $e';
        loading = false;
      });
    }
  }

  List<String> get categories {
    final cats = services
        .map((s) => s['category']?.toString() ?? 'Other')
        .toSet()
        .toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<Map<String, dynamic>> get filteredServices {
    final search = searchController.text.toLowerCase();

    return services.where((s) {
      final name = s['name']?.toString().toLowerCase() ?? '';
      final category = s['category']?.toString() ?? '';

      final matchesSearch = name.contains(search);
      final matchesCategory =
          selectedCategory == 'All' || category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Map<String, dynamic>> get recommendedServices {
    final list = [...services];

    list.sort((a, b) {
      final aPrice = double.tryParse(a['price'].toString()) ?? 0;
      final bPrice = double.tryParse(b['price'].toString()) ?? 0;
      return aPrice.compareTo(bPrice);
    });

    return list.take(4).toList();
  }

  void openBooking(Map<String, dynamic> service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(service: service),
      ),
    );
  }

  void openFaithCo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AIChatPage()),
    );
  }

  int getGridCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 650) return 3;
    if (width >= 430) return 2;
    return 1;
  }

  Widget buildFaithCoRecommendations() {
    if (recommendedServices.isEmpty) return const SizedBox();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: primaryPink),
              const SizedBox(width: 8),
              const Text(
                'FaithCo Recommendations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: openFaithCo,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Ask FaithCo'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Suggested styles based on price, category, and booking value.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 155,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedServices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final service = recommendedServices[index];
                final name = service['name']?.toString() ?? 'Service';
                final price = service['price']?.toString() ?? '0';
                final category = service['category']?.toString() ?? 'Salon';
                final duration =
                    service['duration_minutes']?.toString() ?? '60';

                String tag = 'Best Value';
                if (category.toLowerCase().contains('braid')) {
                  tag = 'Popular Braids';
                } else if (category.toLowerCase().contains('kids')) {
                  tag = 'Kids Pick';
                } else if (duration == '45' || duration == '60') {
                  tag = 'Quick Style';
                }

                return InkWell(
                  onTap: () => openBooking(service),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: primaryPink),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: primaryPink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$category • $duration min'),
                        const Spacer(),
                        Text(
                          'From \$$price',
                          style: TextStyle(
                            color: primaryPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('FaithCo Help'),
        onPressed: openFaithCo,
      ),
      appBar: AppBar(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        title: const Text('Faith Hair Style'),
        actions: [
          IconButton(
            tooltip: 'Admin',
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              );
            },
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: primaryPink))
          : error != null
              ? Center(child: Text(error!))
              : Column(
                  children: [
                    Container(
                      color: primaryPink,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hair Products & Salon Services',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'FaithCo AI Assistant is here to help you choose a style.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search braids, twists, wigs...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      height: 56,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final selected = category == selectedCategory;

                          return ChoiceChip(
                            label: Text(category),
                            selected: selected,
                            selectedColor: Colors.pink.shade100,
                            checkmarkColor: primaryPink,
                            onSelected: (_) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    buildFaithCoRecommendations(),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.sort),
                            label: const Text('Sort by'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.verified),
                            label: const Text('Verified'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.local_offer),
                            label: const Text('Price'),
                          ),
                          const Spacer(),
                          Text(
                            '${filteredServices.length} services',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredServices.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  getGridCount(constraints.maxWidth),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.66,
                            ),
                            itemBuilder: (context, index) {
                              final service = filteredServices[index];

                              return AlibabaServiceCard(
                                service: service,
                                primaryPink: primaryPink,
                                onTap: () => openBooking(service),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class AlibabaServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final Color primaryPink;
  final VoidCallback onTap;

  const AlibabaServiceCard({
    super.key,
    required this.service,
    required this.primaryPink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = service['name']?.toString() ?? 'Service';
    final price = service['price']?.toString() ?? '0';
    final category = service['category']?.toString() ?? 'Salon';
    final duration = service['duration_minutes']?.toString() ?? '60';
    final imageUrl = service['image_url']?.toString();

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.pink.shade50,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.content_cut,
                          size: 70,
                          color: primaryPink,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$$price',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$duration min • $category',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Service',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Book Now'),
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
