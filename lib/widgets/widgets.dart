import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;

// Stats Card Widget
class StatsCard extends StatelessWidget {
  final double distance;
  final int time;
  final double averageSpeed;
  final bool isPaused;
  final Brightness brightness;

  const StatsCard({
    super.key,
    required this.distance,
    required this.time,
    required this.averageSpeed,
    required this.isPaused,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brightness == Brightness.dark
              ? [Colors.black.withOpacity(0.85), Colors.grey.withOpacity(0.85)]
              : [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: brightness == Brightness.dark
              ? Colors.white24
              : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPaused)
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
                  Text('PAUSED', style: TextStyle(color: CupertinoColors.systemYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                _formatDistance(distance),
                'DISTANCE',
                CupertinoColors.systemGreen,
                CupertinoIcons.arrow_up_bin,
                brightness,
              ),
              _buildStatItem(
                _formatTime(time),
                'TIME',
                CupertinoColors.systemBlue,
                CupertinoIcons.timer,
                brightness,
              ),
              _buildStatItem(
                '${averageSpeed.toStringAsFixed(1)} km/h',
                'AVG SPEED',
                CupertinoColors.systemPurple,
                CupertinoIcons.speedometer,
                brightness,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color, IconData icon, Brightness brightness) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: brightness == Brightness.dark
                ? Colors.white60
                : Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
}

// Control Buttons Widget
class ControlButtons extends StatelessWidget {
  final bool isPaused;
  final bool isTracking;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const ControlButtons({
    super.key,
    required this.isPaused,
    required this.isTracking,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: brightness == Brightness.dark ? Colors.white24 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPaused)
            _buildButton(
              icon: CupertinoIcons.play_fill,
              color: CupertinoColors.systemGreen,
              label: 'Resume',
              onPressed: onResume,
            )
          else
            _buildButton(
              icon: CupertinoIcons.pause_fill,
              color: CupertinoColors.systemYellow,
              label: 'Pause',
              onPressed: onPause,
            ),
          const SizedBox(width: 15),
          _buildButton(
            icon: CupertinoIcons.stop_fill,
            color: CupertinoColors.systemRed,
            label: 'Stop',
            onPressed: onStop,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onPressed: onPressed,
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}