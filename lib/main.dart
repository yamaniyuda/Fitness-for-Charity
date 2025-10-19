import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'inverted_circle_clipper.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.init();
  runApp(const MyApp());
}

class DBHelper {
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'auth.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT UNIQUE,
          password TEXT
        )
      ''');
    });
  }

  Future<bool> createUser(String email, String password) async {
    try {
      final id = await _db!.insert('users', {'email': email, 'password': password});
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> userExists(String email) async {
    final res = await _db!.query('users', where: 'email = ?', whereArgs: [email]);
    return res.isNotEmpty;
  }

  Future<bool> validateUser(String email, String password) async {
    final res = await _db!.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      scaffoldMessengerKey: messengerKey,
      title: 'UI 3D flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// Simple Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;

  void _login() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;

    if (email.isEmpty || pass.isEmpty) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final ok = await DBHelper.instance.validateUser(email, pass);

      if (!mounted) return;
      setState(() => _loading = false);

      if (ok) {
        navKey.currentState?.pushReplacement(MaterialPageRoute(builder: (_) => const MyHomePage()));
      } else {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => navKey.currentState?.push(MaterialPageRoute(builder: (_) => const SignUpScreen())),
              child: const Text('Don\'t have an account? Sign up'),
            )
          ],
        ),
      ),
    );
  }
}

// Simple Sign Up Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _loading = false;

  void _signup() async {
    final email = _emailC.text.trim();
    final pass = _passC.text;
    final conf = _confirmC.text;

    if (email.isEmpty || pass.isEmpty) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }
    if (pass != conf) {
      messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final exists = await DBHelper.instance.userExists(email);
      if (exists) {
        if (!mounted) return;
        setState(() => _loading = false);
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Email already registered')));
        return;
      }

      final created = await DBHelper.instance.createUser(email, pass);
      if (!mounted) return;
      setState(() => _loading = false);

      if (created) {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Account created. Please log in.')));
        navKey.currentState?.pop();
      } else {
        messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Failed to create account')));
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text('Sign up error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: _confirmC, decoration: const InputDecoration(labelText: 'Confirm password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loading ? null : _signup, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign up')),
          ],
        ),
      ),
    );
  }
}

// Existing app home (keeps your original MyHomePage UI)
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  O3DController o3dController = O3DController();
  PageController mainPageController = PageController();
  PageController textsPageController = PageController();
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Stack(
          children: [
            O3D(
              src: 'assets/disney_style_character.glb',
              controller: o3dController,
              ar: false,
              autoPlay: true,
              autoRotate: false,
              cameraControls: false,
              cameraTarget: CameraTarget(-.25, 1.5, 1.5),
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
                        Image.asset('assets/image1.jpg',
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
                              Text('A simple way to stay healthy',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Dr Babak',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),

                        const Icon(Icons.location_on,
                          color: Colors.red,
                        )

                      ],
                    ),
                  ),
                ),),
                ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, height * 0.8, 12, 100),
                  itemCount: 100,
                  itemBuilder: (context, index) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/image2.jpg',
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
                                  Text('10:24',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12
                                    ),
                                  ),
                                  Text('Morning walk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('2 km in 30min',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Icon(Icons.directions_walk_rounded,
                            color: Colors.red,
                          )

                        ],
                      ),
                    ),
                  ),),
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
                            child: Icon(Icons.do_not_step, color: Colors.purple),
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
                  Column(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: Text("Journal"),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Transform.translate(
                                offset: const Offset(0, 20),
                                child: const Text("<")),
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text("12"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        "July 2020",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
              o3dController.cameraTarget(0, 3, 0);
              o3dController.cameraOrbit(0, 90, -3);
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
// ...existing code...