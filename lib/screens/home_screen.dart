import 'package:flutter/material.dart';

import 'package:o3d/o3d.dart';
import 'package:project_3d/provider/gender_provider.dart';
import 'package:project_3d/screens/settings_screen.dart';
import 'package:project_3d/services/weather_service.dart';
import 'package:provider/provider.dart';
import 'package:project_3d/utils/weather_icons.dart';

import '../inverted_circle_clipper.dart';

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


  @override
  void initState() {
    super.initState();
    _fetchWeather();
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


  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    final genderProvider = Provider.of<GenderProvider>(context);

    final String modelPath =
        genderProvider.gender == "male"
            ? 'assets/male_basic_walk_30_frames_loop.glb'
            : 'assets/disney_style_character.glb';

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            O3D(
              key: ValueKey(modelPath),
              src: modelPath,
              controller: o3dController,
              ar: false,
              autoPlay: true,
              autoRotate: false,
              cameraControls: false,
              cameraTarget: genderProvider.gender == 'male'
                  ? CameraTarget(-.25, 1.5, 0)
                  : CameraTarget(-.25, 1.5, 1.5),
              cameraOrbit: CameraOrbit(0, 90, 1),
            ),
            PageView(
              controller: mainPageController,
              children: [
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
                            'assets/image1.jpg',
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
                                    'A simple way to stay healthy',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Dr Babak',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
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
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    'Morning walk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '2 km in 30min',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12),
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
                ClipPath(
                    clipper: InvertedCircleClipper(),
                    child: Container(
                      color: Colors.white,
                    ),
                  )
              ],
            ),
            Container(
              width: 100,
              height: double.infinity,
              margin: const EdgeInsets.all(12),
              child: PageView(
                controller: textsPageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  Column(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text("Daily goals"),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text("87"),
                              ),
                            ),
                            Transform.translate(
                                offset: const Offset(0, 20),
                                child: const Text("%"))
                          ],
                        ),
                      ),
                      const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.local_fire_department_outlined,
                                color: Colors.red),
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("1,840"),
                              Text(
                                "calories",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ))
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child:
                                Icon(Icons.do_not_step, color: Colors.purple),
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("3,480"),
                              Text(
                                "steps",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ))
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.hourglass_bottom,
                                color: Colors.lightBlueAccent),
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("6.5"),
                              Text(
                                "hours",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ))
                        ],
                      ),
                    ],
                  ),


                  Builder(
                    builder: (context) {
                      if (_loadingWeather) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_weather == null) {
                        return const Center(child: Text('Failed to load weather'));
                      }

                      final temp = _weather!['temperature'];
                      final wind = _weather!['windspeed'];
                      final code = _weather!['weathercode'];

                      return Column(
                        children: [
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                   "${temp?.toStringAsFixed(0) ?? temp}°C",
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(iconFromWeatherCode(code), size: 18, color: Colors.blueGrey),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.fitWidth,
                                      child: Text(
                                        "Wind ${wind?.toStringAsFixed(0) ?? wind} km/h",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              const SizedBox(height: 6),

                            // Keterangan kecil di bawah (kode cuaca)
                            Text(
                              "Code $code",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      );
                    },
                  ),

                  // Column(
                  //   children: [
                  //     const SizedBox(
                  //       width: double.infinity,
                  //       child: FittedBox(
                  //         fit: BoxFit.fitWidth,
                  //         child: Text("Journal"),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: double.infinity,
                  //       child: Row(
                  //         children: [
                  //           Transform.translate(
                  //               offset: const Offset(0, 20),
                  //               child: const Text("<")),
                  //           const Expanded(
                  //             child: FittedBox(
                  //               fit: BoxFit.fitWidth,
                  //               child: Text("12"),
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //     const Text(
                  //       "July 2020",
                  //       style: TextStyle(fontSize: 12, color: Colors.grey),
                  //     ),
                  //   ],
                  // ),


                  const Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text("Profile"),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text("Dis"),
                        ),
                      ),
                      Text(
                        "23 years old",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: page,
          onTap: (page) {
            mainPageController.animateToPage(page,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease);
            textsPageController.animateToPage(page,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease);

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
          ]),
    );
  }
}
