import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'models.dart';

class StravaNotifier extends StateNotifier<StravaState> {
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _positionStream;
  Timer? _statsTimer;
  MapController? _mapController;

  StravaNotifier()
    : super(
        const StravaState(
          isTracking: false,
          isPaused: false,
          showSummary: false,
          showHistory: false,
          selectedActivity: null,
          currentRoute: [],
          fullRoute: [],
          totalDistance: 0.0,
          elapsedSeconds: 0,
          averageSpeed: 0.0,
          activityHistory: [],
        ),
      );

  void startTracking() {
    state = state.copyWith(
      isTracking: true,
      isPaused: false,
      showSummary: false,
      showHistory: false,
      selectedActivity: null,
      currentRoute: [],
      fullRoute: [],
      totalDistance: 0.0,
      elapsedSeconds: 0,
      averageSpeed: 0.0,
    );

    // Setup location stream
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!state.isPaused && state.isTracking) {
              final newPoint = LatLng(position.latitude, position.longitude);
              updateRoute(newPoint);
              _mapController?.move(newPoint, _mapController!.camera.zoom);
            }
          },
        );

    // Setup stats timer
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      updateElapsed();
    });
  }

  (LatLng, double) updateRoute(LatLng newPoint) {
    double segmentDistance = 0.0;
    final List<LatLng> newCurrent = List<LatLng>.from(state.currentRoute);
    if (newCurrent.isNotEmpty) {
      segmentDistance = _distance(newCurrent.last, newPoint);
    }
    newCurrent.add(newPoint);
    final double newDistance = state.totalDistance + segmentDistance;

    state = state.copyWith(
      currentRoute: newCurrent,
      fullRoute: [...state.fullRoute, newPoint],
      totalDistance: newDistance,
    );

    return (newPoint, state.averageSpeed);
  }

  void updateElapsed() {
    if (!state.isPaused && state.isTracking) {
      final int newElapsed = state.elapsedSeconds + 1;
      final double newAvg = _calculateAverageSpeed(newElapsed);
      state = state.copyWith(elapsedSeconds: newElapsed, averageSpeed: newAvg);
    }
  }

  double _calculateAverageSpeed(int seconds) {
    if (seconds <= 0) return 0.0;
    final double distanceKm = state.totalDistance / 1000;
    final double hours = seconds / 3600.0;
    return hours > 0 ? distanceKm / hours : 0.0;
  }

  void pauseTracking() {
    state = state.copyWith(isPaused: true);
  }

  void resumeTracking() {
    state = state.copyWith(isPaused: false);
  }

  void stopTracking() {
    _positionStream?.cancel();
    _statsTimer?.cancel();

    if (state.totalDistance > 0) {
      final ActivityResult result = ActivityResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        distance: state.totalDistance,
        duration: state.elapsedSeconds,
        averageSpeed: state.averageSpeed,
        route: state.fullRoute,
      );

      final List<ActivityResult> newHistory = List<ActivityResult>.from(
        state.activityHistory,
      );
      newHistory.insert(0, result);

      state = state.copyWith(
        isTracking: false,
        isPaused: false,
        showSummary: true,
        activityHistory: newHistory,
      );
    } else {
      state = state.copyWith(
        isTracking: false,
        isPaused: false,
        showSummary: true,
      );
    }
  }

  void resetTracking() {
    _positionStream?.cancel();
    _statsTimer?.cancel();
    state = state.copyWith(
      showSummary: false,
      currentRoute: [],
      fullRoute: [],
      totalDistance: 0.0,
      elapsedSeconds: 0,
      averageSpeed: 0.0,
      selectedActivity: null,
    );
  }

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  void toggleHistory() {
    state = state.copyWith(
      showHistory: !state.showHistory,
      showSummary: false,
      selectedActivity: null,
    );
  }

  void viewActivityDetails(ActivityResult activity) {
    state = state.copyWith(
      selectedActivity: activity,
      showHistory: false,
      showSummary: false,
    );
  }

  void backToHistory() {
    state = state.copyWith(selectedActivity: null, showHistory: true);
  }
}
