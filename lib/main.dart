import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'models.dart';
import 'widgets.dart';
import 'utils.dart';

void main() {
  runApp(const ProviderScope(child: StravaApp()));
}

class StravaApp extends StatelessWidget {
  const StravaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/map': (context) => const MapScreen(),
      },
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeOrange,
      ),
    );
  }
}

/// Landing page shown before entering the map screen.
class LandingPage extends ConsumerWidget {
  const LandingPage({super.key});

  Future<void> _requestLocationPermissions(BuildContext context, WidgetRef ref) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Please enable location permissions to track your activities.',
            ),
            actions: [
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (context.mounted) {
      Navigator.pushNamed(context, '/map');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = CupertinoTheme.of(context);
    final backgroundColor = brightness == Brightness.dark
        ? CupertinoColors.black
        : CupertinoColors.white;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor,
                        CupertinoColors.systemPurple,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.location_fill,
                    color: CupertinoColors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Track Your Journey',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Record your activities, view routes, and analyse your performance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 48),
                CupertinoButton(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: () => _requestLocationPermissions(context, ref),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    child: Text(
                      'Start Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Main map screen with all tracking functionality.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    ref.read(stravaProvider.notifier).setMapController(mapController);
    _startTrackingAfterPermission();
  }

  Future<void> _startTrackingAfterPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Please enable location permissions to track your activities.',
            ),
            actions: [
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
      return;
    }
    ref.read(stravaProvider.notifier).startTracking();
  }

  void pauseTracking() => ref.read(stravaProvider.notifier).pauseTracking();
  void resumeTracking() => ref.read(stravaProvider.notifier).resumeTracking();
  void stopTracking() => ref.read(stravaProvider.notifier).stopTracking();

  void resetTracking() {
    ref.read(stravaProvider.notifier).resetTracking();
    ref.read(stravaProvider.notifier).startTracking();
  }

  void toggleHistory() => ref.read(stravaProvider.notifier).toggleHistory();
  void viewActivityDetails(ActivityResult activity) {
    ref.read(stravaProvider.notifier).viewActivityDetails(activity);
    if (activity.route.isNotEmpty) {
      _fitRouteBounds(activity.route);
    }
  }
  void backToHistory() => ref.read(stravaProvider.notifier).backToHistory();

  void _fitRouteBounds(List<LatLng> route) {
    if (route.isEmpty) return;
    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;
    for (final point in route) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    mapController.move(center, 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final stravaState = ref.watch(stravaProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final theme = CupertinoTheme.of(context);

    ref.listen(stravaProvider, (previous, next) {
      if ((previous?.showSummary ?? false) != next.showSummary) {
        if (next.showSummary) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });

    final tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final backgroundColor = CupertinoColors.systemBackground;
    final cardBackground = CupertinoColors.secondarySystemBackground;
    final textColor = CupertinoColors.label;
    final secondaryTextColor = CupertinoColors.secondaryLabel;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      child: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 15,
              maxZoom: 19,
              minZoom: 3,
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrlTemplate,
                userAgentPackageName: 'com.example.strava',
              ),

              // Polylines & markers
              if (stravaState.isTracking && stravaState.currentRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: stravaState.currentRoute,
                      color: theme.primaryColor,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (!stravaState.isTracking &&
                  stravaState.fullRoute.isNotEmpty &&
                  stravaState.showSummary)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: stravaState.fullRoute,
                      color: const Color(0xFF00B4D8),
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (stravaState.selectedActivity != null &&
                  stravaState.selectedActivity!.route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: stravaState.selectedActivity!.route,
                      color: CupertinoColors.systemBlue,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              if (stravaState.isTracking && stravaState.currentRoute.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: stravaState.currentRoute.last,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: CupertinoColors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              if (stravaState.selectedActivity != null &&
                  stravaState.selectedActivity!.route.length > 1)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: stravaState.selectedActivity!.route.first,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: CupertinoColors.white, width: 2),
                        ),
                        child: const Icon(
                          CupertinoIcons.flag_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Marker(
                      point: stravaState.selectedActivity!.route.last,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: CupertinoColors.white, width: 2),
                        ),
                        child: const Icon(
                          CupertinoIcons.flag_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Header (title + History button)
          if (!stravaState.showSummary &&
              !stravaState.showHistory &&
              stravaState.selectedActivity == null)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Strava',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: cardBackground.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.clock, color: textColor),
                        const SizedBox(width: 4),
                        Text('History', style: TextStyle(color: textColor)),
                      ],
                    ),
                    onPressed: toggleHistory,
                  ),
                ],
              ),
            ),

          // Activity Detail Header
          if (stravaState.selectedActivity != null)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    color: cardBackground.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.back, color: textColor),
                        const SizedBox(width: 4),
                        Text('Back', style: TextStyle(color: textColor)),
                      ],
                    ),
                    onPressed: backToHistory,
                  ),
                  Text(
                    'Activity Details',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 70),
                ],
              ),
            ),

          // Live stats card
          if (stravaState.isTracking &&
              !stravaState.showSummary &&
              !stravaState.showHistory &&
              stravaState.selectedActivity == null)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBackground.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (stravaState.isPaused)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CupertinoColors.systemYellow, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.pause_circle_fill, color: CupertinoColors.systemYellow, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'PAUSED',
                              style: TextStyle(
                                color: CupertinoColors.systemYellow,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        LiveStat(
                          value: formatDistance(stravaState.totalDistance),
                          label: 'DISTANCE',
                          color: CupertinoColors.systemGreen,
                          icon: CupertinoIcons.arrow_up_bin,
                        ),
                        LiveStat(
                          value: formatTime(stravaState.elapsedSeconds),
                          label: 'TIME',
                          color: CupertinoColors.systemBlue,
                          icon: CupertinoIcons.timer,
                        ),
                        LiveStat(
                          value: '${stravaState.averageSpeed.toStringAsFixed(1)} km/h',
                          label: 'AVG SPEED',
                          color: CupertinoColors.systemPurple,
                          icon: CupertinoIcons.speedometer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Activity Detail Stats Card
          if (stravaState.selectedActivity != null)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBackground.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        DetailStat(
                          value: formatDistance(stravaState.selectedActivity!.distance),
                          label: 'DISTANCE',
                          color: CupertinoColors.systemGreen,
                        ),
                        DetailStat(
                          value: stravaState.selectedActivity!.formattedTime,
                          label: 'TIME',
                          color: CupertinoColors.systemBlue,
                        ),
                        DetailStat(
                          value: '${stravaState.selectedActivity!.averageSpeed.toStringAsFixed(1)} km/h',
                          label: 'AVG SPEED',
                          color: CupertinoColors.systemPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.calendar, color: textColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            stravaState.selectedActivity!.formattedDate,
                            style: TextStyle(color: textColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Control buttons
          if (stravaState.isTracking &&
              !stravaState.showSummary &&
              !stravaState.showHistory &&
              stravaState.selectedActivity == null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBackground.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (stravaState.isPaused)
                        ControlButton(
                          icon: CupertinoIcons.play_fill,
                          color: CupertinoColors.systemGreen,
                          onPressed: resumeTracking,
                          label: 'Resume',
                        )
                      else if (stravaState.isTracking && !stravaState.isPaused)
                        ControlButton(
                          icon: CupertinoIcons.pause_fill,
                          color: CupertinoColors.systemYellow,
                          onPressed: pauseTracking,
                          label: 'Pause',
                        ),
                      if (stravaState.isTracking)
                        Container(
                          width: 1,
                          height: 30,
                          color: theme.primaryColor.withOpacity(0.2),
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                      if (stravaState.isTracking)
                        ControlButton(
                          icon: CupertinoIcons.stop_fill,
                          color: CupertinoColors.systemRed,
                          onPressed: stopTracking,
                          label: 'Stop',
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // History View – with enhanced close button
          if (stravaState.showHistory)
            Positioned.fill(
              child: Container(
                color: backgroundColor.withOpacity(0.98),
                child: SafeArea(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Activity History',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.all(10),
                              onPressed: () async {
                                // Ask if user wants to start a new activity
                                final startNew = await showCupertinoDialog<bool>(
                                  context: context,
                                  builder: (context) => CupertinoAlertDialog(
                                    title: const Text('Start New Activity'),
                                    content: const Text('Do you want to start a new activity?'),
                                    actions: [
                                      CupertinoButton(
                                        child: const Text('No'),
                                        onPressed: () => Navigator.pop(context, false),
                                      ),
                                      CupertinoButton(
                                        child: const Text('Yes'),
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                                );
                                if (startNew == true) {
                                  // Start a new activity
                                  resetTracking();
                                } else {
                                  // Just close the history view
                                  toggleHistory();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Icon(CupertinoIcons.clear, color: textColor, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.5),
                              CupertinoColors.systemPurple.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: theme.primaryColor.withOpacity(0.15), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Statistics',
                              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.spaceAround,
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                HistoryStat(
                                  value: stravaState.activityHistory.length.toString(),
                                  label: 'Activities',
                                  color: theme.primaryColor,
                                ),
                                HistoryStat(
                                  value: formatDistance(
                                    stravaState.activityHistory.fold(0.0, (sum, item) => sum + item.distance),
                                  ),
                                  label: 'Total Distance',
                                  color: CupertinoColors.systemGreen,
                                ),
                                HistoryStat(
                                  value: formatTime(
                                    stravaState.activityHistory.fold(0, (sum, item) => sum + item.duration),
                                  ),
                                  label: 'Total Time',
                                  color: CupertinoColors.systemBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: stravaState.activityHistory.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(CupertinoIcons.clock, color: secondaryTextColor, size: 60),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No activities yet',
                                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete your first activity\nto see it here',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: secondaryTextColor, fontSize: 16, height: 1.4),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: stravaState.activityHistory.length,
                          itemBuilder: (context, index) {
                            final activity = stravaState.activityHistory[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: cardBackground.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(18),
                                onPressed: () => viewActivityDetails(activity),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [theme.primaryColor, CupertinoColors.systemPurple],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(CupertinoIcons.map, color: textColor, size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity.formattedDate,
                                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 12,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.arrow_up_bin,
                                                    color: CupertinoColors.systemGreen.withOpacity(0.8),
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    activity.formattedDistance,
                                                    style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.timer,
                                                    color: CupertinoColors.systemBlue.withOpacity(0.8),
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    activity.formattedTime,
                                                    style: TextStyle(color: textColor.withOpacity(0.9), fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemPurple.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: CupertinoColors.systemPurple.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.speedometer,
                                            color: CupertinoColors.systemPurple,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${activity.averageSpeed.toStringAsFixed(1)} km/h',
                                            style: const TextStyle(
                                              color: CupertinoColors.systemPurple,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Summary overlay
          if (stravaState.showSummary)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  ref.read(stravaProvider.notifier).resetTracking();
                  ref.read(stravaProvider.notifier).startTracking();
                },
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: CupertinoColors.black.withOpacity(0.3)),
                ),
              ),
            ),
          if (stravaState.showSummary)
            Positioned(
              left: 20,
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGreen.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: CupertinoColors.systemGreen,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Activity Complete!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Great job! Here\'s your summary',
                            style: TextStyle(fontSize: 14, color: secondaryTextColor),
                          ),
                          const SizedBox(height: 24),
                          SummaryRow(
                            icon: CupertinoIcons.arrow_up_bin,
                            label: 'Total Distance',
                            value: formatDistance(stravaState.totalDistance),
                            color: CupertinoColors.systemGreen,
                          ),
                          const SizedBox(height: 12),
                          SummaryRow(
                            icon: CupertinoIcons.timer,
                            label: 'Total Time',
                            value: formatTime(stravaState.elapsedSeconds),
                            color: CupertinoColors.systemBlue,
                          ),
                          const SizedBox(height: 12),
                          SummaryRow(
                            icon: CupertinoIcons.speedometer,
                            label: 'Average Speed',
                            value: '${stravaState.averageSpeed.toStringAsFixed(1)} km/h',
                            color: CupertinoColors.systemPurple,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(30),
                                  child: const Text('New Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onPressed: resetTracking,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  child: const Text('View History', style: TextStyle(fontWeight: FontWeight.w600)),
                                  onPressed: () => ref.read(stravaProvider.notifier).toggleHistory(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Map controls
          if (stravaState.isTracking &&
              !stravaState.showSummary &&
              !stravaState.showHistory &&
              stravaState.selectedActivity == null)
            Positioned(
              right: 20,
              bottom: 140,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBackground.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      child: Icon(CupertinoIcons.location_fill, color: textColor, size: 24),
                      onPressed: () {
                        if (stravaState.currentRoute.isNotEmpty) {
                          mapController.move(stravaState.currentRoute.last, 16);
                        }
                      },
                    ),
                    Container(height: 1, width: 40, color: theme.primaryColor.withOpacity(0.2)),
                    CupertinoButton(
                      padding: const EdgeInsets.all(16),
                      child: Icon(CupertinoIcons.compass, color: textColor, size: 24),
                      onPressed: () => mapController.rotate(0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}