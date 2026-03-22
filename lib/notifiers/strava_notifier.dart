import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/models.dart';
import '../utils/location_utils.dart';
import '../utils/storage_utils.dart';

class StravaNotifier extends StateNotifier<StravaState> {
  StreamSubscription<Position>? _positionStream;
  MapController? _mapController;
  Timer? _timer;
  Position? _lastPosition;

  StravaNotifier() : super(StravaState.initial()) {
    _loadHistory();
  }

  void setMapController(MapController controller) {
    _mapController = controller;
  }

  Future<void> _loadHistory() async {
    final history = await StorageUtils.loadActivityHistory();
    state = state.copyWith(activityHistory: history);
  }

  Future<void> _saveHistory() async {
    await StorageUtils.saveActivityHistory(state.activityHistory);
  }

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);

    state = state.copyWith(
      isTracking: true,
      isPaused: false,
      showSummary: false,
      currentRoute: [],
      fullRoute: [],
      elapsedSeconds: 0,
      totalDistance: 0,
      averageSpeed: 0,
      startTime: DateTime.now(),
    );

    _startTimer();
  }

  void pauseTracking() {
    _positionStream?.pause();
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resumeTracking() {
    _positionStream?.resume();
    _startTimer();
    state = state.copyWith(isPaused: false);
  }

  void stopTracking() {
    _positionStream?.cancel();
    _timer?.cancel();

    final newActivity = ActivityResult(
      date: state.startTime ?? DateTime.now(),
      duration: state.elapsedSeconds,
      distance: state.totalDistance,
      averageSpeed: state.averageSpeed,
      route: List.from(state.currentRoute),
    );

    final updatedHistory = [newActivity, ...state.activityHistory];

    state = state.copyWith(
      isTracking: false,
      isPaused: false,
      showSummary: true,
      fullRoute: List.from(state.currentRoute),
      activityHistory: updatedHistory,
    );

    _saveHistory();
  }

  void resetTracking() {
    state = state.copyWith(
      isTracking: false,
      isPaused: false,
      showSummary: false,
      currentRoute: [],
      fullRoute: [],
      elapsedSeconds: 0,
      totalDistance: 0,
      averageSpeed: 0,
      startTime: null,
    );
  }

  void toggleHistory() {
    state = state.copyWith(
      showHistory: !state.showHistory,
      selectedActivity: null,
    );
  }

  void viewActivityDetails(ActivityResult activity) {
    state = state.copyWith(
      selectedActivity: activity,
      showHistory: false,
      showSummary: false,
    );

    if (_mapController != null && activity.route.isNotEmpty) {
      final bounds = LocationUtils.calculateBounds(activity.route);
      _mapController?.fitBounds(bounds);
    }
  }

  void backToHistory() {
    state = state.copyWith(
      selectedActivity: null,
      showHistory: true,
    );
  }

  void _onPositionUpdate(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);
    final updatedRoute = List<LatLng>.from(state.currentRoute)..add(currentPoint);

    double newDistance = state.totalDistance;
    if (_lastPosition != null) {
      final distance = LocationUtils.calculateDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      newDistance += distance;
    }

    _lastPosition = position;

    if (!state.isPaused && _mapController != null) {
      _mapController?.move(currentPoint, _mapController?.camera.zoom ?? 16);
    }

    state = state.copyWith(
      currentRoute: updatedRoute,
      totalDistance: newDistance,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isPaused && state.isTracking) {
        final newElapsedSeconds = state.elapsedSeconds + 1;
        final newAverageSpeed = state.totalDistance / (newElapsedSeconds / 3600);

        state = state.copyWith(
          elapsedSeconds: newElapsedSeconds,
          averageSpeed: newAverageSpeed.isFinite ? newAverageSpeed : 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}