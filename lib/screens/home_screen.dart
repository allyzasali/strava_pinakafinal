import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Center map on user location
      final mapController = ref.read(mapControllerProvider);
      mapController.move(_currentLocation!, 15);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stravaState = ref.watch(stravaProvider);
    final mapController = ref.watch(mapControllerProvider);
    final brightness = MediaQuery.of(context).platformBrightness;

    ref.listen(stravaProvider, (previous, next) {
      if ((previous?.showSummary ?? false) != next.showSummary) {
        if (next.showSummary) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          // Map
          if (_currentLocation != null)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _currentLocation!,
                initialZoom: 15,
                maxZoom: 19,
                minZoom: 3,
              ),
              children: [
                TileLayer(
                  urlTemplate: brightness == Brightness.dark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                      : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.strava',
                ),

                // Current route (during activity)
                if (stravaState.isTracking && stravaState.currentRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stravaState.currentRoute,
                        color: CupertinoColors.activeOrange,
                        strokeWidth: 6,
                      ),
                    ],
                  ),

                // Completed route (after activity)
                if (!stravaState.isTracking &&
                    stravaState.fullRoute.isNotEmpty &&
                    stravaState.showSummary)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: stravaState.fullRoute,
                        color: const Color(0xFF00B4D8),
                        strokeWidth: 6,
                      ),
                    ],
                  ),

                // Current position marker
                if (stravaState.isTracking && stravaState.currentRoute.isNotEmpty)
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
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.location_fill,
                            color: CupertinoColors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),

                // Start and end markers for completed activity
                if (!stravaState.isTracking &&
                    stravaState.fullRoute.isNotEmpty &&
                    stravaState.showSummary &&
                    stravaState.fullRoute.length > 1)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: stravaState.fullRoute.first,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
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
                      Marker(
                        point: stravaState.fullRoute.last,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: brightness == Brightness.dark ? Colors.white : Colors.black,
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

          // Loading indicator
          if (_currentLocation == null)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Header
          if (!stravaState.showSummary && !stravaState.showHistory)
            _buildHeader(brightness, stravaState),

          // Stats Card
          if (stravaState.isTracking && !stravaState.showSummary && !stravaState.showHistory)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: StatsCard(
                distance: stravaState.totalDistance,
                time: stravaState.elapsedSeconds,
                averageSpeed: stravaState.averageSpeed,
                isPaused: stravaState.isPaused,
                brightness: brightness,
              ),
            ),

          // Control Buttons
          if (stravaState.isTracking && !stravaState.showSummary && !stravaState.showHistory)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ControlButtons(
                  isPaused: stravaState.isPaused,
                  isTracking: stravaState.isTracking,
                  onPause: () => ref.read(stravaProvider.notifier).pauseTracking(),
                  onResume: () => ref.read(stravaProvider.notifier).resumeTracking(),
                  onStop: () => ref.read(stravaProvider.notifier).stopTracking(),
                ),
              ),
            ),

          // Start Button
          if (!stravaState.isTracking && !stravaState.showSummary && !stravaState.showHistory)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  color: CupertinoColors.activeOrange,
                  borderRadius: BorderRadius.circular(30),
                  onPressed: () {
                    ref.read(stravaProvider.notifier).startTracking();
                  },
                  child: const Text(
                    'Start Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),

          // Summary Overlay
          if (stravaState.showSummary)
            _buildSummaryOverlay(stravaState, brightness),

          // Map Controls
          if (!stravaState.showSummary && !stravaState.showHistory)
            _buildMapControls(stravaState, brightness, mapController),
        ],
      ),
    );
  }

  Widget _buildHeader(Brightness brightness, StravaState state) {
    return Positioned(
      top: 10,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Strava',
            style: TextStyle(
              color: brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(10),
            color: brightness == Brightness.dark
                ? Colors.black.withOpacity(0.5)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  color: brightness == Brightness.dark ? Colors.white : Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  'History',
                  style: TextStyle(
                    color: brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            onPressed: () {
              ref.read(stravaProvider.notifier).toggleHistory();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryOverlay(StravaState state, Brightness brightness) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          ref.read(stravaProvider.notifier).resetTracking();
        },
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: brightness == Brightness.dark
                            ? [const Color(0xFF2A2F4F), const Color(0xFF4A3F6E)]
                            : [const Color(0xFFE8F0FF), const Color(0xFFD4E0FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemGreen,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Activity Complete!',
                          style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Great job! Here\'s your summary',
                          style: TextStyle(
                            color: brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Mini map preview
                        if (state.fullRoute.isNotEmpty)
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              color: brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: CustomPaint(
                                painter: RoutePreviewPainter(
                                  route: state.fullRoute,
                                  isDark: brightness == Brightness.dark,
                                ),
                                size: const Size(double.infinity, 150),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Stats
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: brightness == Brightness.dark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                'Total Distance',
                                _formatDistance(state.totalDistance),
                                CupertinoColors.systemGreen,
                                brightness,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Total Time',
                                _formatTime(state.elapsedSeconds),
                                CupertinoColors.systemBlue,
                                brightness,
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Average Speed',
                                '${state.averageSpeed.toStringAsFixed(1)} km/h',
                                CupertinoColors.systemPurple,
                                brightness,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          color: CupertinoColors.activeOrange,
                          borderRadius: BorderRadius.circular(30),
                          onPressed: () {
                            ref.read(stravaProvider.notifier).resetTracking();
                          },
                          child: const Text(
                            'New Activity',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: brightness == Brightness.dark ? Colors.white70 : Colors.black87,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMapControls(StravaState state, Brightness brightness, MapController mapController) {
    return Positioned(
      right: 20,
      bottom: 140,
      child: Container(
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? Colors.black.withOpacity(0.8)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: brightness == Brightness.dark ? Colors.white24 : Colors.black12,
          ),
        ),
        child: Column(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              child: Icon(
                CupertinoIcons.location_fill,
                color: brightness == Brightness.dark ? Colors.white : Colors.black,
                size: 24,
              ),
              onPressed: () async {
                Position position = await Geolocator.getCurrentPosition();
                mapController.move(LatLng(position.latitude, position.longitude), 16);
              },
            ),
            Container(
              height: 1,
              width: 40,
              color: brightness == Brightness.dark ? Colors.white24 : Colors.black12,
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(16),
              child: Icon(
                CupertinoIcons.compass,
                color: brightness == Brightness.dark ? Colors.white : Colors.black,
                size: 24,
              ),
              onPressed: () {
                mapController.rotate(0);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, "0")}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}";
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return "${(meters / 1000).toStringAsFixed(2)} km";
    }
    return "${meters.toStringAsFixed(0)} m";
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class RoutePreviewPainter extends CustomPainter {
  final List<LatLng> route;
  final bool isDark;

  RoutePreviewPainter({required this.route, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (route.isEmpty) return;

    final paint = Paint()
      ..color = CupertinoColors.activeOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Calculate bounds
    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (var p in route) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }

    // Add padding
    double latPadding = (maxLat - minLat) * 0.1;
    double lngPadding = (maxLng - minLng) * 0.1;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    double latRange = maxLat - minLat;
    double lngRange = maxLng - minLng;

    ui.Path path = ui.Path();

    for (int i = 0; i < route.length; i++) {
      double x = ((route[i].longitude - minLng) / lngRange) * size.width;
      double y = ((route[i].latitude - minLat) / latRange) * size.height;
      y = size.height - y;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}