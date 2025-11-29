import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  LocationService._internal();

  static final LocationService instance = LocationService._internal();

  static const Duration _cacheDuration = Duration(seconds: 30);
  static const String _locationSource = 'ios_core_location';

  Map<String, dynamic>? _lastPayload;
  DateTime? _lastFetchTime;
  Future<void>? _initialPermissionRequest;

  Future<void> initialize() {
    _initialPermissionRequest ??= _ensurePermission();
    return _initialPermissionRequest!;
  }

  Future<Map<String, dynamic>?> getLocationPayload() async {
    final now = DateTime.now();
    if (_lastPayload != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      dev.log('Reusing cached location payload: ${jsonEncode(_lastPayload)}');
      return _lastPayload;
    }

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      dev.log('Location permission unavailable; returning null payload.');
      return null;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      dev.log('Device location services are disabled.');
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final timestamp = position.timestamp;
      final accuracy = position.accuracy;

      String? label;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          label = _formatPlacemark(placemarks.first);
        }
      } catch (e, stackTrace) {
        dev.log('Reverse geocoding failed: $e', error: e, stackTrace: stackTrace);
      }

      final payload = <String, dynamic>{
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy_meters': accuracy,
        'label': label,
        'source': _locationSource,
        'timestamp': timestamp.toIso8601String(),
      };

      _lastPayload = payload;
      _lastFetchTime = now;
      dev.log('Prepared new location payload: ${jsonEncode(payload)}');
      return payload;
    } catch (e, stackTrace) {
      dev.log('Failed to get current location: $e',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  String? _formatPlacemark(Placemark placemark) {
    final components = <String?>[
      placemark.name,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ];

    final filtered = components
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    if (filtered.isEmpty) {
      return null;
    }

    return filtered.join(', ');
  }
}
