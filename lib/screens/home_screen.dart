import 'package:flutter/material.dart';

import 'package:o3d/o3d.dart';
import 'package:project_3d/provider/gender_provider.dart';
import 'package:project_3d/screens/settings_screen.dart';
import 'package:project_3d/services/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:project_3d/utils/weather_icons.dart';

import '../inverted_circle_clipper.dart';
import 'package:project_3d/database/database_helper.dart';
import 'package:project_3d/models/card_item.dart';

// Existing app home (keeps your original HomeScreen UI)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  O3DController o3dController = O3DController();
  PageController mainPageController = PageController();
  PageController textsPageController = PageController();
  int page = 0;

  Map<String, dynamic>? _weather;
  bool _loadingWeather = true;

  // DB related
  late Future<List<Map<String, dynamic>>> _futureCards;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadCards();
    _ensureSampleData();
  }

  void _loadCards() {
    _futureCards = DBHelper.instance.getCardsWithMeta();
  }

  Future<void> _ensureSampleData() async {
    final rows = await DBHelper.instance.getCardsWithMeta();
    if (rows.isEmpty) {
      await _insertSampleData();
    } else {
      setState(() {
        _loadCards();
      });
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final svc = WeatherService();
      final data = await svc.getWeather();
      setState(() {
        _weather = data;
        _loadingWeather = false;
      });
    } catch (_) {
      setState(() {
        _weather = null;
        _loadingWeather = false;
      });
    }
  }

  Future<void> _insertSampleData() async {
    await DBHelper.instance
        .insertAuthor({'name': 'Dr Babak', 'avatar': 'assets/avatar1.png'});
    final authorId = await DBHelper.instance.getAuthorIdByName('Dr Babak') ?? 1;

    int catRunId = await DBHelper.instance.getCategoryIdByName('Charity Run') ??
        await DBHelper.instance.insertCategory({'name': 'Charity Run'});

    int catYogaId =
        await DBHelper.instance.getCategoryIdByName('Charity Yoga') ??
            await DBHelper.instance.insertCategory({'name': 'Charity Yoga'});

    int catWalkId =
        await DBHelper.instance.getCategoryIdByName('Charity Walk') ??
            await DBHelper.instance.insertCategory({'name': 'Charity Walk'});

    final now = DateTime.now().millisecondsSinceEpoch;

    final events = [
      {
        'title': 'Charity Run 5K for Education',
        'subtitle': 'Run and raise funds for local schools',
        'body':
            'A fun community run for all ages. All fees will be donated to children’s education.',
        'imageUrl': 'assets/charity-run.jpg',
        'event_date':
            DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch,
        'target_donation': 5000000,
        'collected_donation': 2000000,
        'created_at': now,
        'author_id': authorId,
        'category_id': catRunId,
      },
      {
        'title': 'Charity Yoga for Wellness',
        'subtitle': 'Breathe. Stretch. Give.',
        'body':
            'Morning yoga session to promote mental health awareness. All proceeds go to mental health charity.',
        'imageUrl': 'assets/yoga_event.jfif',
        'event_date':
            DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
        'target_donation': 3000000,
        'collected_donation': 1500000,
        'created_at': now,
        'author_id': authorId,
        'category_id': catYogaId,
      },
      {
        'title': 'Walk for Clean Water',
        'subtitle': 'Every step brings water to villages',
        'body': 'Join our 3km charity walk to support clean water projects.',
        'imageUrl': 'assets/fun_walk.jfif',
        'event_date':
            DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch,
        'target_donation': 7000000,
        'collected_donation': 2500000,
        'created_at': now,
        'author_id': authorId,
        'category_id': catWalkId,
      },
    ];

    for (var e in events) {
      await DBHelper.instance.insertCard(e);
    }

    setState(() {
      _loadCards();
    });
  }

  void _confirmDelete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus event?'),
        content: Text('Hapus "${row['title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.instance.deleteCard(row['id'] as int);
      setState(() {
        _loadCards();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    // header total height (tweak if needed)
    final double headerHeight = 420;
    // left column width for stats (prevent the number from expanding too big)
    final double leftColumnWidth = 140;

    final genderProvider = Provider.of<GenderProvider>(context);

    final String modelPath = genderProvider.gender == "male"
        ? 'assets/male_basic_walk_30_frames_loop.glb'
        : 'assets/disney_style_character.glb';

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: PageView(
          controller: mainPageController,
          children: [
            // PAGE 1
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureCards,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final rows = snapshot.data ?? [];

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.blue.shade50,
                        child: Column(
                          children: [
                            // header top row: stats left + settings icon
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left fixed-width column for stats (so number doesn't expand)
                                  SizedBox(
                                    width: leftColumnWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Daily goals',
                                            style: TextStyle(fontSize: 16)),
                                        const SizedBox(height: 8),
                                        // big number - fixed font size (not FittedBox)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: const [
                                            Text('87',
                                                style: TextStyle(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87)),
                                            SizedBox(width: 6),
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(bottom: 8.0),
                                              child: Text('%',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // small stats
                                        const Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Icon(
                                                  Icons
                                                      .local_fire_department_outlined,
                                                  color: Colors.red,
                                                  size: 18),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("1,840",
                                                      style: TextStyle(
                                                          fontSize: 13)),
                                                  Text("calories",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Icon(Icons.do_not_step,
                                                  color: Colors.purple,
                                                  size: 18),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("3,480",
                                                      style: TextStyle(
                                                          fontSize: 13)),
                                                  Text("steps",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        const Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8.0),
                                              child: Icon(
                                                  Icons.hourglass_bottom,
                                                  color: Colors.lightBlueAccent,
                                                  size: 18),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text("6.5",
                                                      style: TextStyle(
                                                          fontSize: 13)),
                                                  Text("hours",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Spacer between left stats and model
                                  const SizedBox(width: 12),

                                  // Right area: center the 3D model visually
                                  Expanded(
                                    child: Column(
                                      children: [
                                        // keep a top-right settings icon aligned to the right
                                        Row(
                                          children: [
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.settings),
                                              onPressed: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            const SettingsScreen()));
                                              },
                                            ),
                                          ],
                                        ),
                                        // model area with fixed size so the model is visible enough
                                        // --- REPLACEMENT: bigger 3D model area (make the character larger) ---
                                        SizedBox(
                                          // make overall model area taller so the model has room and doesn't get clipped
                                          height: headerHeight -
                                              120, // sedikit lebih besar dari sebelumnya
                                          child: Center(
                                            child: SizedBox(
                                              // make the model box larger
                                              width: 380,
                                              height: 380,
                                              child: O3D(
                                                key: ValueKey(modelPath),
                                                src: modelPath,
                                                controller: o3dController,
                                                ar: false,
                                                autoPlay: true,
                                                autoRotate: false,
                                                cameraControls: false,
                                                // bring the camera closer (smaller radius / z) so the model appears larger
                                                cameraTarget: genderProvider
                                                            .gender ==
                                                        'male'
                                                    ? CameraTarget(-.25, 1.5,
                                                        0.8) // moved camera slightly forward
                                                    : CameraTarget(
                                                        -.25, 1.5, 1.2),
                                                // adjust orbit to a comfortable angle and smaller radius (last param)
                                                cameraOrbit: genderProvider
                                                            .gender ==
                                                        'male'
                                                    ? CameraOrbit(0, 90,
                                                        0.8) // tighter radius -> larger appearing model
                                                    : CameraOrbit(0, 90, 0.9),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // cards list
                    rows.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 24),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child:
                                      Center(child: Text('Tidak ada event.')),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final r = rows[index];
                                final item = CardItem.fromMap(r);
                                return Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 6, 12, 6),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 72,
                                              height: 72,
                                              child: item.imageUrl != null
                                                  ? (item.imageUrl!.startsWith('http')
                                                      ? Image.network(
                                                          item.imageUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) =>
                                                              const Icon(
                                                                  Icons.image))
                                                      : Image.asset(item.imageUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __,
                                                                  ___) =>
                                                              const Icon(
                                                                  Icons.image)))
                                                  : const Icon(
                                                      Icons.fitness_center,
                                                      size: 48),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                      item.subtitle ??
                                                          (item.authorName ??
                                                              ''),
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.black54)),
                                                  const SizedBox(height: 6),
                                                  if (item.eventDate != null)
                                                    Text(
                                                        '${item.eventDate!.toLocal().toString().split(' ')[0]} • ${item.categoryName ?? ''}',
                                                        style: const TextStyle(
                                                            fontSize: 12,
                                                            color:
                                                                Colors.grey)),
                                                  const SizedBox(height: 6),
                                                  if (item.collectedDonation !=
                                                          null ||
                                                      item.targetDonation !=
                                                          null)
                                                    Text(
                                                        'Raised: ${item.collectedDonation?.toStringAsFixed(0) ?? 0} / ${item.targetDonation?.toStringAsFixed(0) ?? 0}'),
                                                ],
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.location_on,
                                                color: Colors.red),
                                            onPressed: () => _confirmDelete(r),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: rows.length,
                            ),
                          ),

                    // bottom spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            ),

            // PAGE 2 (unchanged sample)
            ListView.builder(
              padding: EdgeInsets.fromLTRB(12, height * 0.8, 12, 100),
              itemCount: 100,
              itemBuilder: (context, index) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/image2.jpg',
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '10:24',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                'Morning walk',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '2 km in 30min',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.directions_walk_rounded,
                        color: Colors.red,
                      )
                    ],
                  ),
                ),
              ),
            ),

            // PAGE 3 (unchanged)
            ClipPath(
              clipper: InvertedCircleClipper(),
              child: Container(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: page,
        onTap: (page) {
          mainPageController.animateToPage(page,
              duration: const Duration(milliseconds: 500), curve: Curves.ease);
          textsPageController.animateToPage(page,
              duration: const Duration(milliseconds: 500), curve: Curves.ease);

          if (page == 0) {
            o3dController.cameraTarget(-.25, 1.5, 1.5);
            o3dController.cameraOrbit(0, 90, 1);
          } else if (page == 1) {
            o3dController.cameraTarget(0, 1.8, 0);
            o3dController.cameraOrbit(-90, 90, 1.5);
          } else if (page == 2) {
            if (genderProvider.gender == 'male') {
            } else {
              o3dController.cameraTarget(0, 3, 0);
              o3dController.cameraOrbit(0, 90, -3);
            }
          }

          setState(() {
            this.page = page;
          });
        },
        showUnselectedLabels: false,
        showSelectedLabels: false,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined), label: 'home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined), label: 'home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'home'),
        ],
      ),
    );
  }
}
