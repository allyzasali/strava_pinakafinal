import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../notifiers/strava_notifier.dart';
import '../models/models.dart';

// State providers
final stravaProvider = StateNotifierProvider<StravaNotifier, StravaState>((ref) {
  return StravaNotifier();
});

// Map controller provider
final mapControllerProvider = Provider<MapController>((ref) {
  return MapController();
});

// Permission status provider
final permissionStatusProvider = StateProvider<bool>((ref) {
  return false;
});

// Location services provider
final locationServicesEnabledProvider = StateProvider<bool>((ref) {
  return false;
});

// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});