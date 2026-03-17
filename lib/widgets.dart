import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';
import 'dart:ui' as ui;

class LiveStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const LiveStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class DetailStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const DetailStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class HistoryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const HistoryStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final String label;

  const ControlButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const SummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.9),
              fontSize: 16,
            ),
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
}

class RoutePainter extends CustomPainter {
  final List<LatLng> route;

  RoutePainter(this.route);

  @override
  void paint(Canvas canvas, Size size) {
    if (route.isEmpty) return;

    final paint = Paint()
      ..color = CupertinoColors.activeOrange
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Find bounds with padding
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

    // Add 10% padding
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

    // Draw start marker
    Paint startPaint = Paint()
      ..color = CupertinoColors.systemGreen
      ..style = PaintingStyle.fill;

    double startX = ((route.first.longitude - minLng) / lngRange) * size.width;
    double startY =
        size.height -
        ((route.first.latitude - minLat) / latRange) * size.height;
    canvas.drawCircle(Offset(startX, startY), 6, startPaint);

    // Draw white border for start marker
    Paint startBorder = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(startX, startY), 6, startBorder);

    // Draw end marker
    Paint endPaint = Paint()
      ..color = CupertinoColors.systemRed
      ..style = PaintingStyle.fill;

    double endX = ((route.last.longitude - minLng) / lngRange) * size.width;
    double endY =
        size.height - ((route.last.latitude - minLat) / latRange) * size.height;
    canvas.drawCircle(Offset(endX, endY), 6, endPaint);

    // Draw white border for end marker
    Paint endBorder = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(endX, endY), 6, endBorder);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
