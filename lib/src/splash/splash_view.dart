import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:rts_locator/src/splash/splash_controller.dart';
import 'package:rts_locator/src/splash/splash_service.dart';

class SplashView extends StatelessWidget {
  SplashView({super.key});

  final SplashController _splashController =
      Get.put(SplashController(SplashService()));

  static const routeName = '/splash';

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SizedBox(
        height: height,
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/background/rts_logo.png',
              width: 100,
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                'RTS LOCATOR',
                style: GoogleFonts.zenDots(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: LinearPercentIndicator(
                alignment: MainAxisAlignment.center,
                animation: true,
                animationDuration: 2000,
                lineHeight: height * 0.005,
                width: width * 0.51,
                percent: 1,
                linearGradient: const LinearGradient(
                  colors: [Color(0xFFCC0F2B), Color(0xFFF9A620)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                backgroundColor: Colors.grey,
                onAnimationEnd: () {
                  _splashController.checkToken();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
