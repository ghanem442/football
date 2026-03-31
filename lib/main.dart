import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Status bar icons adapt (light/dark)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark, // iOS hint
    statusBarIconBrightness: Brightness.dark, // Android hint
  ));

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runZonedGuarded(() {
    runApp(
      const ProviderScope(
        child: _BootApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Zoned error: $error');
    debugPrint('$stack');
  });
}

class _BootApp extends ConsumerStatefulWidget {
  const _BootApp();

  @override
  ConsumerState<_BootApp> createState() => _BootAppState();
}

class _BootAppState extends ConsumerState<_BootApp> {
  @override
  Widget build(BuildContext context) {
    // ✅ مفيش boot هنا
    // SplashPage هو اللي هيعمل boot ويحدد AuthStatus
    return const MyApp();
  }
}