import 'package:flutter/material.dart';
import 'package:project_3d/provider/gender_provider.dart';
import 'package:project_3d/screens/home_screen.dart';

import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => GenderProvider()..loadGender(), // ✅ langsung load saat create
        ),
      ],
      child: const MyApp(),
    ),
  );
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
      home: const HomeScreen(),
    );
  }
}