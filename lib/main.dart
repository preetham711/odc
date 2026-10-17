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
import 'services/native_channel_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // 1. Hive (mobile only — uses path_provider)
    await HiveService.init();

    // 2. Notifications (mobile only)
    await NotificationService().init();

    // 3. Lock to portrait on phones (allow landscape on tablets)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 4. Status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  // 5. Firebase (web + mobile)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 6. Firestore offline persistence (mobile only — web uses IndexedDB automatically)
  if (!kIsWeb) {
    await FirestoreService().enableOfflinePersistence();
  }

  // 7. Deep link listener for iOS Siri Shortcuts / URL scheme
  if (!kIsWeb) {
    NativeChannelService().listenForDeepLinks((url) {
      debugPrint('Deep link received: $url');
      // TODO: handle odctracker://checkin, odctracker://checkout, etc.
    });
  }

  runApp(const ProviderScope(child: ODCTrackerApp()));
}

class ODCTrackerApp extends ConsumerWidget {
  const ODCTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'ODC Tracker AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // iOS-style page transitions
      builder: (context, child) {
        return MediaQuery(
          // Respect user's text size preference (iOS Dynamic Type)
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.4),
            ),
          ),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}
