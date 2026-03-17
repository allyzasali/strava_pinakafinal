import 'package:latlong2/latlong.dart';

class ActivityResult {
  final String id;
  final double distance; // meters
  final int duration; // seconds
  final double averageSpeed; // km/h
  final List<LatLng> route;
  final DateTime date;

  ActivityResult({
    required this.id,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.route,
    required this.date,
  });

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }
    return '${(distance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedTime {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class StravaState {
  final bool isTracking;
  final bool isPaused;
  final List<LatLng> currentRoute;
  final List<LatLng> fullRoute;
  final double totalDistance;
  final int elapsedSeconds;
  final double averageSpeed;
  final List<ActivityResult> activityHistory;
  final bool showSummary;
  final bool showHistory;
  final ActivityResult? selectedActivity;

  StravaState({
    required this.isTracking,
    required this.isPaused,
    required this.currentRoute,
    required this.fullRoute,
    required this.totalDistance,
    required this.elapsedSeconds,
    required this.averageSpeed,
    required this.activityHistory,
    required this.showSummary,
    required this.showHistory,
    required this.selectedActivity,
  });

  StravaState copyWith({
    bool? isTracking,
    bool? isPaused,
    List<LatLng>? currentRoute,
    List<LatLng>? fullRoute,
    double? totalDistance,
    int? elapsedSeconds,
    double? averageSpeed,
    List<ActivityResult>? activityHistory,
    bool? showSummary,
    bool? showHistory,
    ActivityResult? selectedActivity,
  }) {
    return StravaState(
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      currentRoute: currentRoute ?? this.currentRoute,
      fullRoute: fullRoute ?? this.fullRoute,
      totalDistance: totalDistance ?? this.totalDistance,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      activityHistory: activityHistory ?? this.activityHistory,
      showSummary: showSummary ?? this.showSummary,
      showHistory: showHistory ?? this.showHistory,
      selectedActivity: selectedActivity ?? this.selectedActivity,
    );
  }
}