import 'package:flutter/material.dart';

IconData iconFromWeatherCode(int? code) {
  if (code == null) return Icons.help_outline;

  // Open-Meteo weather codes (simplified)
  if (code == 0) return Icons.wb_sunny;                  // Clear
  if (code == 1 || code == 2) return Icons.wb_cloudy;     // Mostly/Partly cloudy
  if (code == 3) return Icons.cloud;                      // Overcast
  if ((code >= 45 && code <= 48)) return Icons.foggy;     // Fog
  if ((code >= 51 && code <= 67)) return Icons.umbrella;  // Drizzle/Rain
  if ((code >= 71 && code <= 77)) return Icons.ac_unit;   // Snow
  if ((code >= 80 && code <= 82)) return Icons.grain;     // Rain showers
  if ((code >= 85 && code <= 86)) return Icons.ac_unit;   // Snow showers
  if ((code >= 95)) return Icons.thunderstorm;            // Thunderstorm
  return Icons.help_outline;
}
