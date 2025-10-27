import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isFemale = true;
  String modelPath = 'assets/disney_style_character.glb';
  final O3DController controller = O3DController();

  void toggleGender(bool value) {
    setState(() {
      isFemale = value;
      if (isFemale) {
        modelPath = 'assets/disney_style_character.glb';
      } else {
        modelPath = 'assets/male_basic_walk_30_frames_loop.glb';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gender'),
                Switch(
                  value: isFemale,
                  onChanged: toggleGender,
                ),
              ],
            ),
            Expanded(
              child: O3D(
                src: modelPath,
                controller: controller,
                ar: false,
                autoPlay: true,
                cameraControls: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}