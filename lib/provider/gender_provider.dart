import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenderProvider extends ChangeNotifier {
  String _gender = "female"; // default

  String get gender => _gender;

  Future<void> loadGender() async {
    final prefs = await SharedPreferences.getInstance();
    _gender = prefs.getString("gender") ?? "female";
    notifyListeners();
  }

  Future<void> setGender(String value) async {
    _gender = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender", value);
    notifyListeners();
  }
}
