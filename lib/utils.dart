String formatTime(int seconds) {
  int h = seconds ~/ 3600;
  int m = (seconds % 3600) ~/ 60;
  int s = seconds % 60;
  return "${h.toString().padLeft(2, "0")}:${m.toString().padLeft(2, "0")}:${s.toString().padLeft(2, "0")}";
}

String formatDistance(double meters) {
  if (meters >= 1000) {
    return "${(meters / 1000).toStringAsFixed(2)} km";
  }
  return "${meters.toStringAsFixed(0)} m";
}
