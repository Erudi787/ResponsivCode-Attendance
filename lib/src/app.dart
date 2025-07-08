// lib/src/app.dart

import 'package:flutter/material.dart';
import 'package:rts_locator/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:rts_locator/src/dtr_logs/view/dtr_logs_view.dart';
// --- Add these imports for the new views ---
import 'package:rts_locator/src/facial_recognition/face_recognition_view.dart';
import 'package:rts_locator/src/facial_recognition/live_registration_view.dart';
// --- End of new imports ---
import 'package:rts_locator/src/home/home_view.dart';
import 'package:rts_locator/src/login/login_view.dart';
import 'package:rts_locator/src/splash/splash_view.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,
          getPages: [
            GetPage(
              name: SplashView.routeName,
              page: () => SplashView(),
            ),
            GetPage(
              name: LoginView.routeName,
              page: () => const LoginView(),
            ),
            GetPage(
              name: HomeView.routeName,
              page: () => const HomeView(),
            ),
            GetPage(
                name: DtrLogsView.routeName, page: () => const DtrLogsView()),
            GetPage(
              name: SettingsView.routeName,
              page: () => SettingsView(controller: settingsController),
            ),
            // --- Add the new routes here ---
            GetPage(
              name: LiveRegistrationView.routeName,
              // Use Get.arguments to pass the person's name to the view
              page: () => LiveRegistrationView(personName: Get.arguments as String),
            ),
            GetPage(
              name: FaceRecognitionView.routeName,
              page: () => const FaceRecognitionView(),
            ),
            // -----------------------------
          ],
          initialRoute: SplashView.routeName,
        );
      },
    );
  }
}