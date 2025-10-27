import 'package:flutter/material.dart';
import 'package:project_3d/provider/gender_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GenderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        children: [
          RadioListTile(
            title: const Text("Perempuan"),
            value: "female",
            groupValue: provider.gender,
            onChanged: (value) {
              provider.setGender(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile(
            title: const Text("Laki-Laki"),
            value: "male",
            groupValue: provider.gender,
            onChanged: (value) {
              provider.setGender(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
