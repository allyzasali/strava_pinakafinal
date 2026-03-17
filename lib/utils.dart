import 'dart:math';
import 'package:latlong2/latlong.dart';

double calculateDistance(LatLng p1, LatLng p2) {
  const double R = 6371000; // Earth radius in meters
  final dLat = (p2.latitude - p1.latitude) * (pi / 180);
  final dLon = (p2.longitude - p1.longitude) * (pi / 180);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(p1.latitude * (pi / 180)) *
          cos(p2.latitude * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)} m';
  }
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String formatTime(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}