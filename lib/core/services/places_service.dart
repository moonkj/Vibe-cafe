import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// Google Maps API key — same key used in AppDelegate.swift
const _mapsApiKey = String.fromEnvironment(
  'MAPS_API_KEY',
  defaultValue: 'AIzaSyBigJrMfUqNTkMyoy_rOli5M1PRdP2YDOU',
);

class PlacePrediction {
  final String placeId;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceLatLng {
  final double lat;
  final double lng;
  const PlaceLatLng({required this.lat, required this.lng});
}

class PlacesService {
  final http.Client _client;
  PlacesService({http.Client? client}) : _client = client ?? http.Client();

  /// Returns autocomplete predictions for [input], biased toward [lat]/[lng].
  Future<List<PlacePrediction>> autocomplete(
    String input, {
    double? lat,
    double? lng,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': _mapsApiKey,
      'language': 'ko',
      'components': 'country:kr',
    };
    if (lat != null && lng != null) {
      params['location'] = '$lat,$lng';
      params['radius'] = '50000';
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        params,
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      final body = response.body;
      debugPrint('[Places] HTTP ${response.statusCode} | ${body.length > 300 ? body.substring(0, 300) : body}');
      if (response.statusCode != 200) return [];

      final data = json.decode(body) as Map<String, dynamic>;
      debugPrint('[Places] status=${data['status']} error=${data['error_message']}');
      final predictions = data['predictions'] as List<dynamic>? ?? [];

      return predictions.map((p) {
        final structured =
            p['structured_formatting'] as Map<String, dynamic>? ?? {};
        return PlacePrediction(
          placeId: p['place_id'] as String,
          mainText: structured['main_text'] as String? ??
              p['description'] as String,
          secondaryText: structured['secondary_text'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[Places] autocomplete error: $e');
      return [];
    }
  }

  /// Returns lat/lng for a given [placeId].
  Future<PlaceLatLng?> getDetails(String placeId) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': placeId,
          'fields': 'geometry',
          'key': _mapsApiKey,
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final location = (result?['geometry'] as Map<String, dynamic>?)?['location']
          as Map<String, dynamic>?;
      if (location == null) return null;

      return PlaceLatLng(
        lat: (location['lat'] as num).toDouble(),
        lng: (location['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

final placesServiceProvider = Provider<PlacesService>((_) => PlacesService());
