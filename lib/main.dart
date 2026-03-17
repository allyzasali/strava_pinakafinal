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

class StravaApp extends ConsumerStatefulWidget {
  const StravaApp({super.key});

  @override
  ConsumerState<StravaApp> createState() => _StravaAppState();
}

class _StravaAppState extends ConsumerState<StravaApp>
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
    _checkPermissionsAndStart();
  }

  Future<void> _checkPermissionsAndStart() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showPermissionDeniedDialog();
    } else {
      ref.read(stravaProvider.notifier).startTracking();
    }
  }

  void _showPermissionDeniedDialog() {
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

  void pauseTracking() {
    ref.read(stravaProvider.notifier).pauseTracking();
  }

  void resumeTracking() {
    ref.read(stravaProvider.notifier).resumeTracking();
  }

  void stopTracking() {
    ref.read(stravaProvider.notifier).stopTracking();
  }

  void resetTracking() {
    ref.read(stravaProvider.notifier).resetTracking();
    ref.read(stravaProvider.notifier).startTracking();
  }

  void toggleHistory() {
    ref.read(stravaProvider.notifier).toggleHistory();
  }

  void viewActivityDetails(ActivityResult activity) {
    ref.read(stravaProvider.notifier).viewActivityDetails(activity);
  }

  void backToHistory() {
    ref.read(stravaProvider.notifier).backToHistory();
  }

  @override
  Widget build(BuildContext context) {
    final stravaState = ref.watch(stravaProvider);

    ref.listen(stravaProvider, (previous, next) {
      if ((previous?.showSummary ?? false) != next.showSummary) {
        if (next.showSummary) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeOrange,
      ),
      home: CupertinoPageScaffold(
        child: Stack(
          children: [
            // Map - always show the map
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(0, 0),
                initialZoom: 15,
                maxZoom: 19,
                minZoom: 3,
                // interactiveFlags removed – not supported in flutter_map 8.2.2
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.strava',
                ),

                // Show current route (active tracking)
                if (stravaState.isTracking &&
                    stravaState.currentRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stravaState.currentRoute,
                        color: CupertinoColors.activeOrange,
                        strokeWidth: 5,
                      ),
                    ],
                  ),

                // Show completed route after stopping (until new activity starts)
                if (!stravaState.isTracking &&
                    stravaState.fullRoute.isNotEmpty &&
                    stravaState.showSummary)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stravaState.fullRoute,
                        color: const Color(0xFF00B4D8), // Vibrant cyan
                        strokeWidth: 5,
                      ),
                    ],
                  ),

                // Show selected activity route
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

                // Current position marker
                if (stravaState.isTracking &&
                    stravaState.currentRoute.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: stravaState.currentRoute.last,
                        width: 50,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeOrange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/icon.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // Show start and end markers for selected activity
                if (stravaState.selectedActivity != null &&
                    stravaState.selectedActivity!.route.length > 1)
                  MarkerLayer(
                    markers: [
                      // Start marker
                      Marker(
                        point: stravaState.selectedActivity!.route.first,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.flag_fill,
                            color: CupertinoColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // End marker
                      Marker(
                        point: stravaState.selectedActivity!.route.last,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 2,
                            ),
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

            // Header with History button (when not in summary/history/activity detail)
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
                    const Text(
                      'Strava',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(10),
                      color: CupertinoColors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'History',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
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
                      color: CupertinoColors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.back,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ],
                      ),
                      onPressed: backToHistory,
                    ),
                    Text(
                      'Activity Details',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 70), // Placeholder for balance
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        CupertinoColors.black.withOpacity(0.85),
                        CupertinoColors.systemGrey.withOpacity(0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: CupertinoColors.white.withOpacity(0.2),
                      width: 1,
                    ),
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
                      // Pause indicator
                      if (stravaState.isPaused)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemYellow.withOpacity(
                              0.2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: CupertinoColors.systemYellow,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.pause_circle_fill,
                                color: CupertinoColors.systemYellow,
                                size: 16,
                              ),
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
                            value:
                                '${stravaState.averageSpeed.toStringAsFixed(1)} km/h',
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
                    color: CupertinoColors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: CupertinoColors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          DetailStat(
                            value: formatDistance(
                              stravaState.selectedActivity!.distance,
                            ),
                            label: 'DISTANCE',
                            color: CupertinoColors.systemGreen,
                          ),
                          DetailStat(
                            value: stravaState.selectedActivity!.formattedTime,
                            label: 'TIME',
                            color: CupertinoColors.systemBlue,
                          ),
                          DetailStat(
                            value:
                                '${stravaState.selectedActivity!.averageSpeed.toStringAsFixed(1)} km/h',
                            label: 'AVG SPEED',
                            color: CupertinoColors.systemPurple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.calendar,
                              color: CupertinoColors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stravaState.selectedActivity!.formattedDate,
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
                              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: CupertinoColors.white.withOpacity(0.2),
                        width: 1,
                      ),
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
                        else if (stravaState.isTracking &&
                            !stravaState.isPaused)
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
                            color: CupertinoColors.white.withOpacity(0.2),
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

            // ========== ENHANCED HISTORY VIEW ==========
            if (stravaState.showHistory)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.black.withOpacity(0.98),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // History Header with close button
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Activity History',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.all(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.clear,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: toggleHistory,
                              ),
                            ],
                          ),
                        ),

                        // Stats Summary – more vibrant
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CupertinoColors.activeOrange.withOpacity(0.5),
                                CupertinoColors.systemPurple.withOpacity(0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: CupertinoColors.white.withOpacity(0.15),
                              width: 1,
                            ),
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
                              const Text(
                                'Total Statistics',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  HistoryStat(
                                    value: stravaState.activityHistory.length
                                        .toString(),
                                    label: 'Activities',
                                    color: CupertinoColors.activeOrange,
                                  ),
                                  HistoryStat(
                                    value: formatDistance(
                                      stravaState.activityHistory.fold(
                                        0.0,
                                        (sum, item) => sum + item.distance,
                                      ),
                                    ),
                                    label: 'Total Distance',
                                    color: CupertinoColors.systemGreen,
                                  ),
                                  HistoryStat(
                                    value: formatTime(
                                      stravaState.activityHistory.fold(
                                        0,
                                        (sum, item) => sum + item.duration,
                                      ),
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

                        // History List
                        Expanded(
                          child: stravaState.activityHistory.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGrey
                                              .withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.clock,
                                          color: CupertinoColors.systemGrey,
                                          size: 60,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'No activities yet',
                                        style: TextStyle(
                                          color: CupertinoColors.white
                                              .withOpacity(0.9),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Complete your first activity\nto see it here',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: CupertinoColors.white
                                              .withOpacity(0.5),
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: stravaState.activityHistory.length,
                                  itemBuilder: (context, index) {
                                    final activity =
                                        stravaState.activityHistory[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemGrey
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: CupertinoColors.white
                                              .withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: CupertinoColors.black
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(18),
                                        onPressed: () =>
                                            viewActivityDetails(activity),
                                        child: Row(
                                          children: [
                                            // Left icon with gradient background
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    CupertinoColors
                                                        .activeOrange,
                                                    CupertinoColors
                                                        .systemPurple,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                              child: const Icon(
                                                CupertinoIcons.map,
                                                color: CupertinoColors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Middle column – date, distance, time
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    activity.formattedDate,
                                                    style: const TextStyle(
                                                      color:
                                                          CupertinoColors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        CupertinoIcons
                                                            .arrow_up_bin,
                                                        color: CupertinoColors
                                                            .systemGreen
                                                            .withOpacity(0.8),
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        activity
                                                            .formattedDistance,
                                                        style: TextStyle(
                                                          color: CupertinoColors
                                                              .white
                                                              .withOpacity(0.9),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Icon(
                                                        CupertinoIcons.timer,
                                                        color: CupertinoColors
                                                            .systemBlue
                                                            .withOpacity(0.8),
                                                        size: 14,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        activity.formattedTime,
                                                        style: TextStyle(
                                                          color: CupertinoColors
                                                              .white
                                                              .withOpacity(0.9),
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Right speed badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors
                                                    .systemPurple
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                border: Border.all(
                                                  color: CupertinoColors
                                                      .systemPurple
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons.speedometer,
                                                    color: CupertinoColors
                                                        .systemPurple,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '${activity.averageSpeed.toStringAsFixed(1)} km/h',
                                                    style: const TextStyle(
                                                      color: CupertinoColors
                                                          .systemPurple,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                    child: Container(
                      color: CupertinoColors.black.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

            if (stravaState.showSummary)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A2F4F), // Deep indigo
                            const Color(0xFF4A3F6E), // Rich purple
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: CupertinoColors.white.withOpacity(0.15),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF917FB3).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.systemGreen,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Activity Complete!',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Great job! Here\'s your summary',
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Mini map preview
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: CupertinoColors.white.withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CustomPaint(
                                painter: RoutePainter(stravaState.fullRoute),
                                size: const Size(300, 180),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Summary stats
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey.withOpacity(
                                0.15,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: CupertinoColors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                SummaryRow(
                                  icon: CupertinoIcons.arrow_up_bin,
                                  label: 'Total Distance',
                                  value: formatDistance(
                                    stravaState.totalDistance,
                                  ),
                                  color: CupertinoColors.systemGreen,
                                ),
                                const SizedBox(height: 16),
                                SummaryRow(
                                  icon: CupertinoIcons.timer,
                                  label: 'Total Time',
                                  value: formatTime(stravaState.elapsedSeconds),
                                  color: CupertinoColors.systemBlue,
                                ),
                                const SizedBox(height: 16),
                                SummaryRow(
                                  icon: CupertinoIcons.speedometer,
                                  label: 'Average Speed',
                                  value:
                                      '${stravaState.averageSpeed.toStringAsFixed(1)} km/h',
                                  color: CupertinoColors.systemPurple,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  color: CupertinoColors.activeOrange,
                                  borderRadius: BorderRadius.circular(30),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_clockwise,
                                        color: CupertinoColors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'New Activity',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: resetTracking,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  color: CupertinoColors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.clock,
                                        color: CupertinoColors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'View History',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(stravaProvider.notifier)
                                        .toggleHistory();
                                  },
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
                    color: CupertinoColors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: CupertinoColors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          CupertinoIcons.location_fill,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          if (stravaState.currentRoute.isNotEmpty) {
                            mapController.move(
                              stravaState.currentRoute.last,
                              16,
                            );
                          }
                        },
                      ),
                      Container(
                        height: 1,
                        width: 40,
                        color: CupertinoColors.white.withOpacity(0.2),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          CupertinoIcons.compass,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // Reset map rotation to north (0 degrees)
                          mapController.rotate(0);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
