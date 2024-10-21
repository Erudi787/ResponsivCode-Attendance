import 'dart:convert';

import 'package:camera/camera.dart';
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
  int _selectedIndex = 1;
  late ValueNotifier<String> attendanceType = ValueNotifier<String>("time_in");
  final box = GetStorage();
  late TabController _tabController;
  double longitude = 0.0;
  double latitude = 0.0;
  String plusCode = '';
  String address_complete = '';
  String notes = '';
  bool isResetNeeded = true;
  ValueNotifier<bool> isOverTime = ValueNotifier<bool>(false);
  ValueNotifier<Map<String, String>> tabHeader =
      ValueNotifier<Map<String, String>>({
    'DOCUMENTARY': 'documentary',
    'TIME IN': 'time_in',
    'BREAK OUT': 'break_out',
    'BREAK IN': 'break_in',
    'TIME OUT': 'time_out'
  });
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    update(tabHeader.value.length);
  }

  void update(int length) {
    _tabController = TabController(
        length: length, vsync: this, initialIndex: _selectedIndex);
    _tabController.addListener(() {
      _selectedIndex = _tabController.index;
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
        'AIzaSyCK0P_803SLSiBa663Sw44-njG-ehwPTrg',
      );

      print("Hoy $address");

      setState(() {
        plusCode = address!['plus_code']!;
        address_complete = address['address']!;
        longitude = position.longitude;
        latitude = position.latitude;
      });
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
              data['plus_code']['compound_code'] ?? "Failed to fetch plus_code",
          "address": data['results'][0]['formatted_address'] ??
              "Failed to fetch address"
        };
      } else {
        return {
          "plus_code": 'Failed to fetch plus_code',
          "address": "Failed to fetch address"
        };
      }
    }
    return null;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController.dispose();
    homeController.cameraController!.dispose();
    isOverTime.dispose();
    tabHeader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    print("Hoy ${_tabController.index}");
    return ValueListenableBuilder(
        valueListenable: attendanceType,
        builder: (context, attendance, _) {
          print("Hoy $attendance");
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
                          Get.offAllNamed(SettingsView.routeName);
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
                      if (attendance == "documentary")
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                              filled: true,
                              fillColor: Colors.grey.withOpacity(0.5),
                              border: OutlineInputBorder(
                                // borderRadius: BorderRadius.circular(8),
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
                              child: homeController.selectedCameraIndex == 0
                                  ? CameraPreview(
                                      homeController.cameraController!)
                                  : Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.identity()
                                        ..rotateY(math.pi),
                                      child: CameraPreview(
                                          homeController.cameraController!)),
                            ),
                            if (_tabController.index == 0)
                              Positioned(
                                top: height * 0.0193,
                                right: width * 0.04,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(width: 2.0),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.cameraswitch_outlined,
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
                                      ValueListenableBuilder<
                                              Map<String, String>>(
                                          valueListenable: tabHeader,
                                          builder:
                                              (context, tabHeaderValue, _) {
                                            return Align(
                                              alignment: Alignment.topCenter,
                                              child: SizedBox(
                                                height: 60,
                                                child: TabBar(
                                                  isScrollable: true,
                                                  tabAlignment:
                                                      TabAlignment.center,
                                                  dividerColor:
                                                      Colors.transparent,
                                                  indicatorColor: Colors.red,
                                                  unselectedLabelColor:
                                                      Colors.orange,
                                                  labelColor: Colors.white,
                                                  controller: _tabController,
                                                  onTap: (value) async {
                                                    print("Hoy value: $value");
                                                    await homeController
                                                        .autoSwitchCamera(
                                                            selectedIndex:
                                                                value);
                                                    switch (value) {
                                                      case 0:
                                                        attendanceType.value =
                                                            tabHeaderValue
                                                                .values
                                                                .elementAt(0);
                                                        break;
                                                      case 1:
                                                        attendanceType.value =
                                                            tabHeaderValue
                                                                .values
                                                                .elementAt(1);
                                                        break;
                                                      case 2:
                                                        attendanceType.value =
                                                            tabHeaderValue
                                                                .values
                                                                .elementAt(2);
                                                        break;
                                                      case 3:
                                                        attendanceType.value =
                                                            tabHeaderValue
                                                                .values
                                                                .elementAt(3);
                                                        break;
                                                      case 4:
                                                        attendanceType.value =
                                                            tabHeaderValue
                                                                .values
                                                                .elementAt(4);
                                                        break;
                                                    }
                                                  },
                                                  tabs: [
                                                    Tab(
                                                      child: Text(
                                                        tabHeaderValue.keys
                                                            .elementAt(0),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                    ),
                                                    Tab(
                                                      child: Text(
                                                        tabHeaderValue.keys
                                                            .elementAt(1),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                    ),
                                                    Tab(
                                                      child: Text(
                                                        tabHeaderValue.keys
                                                            .elementAt(2),
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500),
                                                      ),
                                                    ),
                                                    if (tabHeaderValue.length !=
                                                        3)
                                                      Tab(
                                                        child: Text(
                                                          tabHeaderValue.keys
                                                              .elementAt(3),
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                        ),
                                                      ),
                                                    if (tabHeaderValue.length !=
                                                        3)
                                                      Tab(
                                                        child: Text(
                                                          tabHeaderValue.keys
                                                              .elementAt(4),
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                      Padding(
                                        padding:
                                            EdgeInsets.only(top: height * 0.05),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Obx(() {
                                            return homeController
                                                    .isLoading.value
                                                ? Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Container(
                                                        height: 80,
                                                        width: 80,
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      100),
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .fiber_manual_record,
                                                        color: Colors.orange,
                                                        size: 95,
                                                      ),
                                                    ],
                                                  )
                                                : GestureDetector(
                                                    onTap: () async {
                                                      _determinePosition()
                                                          .then((_) async {
                                                        if (attendance ==
                                                            'documentary') {
                                                          if (_formKey
                                                              .currentState!
                                                              .validate()) {
                                                            await homeController
                                                                .captureAndUpload(
                                                              note:
                                                                  noteController
                                                                      .text
                                                                      .trim(),
                                                              attendanceType:
                                                                  attendance,
                                                              latitude:
                                                                  latitude,
                                                              longitude:
                                                                  longitude,
                                                              plusCode:
                                                                  plusCode,
                                                              address_complete:
                                                                  address_complete,
                                                            )
                                                                .then((image) {
                                                              noteController
                                                                  .clear();
                                                              homeController
                                                                      .isLoading
                                                                      .value =
                                                                  false;
                                                            });
                                                          }
                                                        } else {
                                                          await homeController
                                                              .captureAndUpload(
                                                            note: noteController
                                                                .text
                                                                .trim(),
                                                            attendanceType:
                                                                attendance,
                                                            latitude: latitude,
                                                            longitude:
                                                                longitude,
                                                            plusCode: plusCode,
                                                            address_complete:
                                                                address_complete,
                                                          )
                                                              .then((image) {
                                                            noteController
                                                                .clear();
                                                            homeController
                                                                .isLoading
                                                                .value = false;
                                                          });
                                                        }
                                                      });
                                                    },
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        Container(
                                                          height: 80,
                                                          width: 80,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color: Colors
                                                                    .white),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        100),
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons
                                                              .fiber_manual_record,
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
                                            top: height * 0.05,
                                            right: width * 0.03),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () {
                                              isOverTime.value =
                                                  !isOverTime.value;
                                            },
                                            child: Container(
                                              height: 80,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.white),
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child:
                                                  ValueListenableBuilder<bool>(
                                                valueListenable: isOverTime,
                                                builder: (context,
                                                    isOverTimeValue, _) {
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    if (isOverTimeValue) {
                                                      tabHeader.value = {
                                                        'DOCUMENTARY':
                                                            'documentary',
                                                        'OVERTIME IN': 'ot_in',
                                                        // 'OVERTIME BREAK OUT':
                                                        //     'ot_break_out',
                                                        // 'OVERTIME BREAK IN':
                                                        //     'ot_break_in',
                                                        'OVERTIME OUT': 'ot_out'
                                                      };
                                                    } else {
                                                      tabHeader.value = {
                                                        'DOCUMENTARY':
                                                            'documentary',
                                                        'TIME IN': 'time_in',
                                                        'BREAK OUT':
                                                            'break_out',
                                                        'BREAK IN': 'break_in',
                                                        'TIME OUT': 'time_out'
                                                      };
                                                    }

                                                    if (isOverTimeValue &&
                                                        isResetNeeded &&
                                                        _selectedIndex != 1) {
                                                      _selectedIndex = 1;
                                                      isResetNeeded = false;
                                                    }

                                                    if (!isOverTimeValue &&
                                                        !isResetNeeded &&
                                                        _selectedIndex != 1) {
                                                      _selectedIndex = 1;
                                                      isResetNeeded = true;
                                                    }

                                                    update(
                                                        tabHeader.value.length);
                                                  });

                                                  return isOverTimeValue
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
                                                                  color: Colors
                                                                      .orange,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
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
                                                                  color: Colors
                                                                      .orange,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                            ),
                                                          ],
                                                        );
                                                },
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
        });
  }
}
