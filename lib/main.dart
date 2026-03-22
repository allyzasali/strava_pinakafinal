import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const ProviderScope(child: StravaApp()));
}

class StravaApp extends ConsumerWidget {
  const StravaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoApp(
      title: 'Strava',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeOrange,
      ),
      home: const LandingScreen(),
    );
  }
}