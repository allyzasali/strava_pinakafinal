import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'utils.dart';

class StravaNotifier extends StateNotifier<StravaState> {
  StreamSubscription<Position>? _positionSubscription;
  MapController? _mapController;
  DateTime? _startTime;
  DateTime? _pauseStart;
  int _elapsedSecondsPaused = 0;
  double _totalDistance = 0.0;
  List<LatLng> _currentRoute = [];
  List<LatLng> _fullRoute = [];

  StravaNotifier() : super(StravaState(
    isTracking: false,
    isPaused: false,
    currentRoute: [],
    fullRoute: [],
    totalDistance: 0.0,
    elapsedSeconds: 0,
    averageSpeed: 0.0,
    activityHistory: [],
    showSummary: false,
    showHistory: false,
    selectedActivity: null,
  ));

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  void startTracking() {
    if (state.isTracking) return;

    _startTime = DateTime.now();
    _pauseStart = null;
    _elapsedSecondsPaused = 0;
    _totalDistance = 0.0;
    _currentRoute = [];
    _fullRoute = [];

    state = state.copyWith(
      isTracking: true,
      isPaused: false,
      currentRoute: [],
      fullRoute: [],
      totalDistance: 0.0,
      elapsedSeconds: 0,
      averageSpeed: 0.0,
      showSummary: false,
      showHistory: false,
      selectedActivity: null,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!state.isTracking || state.isPaused) return;

      final newPoint = LatLng(position.latitude, position.longitude);
      if (_currentRoute.isNotEmpty) {
        final lastPoint = _currentRoute.last;
        final distance = calculateDistance(lastPoint, newPoint);
        _totalDistance += distance;
        state = state.copyWith(totalDistance: _totalDistance);
      }
      _currentRoute.add(newPoint);
      _fullRoute.add(newPoint);

      // Update average speed (km/h) – only if elapsed time > 0
      final elapsed = _getElapsedSeconds();
      final speed = elapsed > 0 ? (_totalDistance / 1000) / (elapsed / 3600) : 0.0;
      state = state.copyWith(
        currentRoute: List.from(_currentRoute),
        fullRoute: List.from(_fullRoute),
        averageSpeed: speed,
        elapsedSeconds: elapsed,
      );

      // Center map on current location if map controller available
      _mapController?.move(newPoint, _mapController?.camera.zoom ?? 15);
    });
  }

  void pauseTracking() {
    if (!state.isTracking || state.isPaused) return;
    _pauseStart = DateTime.now();
    state = state.copyWith(isPaused: true);
  }

  void resumeTracking() {
    if (!state.isTracking || !state.isPaused) return;
    if (_pauseStart != null) {
      _elapsedSecondsPaused += DateTime.now().difference(_pauseStart!).inSeconds;
      _pauseStart = null;
    }
    state = state.copyWith(isPaused: false);
  }

  void stopTracking() {
    if (!state.isTracking) return;

    _positionSubscription?.cancel();
    final endTime = DateTime.now();
    final elapsed = _getElapsedSeconds();

    final activity = ActivityResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      distance: _totalDistance,
      duration: elapsed,
      averageSpeed: _totalDistance > 0 ? (_totalDistance / 1000) / (elapsed / 3600) : 0.0,
      route: List.from(_fullRoute),
      date: _startTime!,
    );

    final newHistory = [activity, ...state.activityHistory];

    state = state.copyWith(
      isTracking: false,
      isPaused: false,
      currentRoute: [],
      fullRoute: List.from(_fullRoute),
      totalDistance: _totalDistance,
      elapsedSeconds: elapsed,
      averageSpeed: _totalDistance > 0 ? (_totalDistance / 1000) / (elapsed / 3600) : 0.0,
      activityHistory: newHistory,
      showSummary: true,
    );
  }

  void resetTracking() {
    _positionSubscription?.cancel();
    state = state.copyWith(
      isTracking: false,
      isPaused: false,
      currentRoute: [],
      fullRoute: [],
      totalDistance: 0.0,
      elapsedSeconds: 0,
      averageSpeed: 0.0,
      showSummary: false,
    );
  }

  void toggleHistory() {
    state = state.copyWith(
      showHistory: !state.showHistory,
      selectedActivity: null,
      showSummary: false,
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
    state = state.copyWith(
      selectedActivity: null,
      showHistory: true,
    );
  }

  int _getElapsedSeconds() {
    if (_startTime == null) return 0;
    final now = DateTime.now();
    int elapsed = now.difference(_startTime!).inSeconds;
    if (_pauseStart != null) {
      elapsed -= now.difference(_pauseStart!).inSeconds;
    }
    elapsed -= _elapsedSecondsPaused;
    return elapsed;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}