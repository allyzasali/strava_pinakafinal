import 'package:latlong2/latlong.dart';

class ActivityResult {
  final String id;
  final DateTime date;
  final double distance;
  final int duration;
  final double averageSpeed;
  final List<LatLng> route;

  ActivityResult({
    required this.id,
    required this.date,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.route,
  });

  String get formattedDate {
    return '${date.month}/${date.day}/${date.year}';
  }

  String get formattedTime {
    int h = duration ~/ 3600;
    int m = (duration % 3600) ~/ 60;
    int s = duration % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }
}

class StravaState {
  final bool isTracking;
  final bool isPaused;
  final bool showSummary;
  final bool showHistory;
  final ActivityResult? selectedActivity;
  final List<LatLng> currentRoute;
  final List<LatLng> fullRoute;
  final double totalDistance;
  final int elapsedSeconds;
  final double averageSpeed;
  final List<ActivityResult> activityHistory;

  const StravaState({
    required this.isTracking,
    required this.isPaused,
    required this.showSummary,
    required this.showHistory,
    this.selectedActivity,
    required this.currentRoute,
    required this.fullRoute,
    required this.totalDistance,
    required this.elapsedSeconds,
    required this.averageSpeed,
    required this.activityHistory,
  });

  StravaState copyWith({
    bool? isTracking,
    bool? isPaused,
    bool? showSummary,
    bool? showHistory,
    ActivityResult? selectedActivity,
    List<LatLng>? currentRoute,
    List<LatLng>? fullRoute,
    double? totalDistance,
    int? elapsedSeconds,
    double? averageSpeed,
    List<ActivityResult>? activityHistory,
  }) {
    return StravaState(
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      showSummary: showSummary ?? this.showSummary,
      showHistory: showHistory ?? this.showHistory,
      selectedActivity: selectedActivity ?? this.selectedActivity,
      currentRoute: currentRoute ?? this.currentRoute,
      fullRoute: fullRoute ?? this.fullRoute,
      totalDistance: totalDistance ?? this.totalDistance,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      activityHistory: activityHistory ?? this.activityHistory,
    );
  }
}
