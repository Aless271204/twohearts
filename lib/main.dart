import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import './services/app_language.dart';
import 'package:sizer/sizer.dart';

import './core/app_export.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import './widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLanguage.instance.initialize();
  bool initialized = false;
  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    initialized = true;
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Audio loads on demand, so network audio never blocks app startup.

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  GoRouter.optionURLReflectsImperativeAPIs = true;

  // 🚨 CRITICAL: Device orientation lock - only on mobile, not web
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(initialized ? const MyApp() : MaterialApp(home: Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('No pudimos abrir NIDO. Inténtalo nuevamente.'), const SizedBox(height: 16), FilledButton(onPressed: main, child: const Text('Reintentar'))])))));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return ListenableBuilder(listenable: AppLanguage.instance, builder: (context, _) => MaterialApp.router(
          locale: AppLanguage.instance.locale,
          supportedLocales: const [Locale("es"),Locale("en"),Locale("pt")],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          title: 'twohearts',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        ));
      },
    );
  }
}
