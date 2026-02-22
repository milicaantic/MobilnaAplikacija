import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weather_service.g.dart';

class WeatherService {
  final Dio _dio;
  final String _apiKey = 'b266533fb3b82efa6c1e3ff18939ea78';

  WeatherService(this._dio);

  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    try {
      final response = await _dio.get(
        'https://api.openweathermap.org/data/2.5/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': _apiKey,
          'units': 'metric',
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load weather: $e');
    }
  }
}

@riverpod
WeatherService weatherService(Ref ref) {
  return WeatherService(Dio());
}

@riverpod
Future<Map<String, dynamic>> currentWeather(
  Ref ref, {
  required double lat,
  required double lon,
}) {
  return ref.watch(weatherServiceProvider).getCurrentWeather(lat, lon);
}
