import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/hive_service.dart';
import 'notifications/notification_service.dart';
import 'providers/theme_provider.dart';
import 'services/firestore_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Hive uses path_provider — not available on web
    await HiveService.init();

    // flutter_local_notifications is mobile-only
    await NotificationService().init();
  }

  // Firebase works on web and mobile
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    // Firestore offline persistence — web handles this via IndexedDB automatically
    await FirestoreService().enableOfflinePersistence();

    // Status-bar tint — mobile only
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(const ProviderScope(child: ODCTrackerApp()));
}

class ODCTrackerApp extends ConsumerWidget {
  const ODCTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // themeProvider reads Hive; on web Hive isn't init'd so it safely falls
    // back to ThemeMode.system via the try/catch inside ThemeNotifier.
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'ODC Tracker AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const SplashScreen(),
    );
  }
}
