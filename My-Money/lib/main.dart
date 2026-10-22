import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Global Exception & Error Traps for Crash Resilience ──
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[MONEY Global Error]: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[MONEY Platform Error]: $error');
    return true; // Prevents app process crash
  };

  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch(e) {
    debugPrint('Firebase skip: $e');
  }

  runApp(const MyMoneyApp());
}

class MyMoneyApp extends StatelessWidget {
  const MyMoneyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
      child: Consumer<AppProvider>(builder: (ctx, p, _) {
        ThemeMode mode;
        switch(p.themeMode) {
          case 'light': mode = ThemeMode.light; break;
          case 'auto': mode = ThemeMode.system; break;
          default: mode = ThemeMode.dark;
        }
        final listTileTheme = const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: AppTheme.textSecondary,
        );
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme.copyWith(listTileTheme: listTileTheme),
          darkTheme: AppTheme.darkTheme.copyWith(listTileTheme: listTileTheme),
          themeMode: mode,
          home: const SplashScreen(),
          scrollBehavior: const MaterialScrollBehavior()
            .copyWith(overscroll: false));
      }));
  }
}
