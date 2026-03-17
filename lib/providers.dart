import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifier.dart';
import 'models.dart';

final stravaProvider = StateNotifierProvider<StravaNotifier, StravaState>(
  (ref) => StravaNotifier(),
);
