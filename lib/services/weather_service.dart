import 'dart:convert';

import 'package:http/http.dart' as http;

/// Snapshot of current weather conditions for a coordinate.
class WeatherData {
  const WeatherData({
    required this.temperatureC,
    required this.weatherCode,
    required this.isDay,
  });

  final double temperatureC;
  final int weatherCode;
  final bool isDay;
}

/// Fetches current weather from the free, key-less Open-Meteo API.
///
/// https://open-meteo.com/ — no API key or registration required.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WeatherData?> fetch(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weather_code,is_day',
    );

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) {
        return null;
      }

      return WeatherData(
        temperatureC: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        isDay: (current['is_day'] as num).toInt() == 1,
      );
    } catch (_) {
      return null;
    }
  }
}
