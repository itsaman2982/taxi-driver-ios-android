import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import 'package:taxi_driver/src/core/map/mappls_config.dart';

class MapplsService {
  MapplsService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    ),
  );

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  static Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final response = await _dio.post(
        'https://outpost.mappls.com/api/security/oauth/token',
        data: {
          'grant_type': 'client_credentials',
          'client_id': MapplsConfig.atlasClientId,
          'client_secret': MapplsConfig.atlasClientSecret,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data['access_token']?.toString();
        final expiresIn = int.tryParse('${response.data['expires_in'] ?? 86400}') ?? 86400;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        return _accessToken;
      }
    } catch (e) {
      debugPrint('Mappls OAuth error: $e');
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getRoute({
    required LatLng start,
    required LatLng end,
    bool alternatives = false,
  }) async {
    try {
      final token = await _getAccessToken();
      if (token == null) return null;

      final response = await _dio.get(
        'https://apis.mappls.com/advancedmaps/v1/${MapplsConfig.restApiKey}/route_adv/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: {
          'geometries': 'geojson',
          'overview': 'full',
          'alternatives': alternatives,
          'steps': false,
          'annotations': 'speed',
        },
        options: Options(
          headers: {
            'Authorization': 'bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _parseRouteResponse(response.data as Map<String, dynamic>, alternatives);
      }
    } catch (e) {
      debugPrint('Mappls route error: $e');
    }

    final fallback = await _getOsrmRoute(
      start: start,
      end: end,
      alternatives: alternatives,
    );
    if (fallback != null) {
      return fallback;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _getOsrmRoute({
    required LatLng start,
    required LatLng end,
    required bool alternatives,
  }) async {
    try {
      final response = await _dio.get(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'alternatives': alternatives ? 'true' : 'false',
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _parseOsrmRouteResponse(response.data as Map<String, dynamic>, alternatives);
      }
    } catch (e) {
      debugPrint('OSRM fallback route error: $e');
    }

    return null;
  }

  static String stillImageUrl({
    required double latitude,
    required double longitude,
    int zoom = 14,
    String size = '700x380',
    List<String> markers = const [],
  }) {
    final base = Uri.parse(
      'https://apis.mappls.com/advancedmaps/v1/${MapplsConfig.restApiKey}/still_image',
    );

    return base.replace(
      queryParameters: {
        'center': '$latitude,$longitude',
        'zoom': '$zoom',
        'size': size,
        'ssf': '1',
        if (markers.isNotEmpty) 'markers': markers.join('|'),
      },
    ).toString();
  }

  static Map<String, dynamic>? _parseRouteResponse(
    Map<String, dynamic> data,
    bool alternatives,
  ) {
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;

    final primaryRoute = Map<String, dynamic>.from(routes.first as Map);
    final coordinates = primaryRoute['geometry']?['coordinates'] as List?;
    if (coordinates == null) return null;

    final routePoints = coordinates
        .whereType<List>()
        .where((c) => c.length >= 2)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    final trafficSegments = <Map<String, dynamic>>[];
    try {
      final speeds = primaryRoute['legs']?[0]?['annotation']?['speed'] as List?;
      if (speeds != null) {
        for (var i = 0; i < routePoints.length - 1 && i < speeds.length; i++) {
          final speed = (speeds[i] as num).toDouble();
          var color = Colors.blue;
          if (speed < 15) {
            color = Colors.red;
          } else if (speed < 25) {
            color = Colors.orange;
          }
          trafficSegments.add({
            'points': [routePoints[i], routePoints[i + 1]],
            'color': color,
          });
        }
      }
    } catch (_) {}

    final altRoutePoints = <LatLng>[];
    var altRouteEta = '';
    if (alternatives && routes.length > 1) {
      final alternateRoute = Map<String, dynamic>.from(routes[1] as Map);
      final altCoords = alternateRoute['geometry']?['coordinates'] as List?;
      if (altCoords != null) {
        altRoutePoints.addAll(
          altCoords
              .whereType<List>()
              .where((c) => c.length >= 2)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())),
        );
        altRouteEta = '${(((alternateRoute['duration'] as num?)?.toDouble() ?? 0) / 60).round()} min';
      }
    }

    final distance = (primaryRoute['distance'] as num?)?.toDouble() ?? 0;
    final duration = (primaryRoute['duration'] as num?)?.toDouble() ?? 0;

    return {
      'routePoints': routePoints,
      'trafficSegments': trafficSegments,
      'altRoutePoints': altRoutePoints,
      'altRouteEta': altRouteEta,
      'distanceMeters': distance,
      'durationSeconds': duration,
    };
  }

  static Map<String, dynamic>? _parseOsrmRouteResponse(
    Map<String, dynamic> data,
    bool alternatives,
  ) {
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return null;

    final primaryRoute = Map<String, dynamic>.from(routes.first as Map);
    final geometry = primaryRoute['geometry'];
    final coordinates = geometry is Map ? geometry['coordinates'] as List? : null;
    if (coordinates == null) return null;

    final routePoints = coordinates
        .whereType<List>()
        .where((c) => c.length >= 2)
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();

    final altRoutePoints = <LatLng>[];
    var altRouteEta = '';
    if (alternatives && routes.length > 1) {
      final alternateRoute = Map<String, dynamic>.from(routes[1] as Map);
      final altGeometry = alternateRoute['geometry'];
      final altCoords = altGeometry is Map ? altGeometry['coordinates'] as List? : null;
      if (altCoords != null) {
        altRoutePoints.addAll(
          altCoords
              .whereType<List>()
              .where((c) => c.length >= 2)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())),
        );
        altRouteEta = '${(((alternateRoute['duration'] as num?)?.toDouble() ?? 0) / 60).round()} min';
      }
    }

    final distance = (primaryRoute['distance'] as num?)?.toDouble() ?? 0;
    final duration = (primaryRoute['duration'] as num?)?.toDouble() ?? 0;

    return {
      'routePoints': routePoints,
      'trafficSegments': const <Map<String, dynamic>>[],
      'altRoutePoints': altRoutePoints,
      'altRouteEta': altRouteEta,
      'distanceMeters': distance,
      'durationSeconds': duration,
    };
  }
}
