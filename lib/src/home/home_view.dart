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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final HomeController homeController = Get.put(HomeController(HomeService()));
  final LocationController locationController =
      Get.put(LocationController(LocationService()));
  final TextEditingController noteController = TextEditingController();
  int _selectedIndex = 0;
  late ValueNotifier<String> attendanceType =
      ValueNotifier<String>("documentary");
  final box = GetStorage();
  late TabController _tabController;
  double longitude = 0.0;
  double latitude = 0.0;
  String plusCode = '';
  String address_complete = '';
  String notes = '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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

  // void _addNoteDialog(BuildContext context) {
  //   final TextEditingController noteController = TextEditingController();

  //   showDialog(
  //     // barrierDismissible: false,
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: Colors.white,
  //         content: TextField(
  //           minLines: 1, // Starts with 1 line
  //           maxLines:
  //               null, // Allows the TextField to grow as more lines are inputted
  //           controller: noteController,
  //           style: GoogleFonts.poppins(
  //               fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
  //           decoration: InputDecoration(
  //             focusColor: Colors.black,
  //             fillColor: Colors.black,
  //             hoverColor: Colors.black,
  //             labelText: 'Note:',
  //             labelStyle: GoogleFonts.poppins(
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.w500,
  //                 color: Colors.black),
  //           ),
  //           keyboardType: TextInputType.multiline, // Allows for multiple lines
  //         ),
  //         actions: [
  //           Center(
  //             child: GestureDetector(
  //               child: Container(
  //                 height: 50,
  //                 width: 100,
  //                 decoration: BoxDecoration(
  //                     color: Colors.black,
  //                     borderRadius: BorderRadius.all(Radius.circular(20))),
  //                 child: Center(
  //                   child: Text(
  //                     'Confirm',
  //                     style: GoogleFonts.poppins(
  //                         fontSize: 16,
  //                         fontWeight: FontWeight.w500,
  //                         color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //               onTap: () async {
  //                 // Handle the password verification logic here

  //                 setState(() {
  //                   notes = noteController.text.trim();
  //                 });

  //                 noteController.text = '';

  //                 Navigator.of(context).pop();
  //               },
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
    return ValueListenableBuilder(
        valueListenable: attendanceType,
        builder: (context, attendance, _) {
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
                                              await homeController
                                                  .autoSwitchCamera(
                                                      selectedIndex: value);
                                              switch (value) {
                                                case 0:
                                                  attendanceType.value =
                                                      'documentary';
                                                  break;
                                                case 1:
                                                  attendanceType.value =
                                                      'time_in';
                                                  break;
                                                case 2:
                                                  attendanceType.value =
                                                      'break_out';
                                                  break;
                                                case 3:
                                                  attendanceType.value =
                                                      'break_in';
                                                  break;
                                                case 4:
                                                  attendanceType.value =
                                                      'time_out';
                                                  break;
                                              }
                                            },
                                            tabs: [
                                              Tab(
                                                child: Text(
                                                  "DOCUMENTARY",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  "TIME IN",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  "BREAK OUT",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  "BREAK IN",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  "TIME OUT",
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                      Align(
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
                                                            color:
                                                                Colors.white),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(100),
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
                                                    _determinePosition()
                                                        .then((_) async {
                                                      if (attendance ==
                                                          'documentary') {
                                                        if (_formKey
                                                            .currentState!
                                                            .validate()) {
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
                                                      } else {
                                                        await homeController
                                                            .captureAndUpload(
                                                          note: noteController
                                                              .text
                                                              .trim(),
                                                          attendanceType:
                                                              attendance,
                                                          latitude: latitude,
                                                          longitude: longitude,
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
                                                        color: Colors.white,
                                                        size: 95,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                        }),
                                      )
                                    ],
                                  ),
                                )
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
