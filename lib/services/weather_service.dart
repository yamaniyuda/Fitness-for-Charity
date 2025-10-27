import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<Map<String, dynamic>?> getWeather(
      {double lat = 3.5952, double lon = 98.6722}) async {
        
    final Uri url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon&current_weather=true'
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["current_weather"];
    }
    return null;
  }

  Future<Map<String, dynamic>?> getWeatherByCity(String city) async {
    final key = city.toLowerCase().trim();
    final coords = _cityCoordinates[key];
    if (coords == null) return null;
    return getWeather(lat: coords['lat']!, lon: coords['lon']!);
  }

  final Map<String, Map<String, double>> _cityCoordinates = {
    'medan': {'lat': 3.5952, 'lon': 98.6722},
    'jakarta': {'lat': -6.2000, 'lon': 106.8166},
  };
}
