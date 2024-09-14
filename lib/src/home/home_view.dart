import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'package:rts_locator/src/settings/settings_view.dart';
import 'dart:math' as math;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final HomeController homeController = Get.put(HomeController(HomeService()));
  final LocationController locationController =
      Get.put(LocationController(LocationService()));
  int _selectedIndex = 0;
  late ValueNotifier<String> attendanceType =
      ValueNotifier<String>("documentary");
  late TabController _tabController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    locationController.fetchLocation();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      _selectedIndex = _tabController.index;
    });
  }

  void _addNoteDialog(BuildContext context) {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return ValueListenableBuilder(
            valueListenable: attendanceType,
            builder: (contex, attendance, _) {
              return AlertDialog(
                content: TextField(
                  minLines: 1, // Starts with 1 line
                  maxLines:
                      null, // Allows the TextField to grow as more lines are inputted
                  controller: noteController,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Note:',
                    labelStyle: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  keyboardType:
                      TextInputType.multiline, // Allows for multiple lines
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      onPressed: () async {
                        // Handle the password verification logic here
                        await homeController
                            .captureAndUpload(
                                note: noteController.text.trim(),
                                attendanceType: attendance)
                            .then((image) {
                          noteController.text = '';
                          homeController.isLoading.value = false;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              );
            });
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    homeController.cameraController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: height,
                  width: width,
                  child: homeController.selectedCameraIndex == 0
                      ? CameraPreview(homeController.cameraController!)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(math.pi),
                          child:
                              CameraPreview(homeController.cameraController!)),
                ),
                if (_selectedIndex == 0)
                  Positioned(
                    top: height * 0.0193,
                    right: width * 0.04,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 2.0),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.cameraswitch_outlined, size: 24),
                        onPressed: () async {
                          await homeController.switchCamera();
                        },
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 180,
                      width: width,
                      color: Colors.transparent,
                      child: Column(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              height: 60,
                              child: TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.center,
                                dividerColor: Colors.transparent,
                                indicatorColor: Colors.red,
                                unselectedLabelColor: Colors.orange,
                                labelColor: Colors.white,
                                controller: _tabController,
                                onTap: (value) async {
                                  await homeController.autoSwitchCamera(
                                      selectedIndex: value);
                                  switch (value) {
                                    case 0:
                                      attendanceType.value = 'documentary';
                                      break;
                                    case 1:
                                      attendanceType.value = 'time_in';
                                      break;
                                    case 2:
                                      attendanceType.value = 'break_out';
                                      break;
                                    case 3:
                                      attendanceType.value = 'break_in';
                                      break;
                                    case 4:
                                      attendanceType.value = 'time_out';
                                      break;
                                  }
                                },
                                tabs: [
                                  Tab(
                                    child: Text(
                                      "DOCUMENTARY",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      "TIME IN",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      "BREAK OUT",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      "BREAK IN",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Tab(
                                    child: Text(
                                      "TIME OUT",
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: GestureDetector(
                              onTap: () async {
                                _addNoteDialog(context);
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 80,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.fiber_manual_record,
                                    color: Colors.white,
                                    size: 95,
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
