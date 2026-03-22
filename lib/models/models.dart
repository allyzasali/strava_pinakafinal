import 'package:latlong2/latlong.dart';

class ActivityResult {
  final DateTime date;
  final int duration;
  final double distance;
  final double averageSpeed;
  final List<LatLng> route;

  ActivityResult({
    required this.date,
    required this.duration,
    required this.distance,
    required this.averageSpeed,
    required this.route,
  });

  String get formattedDate {
    return '${date.month}/${date.day}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    int hours = duration ~/ 3600;
    int minutes = (duration % 3600) ~/ 60;
    int seconds = duration % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'duration': duration,
      'distance': distance,
      'averageSpeed': averageSpeed,
      'route': route.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
    };
  }

  factory ActivityResult.fromJson(Map<String, dynamic> json) {
    return ActivityResult(
      date: DateTime.parse(json['date']),
      duration: json['duration'],
      distance: json['distance'],
      averageSpeed: json['averageSpeed'],
      route: (json['route'] as List).map((point) => LatLng(
        point['latitude'],
        point['longitude'],
      )).toList(),
    );
  }
}

class StravaState {
  final bool isTracking;
  final bool isPaused;
  final bool showSummary;
  final bool showHistory;
  final List<LatLng> currentRoute;
  final List<LatLng> fullRoute;
  final int elapsedSeconds;
  final double totalDistance;
  final double averageSpeed;
  final List<ActivityResult> activityHistory;
  final ActivityResult? selectedActivity;
  final DateTime? startTime;

  StravaState({
    required this.isTracking,
    required this.isPaused,
    required this.showSummary,
    required this.showHistory,
    required this.currentRoute,
    required this.fullRoute,
    required this.elapsedSeconds,
    required this.totalDistance,
    required this.averageSpeed,
    required this.activityHistory,
    this.selectedActivity,
    this.startTime,
  });

  factory StravaState.initial() {
    return StravaState(
      isTracking: false,
      isPaused: false,
      showSummary: false,
      showHistory: false,
      currentRoute: [],
      fullRoute: [],
      elapsedSeconds: 0,
      totalDistance: 0,
      averageSpeed: 0,
      activityHistory: [],
      selectedActivity: null,
      startTime: null,
    );
  }

  StravaState copyWith({
    bool? isTracking,
    bool? isPaused,
    bool? showSummary,
    bool? showHistory,
    List<LatLng>? currentRoute,
    List<LatLng>? fullRoute,
    int? elapsedSeconds,
    double? totalDistance,
    double? averageSpeed,
    List<ActivityResult>? activityHistory,
    ActivityResult? selectedActivity,
    DateTime? startTime,
  }) {
    return StravaState(
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      showSummary: showSummary ?? this.showSummary,
      showHistory: showHistory ?? this.showHistory,
      currentRoute: currentRoute ?? this.currentRoute,
      fullRoute: fullRoute ?? this.fullRoute,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalDistance: totalDistance ?? this.totalDistance,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      activityHistory: activityHistory ?? this.activityHistory,
      selectedActivity: selectedActivity ?? this.selectedActivity,
      startTime: startTime ?? this.startTime,
    );
  }
}