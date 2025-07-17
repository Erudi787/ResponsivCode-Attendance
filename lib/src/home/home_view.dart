// lib/src/home/home_view.dart

import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rts_locator/src/home/home_controller.dart';
import 'package:rts_locator/src/home/home_service.dart';
import 'package:rts_locator/src/location/location_controller.dart';
import 'package:rts_locator/src/location/location_service.dart';
import 'package:rts_locator/src/settings/settings_view.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final HomeController homeController = Get.put(HomeController(HomeService()));
  final LocationController locationController =
      Get.put(LocationController(LocationService()));
  final TextEditingController noteController = TextEditingController();
  final box = GetStorage();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  late TabController _tabController;
  String attendanceType = "time_in";
  String tabHeaderKey = 'TIME IN';

  double longitude = 0.0;
  double latitude = 0.0;
  String plusCode = '';
  String address_complete = '';
  String notes = '';
  bool isOverTime = false;

  // Define the tab headers
  final Map<String, String> regularTabs = {
    'DOCUMENTARY': 'documentary',
    'TIME IN': 'time_in',
    'BREAK OUT': 'break_out',
    'BREAK IN': 'break_in',
    'TIME OUT': 'time_out'
  };

  final Map<String, String> overtimeTabs = {
    'DOCUMENTARY': 'documentary',
    'OVERTIME IN': 'ot_in',
    'OVERTIME OUT': 'ot_out'
  };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // --- FIX: Simplified and safer lifecycle handling ---
    if (state == AppLifecycleState.paused) {
      homeController.disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      // If the controller is null, it means it was disposed when paused.
      if (homeController.cameraController == null) {
        homeController.initializeCamera();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    homeController.checkAttendanceStatus();
    // Initialize TabController with regular tabs
    _tabController =
        TabController(length: regularTabs.length, vsync: this, initialIndex: 1);
    _tabController.addListener(_handleTabSelection);
    device();
  }

  void _handleTabSelection() {
    // only update state if the index has changed
    if (_tabController.indexIsChanging) {
      setState(() {
        final currentTabs = isOverTime ? overtimeTabs : regularTabs;
        attendanceType = currentTabs.values.elementAt(_tabController.index);
        tabHeaderKey = currentTabs.keys.elementAt(_tabController.index);
      });
    }
  }

  void device() async {
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    print('Hello ${androidDeviceInfo.model}');
  }

  // A single function to switch between overtime and regular modes
  void _toggleOvertime() {
    setState(() {
      isOverTime = !isOverTime;
      // Remove the old listener to avoid errors
      _tabController.removeListener(_handleTabSelection);

      // Create a new TabController with the correct length and initial index
      final newTabs = isOverTime ? overtimeTabs : regularTabs;
      _tabController =
          TabController(length: newTabs.length, vsync: this, initialIndex: 1);

      // Set the default attendance type for the new mode
      attendanceType = newTabs.values.elementAt(1);
      tabHeaderKey = newTabs.keys.elementAt(1);

      // Add the listener to the new controller
      _tabController.addListener(_handleTabSelection);
    });
  }

  Future<void> _determinePosition() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location Permission is denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              "Location permissions are permanently denied, we cannot request permissions.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    );

    // Use Google Maps Geocoding API
    try {
      final address = await _getAddressFromLatLng(
        position.latitude,
        position.longitude,
        'AIzaSyCK0P_803SLSiBa663Sw44-njG-ehwPTrg', // Replace with your API key
      );

      if (mounted) {
        setState(() {
          plusCode = address?['plus_code'] ?? 'Failed to fetch plus_code';
          address_complete = address?['address'] ?? 'Failed to fetch address';
          longitude = position.longitude;
          latitude = position.latitude;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<Map<String, String>?> _getAddressFromLatLng(
      double lat, double lng, String apiKey) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK' && data['results'][0] != null) {
        return {
          "plus_code":
              data['results'][0]['plus_code']?['compound_code'] ?? "N/A",
          "address": data['results'][0]['formatted_address'] ?? "N/A"
        };
      }
    }
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    homeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    final currentTabs = isOverTime ? overtimeTabs : regularTabs;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 150,
                    child: Center(
                      child: Text(
                        '${box.read('fullname')}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  "RTS HR",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    size: 26,
                  ),
                  onPressed: () {
                    Get.toNamed(SettingsView.routeName);
                  },
                ),
              )
            ],
          ),
        ),
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
                if (attendanceType == "documentary")
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      minLines: 1,
                      maxLines: null,
                      controller: noteController,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        labelText: "Add your note here...",
                        labelStyle: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some text';
                        }
                        return null;
                      },
                    ),
                  ),
                Flexible(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: height,
                        width: width,
                        child: CameraPreview(homeController.cameraController!),
                      ),
                      if (_tabController.index == 0)
                        Positioned(
                          top: height * 0.0193,
                          right: width * 0.04,
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(width: 2.0, color: Colors.white),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              color: Colors.white,
                              icon: const Icon(Icons.cameraswitch_outlined,
                                  size: 24),
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
                            child: Stack(
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
                                      tabs: currentTabs.keys
                                          .map((String key) => Tab(
                                                child: Text(
                                                  key,
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: height * 0.05),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Obx(() {
                                      return homeController.isLoading.value
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  height: 80,
                                                  width: 80,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors.white),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.fiber_manual_record,
                                                  color: Colors.orange,
                                                  size: 95,
                                                ),
                                              ],
                                            )
                                          : GestureDetector(
                                              onTap: () async {
                                                final isEnabled = homeController
                                                        .tabAvailability[
                                                            attendanceType]
                                                        ?.value ??
                                                    false;

                                                if (!isEnabled) {
                                                  if (attendanceType ==
                                                          'ot_in' ||
                                                      attendanceType ==
                                                          'ot_out') {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "You must time out first before logging overtime.",
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                  } else {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          "You have already completed this action for today.",
                                                      gravity:
                                                          ToastGravity.CENTER,
                                                    );
                                                  }
                                                  return;
                                                }

                                                await _determinePosition();

                                                if (plusCode.isEmpty ||
                                                    address_complete.isEmpty) {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          "Could not get location. Please try again.");
                                                  return;
                                                }

                                                if (attendanceType ==
                                                    'documentary') {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    await homeController
                                                        .captureAndUpload(
                                                      note: noteController.text
                                                          .trim(),
                                                      attendanceType:
                                                          attendanceType,
                                                      latitude: latitude,
                                                      longitude: longitude,
                                                      plusCode: plusCode,
                                                      tabHeader: tabHeaderKey,
                                                      address_complete:
                                                          address_complete,
                                                    );
                                                    noteController.clear();
                                                  }
                                                } else {
                                                  await homeController
                                                      .captureAndUpload(
                                                    note: noteController.text
                                                        .trim(),
                                                    attendanceType:
                                                        attendanceType,
                                                    latitude: latitude,
                                                    longitude: longitude,
                                                    plusCode: plusCode,
                                                    tabHeader: tabHeaderKey,
                                                    address_complete:
                                                        address_complete,
                                                  );
                                                  noteController.clear();
                                                }
                                              },
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Container(
                                                    height: 80,
                                                    width: 80,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.fiber_manual_record,
                                                    color: Colors.white,
                                                    size: 95,
                                                  ),
                                                ],
                                              ),
                                            );
                                    }),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      top: height * 0.05, right: width * 0.03),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: _toggleOvertime,
                                      child: Container(
                                        height: 80,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: Colors.white),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: isOverTime
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/clock.png',
                                                    width: 40,
                                                    height: 40,
                                                  ),
                                                  Text(
                                                    "NO OVERTIME",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/overtime.png',
                                                    width: 40,
                                                    height: 40,
                                                  ),
                                                  Text(
                                                    "OVERTIME",
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 13,
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
