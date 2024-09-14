import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'package:rts_locator/src/settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final HomeController homeController = Get.put(HomeController(HomeService()));
  final LocationController locationController =
      Get.put(LocationController(LocationService()));
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    locationController.fetchLocation();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('RTS LOCATOR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Get.offAllNamed(SettingsView.routeName);
            },
          ),
        ],
      ),
      body: GetBuilder<HomeController>(
        init: homeController,
        builder: (_) {
          if (homeController.cameraController == null ||
              !homeController.cameraController!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Flexible(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CameraPreview(homeController.cameraController!),
                      Positioned(
                        top: height * 0.0193,
                        right: width * 0.04,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(width: 2.0),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.cameraswitch_outlined,
                                size: 24),
                            onPressed: () async {
                              await homeController.switchCamera();
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            left: width * 0.04,
                            top: height * 0.0193,
                            right: width * 0.04,
                            bottom: height * 0.0193),
                        child: Obx(() {
                          print(homeController.isLoading.value);
                          return homeController.isLoading.value
                              ? Container(
                                  height: height * 0.0844375,
                                  width: width * 0.6,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 2,
                                      style: BorderStyle.solid,
                                      color: const Color(0xffDFDFDF),
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.grey,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(4, 0),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      "CAPTURE",
                                      style: GoogleFonts.inter(
                                        fontSize: height * 0.0193,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () async {
                                    await homeController
                                        .captureAndUpload(
                                            note: noteController.text.trim())
                                        .then((image) {
                                      noteController.text = '';
                                      homeController.isLoading.value = false;
                                    });
                                  },
                                  child: Container(
                                    height: height * 0.0844375,
                                    width: width * 0.6,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        style: BorderStyle.solid,
                                        color: const Color(0xffDFDFDF),
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.black,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(4, 0),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        "CAPTURE",
                                        style: GoogleFonts.inter(
                                          fontSize: height * 0.0193,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                        }),
                      ),
                    ],
                  ),
                ),
                TextFormField(
                  controller: noteController,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: height * 0.0193,
                  ),
                  decoration: InputDecoration(
                    labelText: "Add your note here...",
                    labelStyle: GoogleFonts.inter(
                      fontSize: height * 0.0193,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: height * 0.0120625, horizontal: width * 0.04),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
