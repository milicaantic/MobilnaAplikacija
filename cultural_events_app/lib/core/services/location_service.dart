import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

class LocationService {
  final Dio _dio;
  final String _apiKey = 'b266533fb3b82efa6c1e3ff18939ea78';

  LocationService(this._dio);

  Future<Map<String, double>> getCoordinates(String address) async {
    try {
      final response = await _dio.get(
        'http://api.openweathermap.org/geo/1.0/direct',
        queryParameters: {'q': address, 'limit': 1, 'appid': _apiKey},
      );

      final List data = response.data;
      if (data.isNotEmpty) {
        final location = data[0];
        return {
          'lat': (location['lat'] as num).toDouble(),
          'lng': (location['lon'] as num).toDouble(),
        };
      } else {
        throw Exception('Location not found: $address');
      }
    } on DioException catch (e) {
      throw Exception('Network error during geocoding: ${e.message}');
    } catch (e) {
      throw Exception('Failed to geocode address: $e');
    }
  }
}

@riverpod
LocationService locationService(Ref ref) {
  return LocationService(Dio());
}

@riverpod
Future<Map<String, double>> geocode(Ref ref, String address) {
  return ref.watch(locationServiceProvider).getCoordinates(address);
}
