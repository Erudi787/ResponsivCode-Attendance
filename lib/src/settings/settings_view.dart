import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/home/home_view.dart';

import 'settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          onPressed: () => Get.offAllNamed(HomeView.routeName),
        ),
      ),
      body: SizedBox(
        height: height - height * 0.120625,
        width: width,
        child: Padding(
          padding: EdgeInsets.only(
              left: width * 0.06,
              top: height * 0.05669375,
              right: width * 0.06,
              bottom: height * 0.05669375),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<ThemeMode>(
                  // Read the selected themeMode from the controller
                  value: controller.themeMode,
                  // Call the updateThemeMode method any time the user selects a theme.
                  onChanged: controller.updateThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    )
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await controller.logout();
                },
                child: Container(
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCC0F2B), Color(0xFFF9A620)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: width * 0.355,
                        top: height * 0.01809375,
                        right: width * 0.355,
                        bottom: height * 0.01809375),
                    child: Text(
                      "LOGOUT",
                      style: GoogleFonts.poppins(
                          fontSize: height * 0.0193,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                          color: Colors.white),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
