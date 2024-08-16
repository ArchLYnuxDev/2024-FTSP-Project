/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
//import 'package:project/pages/main/explorer/searchlocation1.dart';
//import 'package:project/pages/main/explorer/currentlocation.dart';
//import 'package:project/pages/main/explorer/explorermap.dart';

import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'selectroute.dart';
import 'package:project/pages/profile/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'choiceForEnd.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

import 'package:project/app_life_globals.dart' as globals;
import 'package:project/network_util.dart' as networking;

const List<String> NoOfPOIs = <String>['2', '3', '4', '5', '6'];
const List<String> NoofItinerary = <String>['1', '2', '3'];

class ExplorerPage extends StatefulWidget {
  Map? account;
  // String firstLocation;
  String secondLocation;
  // String dateandTime;
  TimeOfDay startTime;
  TimeOfDay endTime;
  int selectedIconIndex;
  int endDestinationChoice;
  int topK;
  int topN;
  double latStart;
  double longStart;
  double latEnd;
  double longEnd;

  ExplorerPage({
    Key? key,
    // required this.firstLocation,
    required this.secondLocation,
    required this.startTime,
    required this.endTime,
    required this.selectedIconIndex,
    required this.endDestinationChoice,
    required this.topK,
    required this.topN,
    required this.latStart,
    required this.latEnd,
    required this.longStart,
    required this.longEnd,
    // required this.dateandTime,
  }) : super(key: key);

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

class TimeSelection {
  final int hours;
  final int minutes;

  TimeSelection(this.hours, this.minutes);
}

class _ExplorerPageState extends State<ExplorerPage> {
  List<Map<String, dynamic>> jsonData = [];
  bool _isLoading = false;

  Position? _currentLocation;
  String location = "";

  double latStart = 0;
  double longStart = 0;

  void currentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];

      setState(() {
        widget.latStart = position.latitude;
        widget.longStart = position.longitude;

        location =
            "${place.street} , ${place.name} , ${place.country} ${place.postalCode}";
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    if (!serviceEnabled) {
      return Future.error('Location Services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        return Future.error('Location permission is denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location Permission are denied permanently.');
    }

    return await Geolocator.getCurrentPosition();
  }

  int pageIndex = 0;
  TimeOfDay _timeOfDay1 = TimeOfDay.now();
  String dropdownValueNoOfPOIs = NoOfPOIs.first;
  String dropdownValueNoOfItinerary = NoofItinerary.first;
  DateTime _endTime = DateTime.now().toUtc().add((const Duration(hours: 8)));

  String formatTimeDifference(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours hours and $minutes minutes';
  }

  Future<void> _selectDateTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
    );

    if (selectedTime != null) {
      setState(() {
        _timeOfDay1 = selectedTime;
        widget.startTime = _timeOfDay1;
      });
    }

    if (selectedTime != null) {
      // Ensuring the initialDate is today or later
      DateTime now = DateTime.now();
      DateTime initialDate = DateTime(
        _endTime.year,
        _endTime.month,
        _endTime.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (initialDate.isBefore(now)) {
        initialDate = now;
      }

      // Setting the firstDate to a year ago and lastDate to five years from now
      final DateTime firstDate = DateTime(now.year - 1);
      final DateTime lastDate = DateTime(now.year + 5);

      final selectedDateTime = await showDatePicker(
        context: context,
        initialDate: initialDate, // Set to today or later
        firstDate: firstDate,
        lastDate: lastDate,
      );

      if (selectedDateTime != null) {
        setState(() {
          _endTime = DateTime(
            selectedDateTime.year,
            selectedDateTime.month,
            selectedDateTime.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentLocation();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      widget.account = response == null ? null : jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  int calculateAvailableTimeInSeconds() {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day,
        widget.startTime.hour, widget.startTime.minute);
    final DateTime todayEnd = DateTime(now.year, now.month, now.day,
        widget.endTime.hour, widget.endTime.minute);

    // Handling cases where the end time might be on the next day
    final DateTime adjustedEndTime = todayEnd.isBefore(todayStart)
        ? todayEnd.add(Duration(days: 1))
        : todayEnd;

    Duration duration = adjustedEndTime.difference(todayStart);
    return duration.inSeconds; // Returning seconds directly
  }

  Future<void> makePostRequest() async {
    var url = '${globals.serverURL}getrecommendation';
    int convertToSeconds(int hour, int min) => (hour * 3600) + (min * 60);

    var jsondata = {
      'uid': widget.account?["account"]?["User ID"] ?? "N/A",
      'request_model_to_predict_ranked_pois_given_uid': "200",
      'topk': widget.topK,
      'topn': widget.topN,
      'useravailtime': convertToSeconds(widget.endTime.hour, widget.endTime.minute),
      'vehiclemode': widget.selectedIconIndex,
      'mode': widget.endDestinationChoice,
      'userendpoi': widget.secondLocation,
      'latuser': widget.latStart.toString(),
      'longuser': widget.longStart.toString(),
      'allow_consecutive_foodpoi_in_itinerary': true,
      'StartDateTime': DateFormat('yyyy-MM-dd kk:mm:00').format(DateTime.now().toUtc().add(const Duration(hours: 8))),
    };

    debugPrint("Connecting to ${url}");
    try {
      late final response;
      try {
        //response = await globals.currentSession!.get(url, jsondata); 
        response = await globals.currentSession!.post(url, jsondata); // use get pls, hard to use get with params in flutter
          //await http.post(Uri.parse(url), headers: headers, body: body);
      } on TimeoutException catch (e) {
        debugPrint("TIMEOUT ${e}");
        rethrow;
      }

      debugPrint('Status Code: ${response.statusCode}');
      if (response.statusCode < 200 || response.statusCode > 299) {
        debugPrint("Status: ${response.statusCode}, Error: ${response.body}");
        return;
      }
      switch(response.statusCode) {
        case 200:
          var jsonResponse = jsonDecode(response.body);
          debugPrint('POST request successful explorer, Response body: ${response.body}');
          if (jsonResponse is List) {
            List<Map<String, dynamic>> dataList =
                jsonResponse.cast<Map<String, dynamic>>();
            setState(() {
              jsonData = dataList;
            });
          } else {
            debugPrint('Expected a list, but got: ${jsonResponse.runtimeType}');
          }
        break;
        default:
          debugPrint(
              'GET request failed with status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error occurred while making GET request: $e');
    }
  }

  Future<void> main() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    await makePostRequest(); // This will now properly await the HTTP request

    // After the request is completed, check if jsonData is populated
    if (jsonData.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) {
            return SelectRoutePage(
              secondLocation: widget.secondLocation,
              startTime: widget.startTime,
              endTime: widget.endTime,
              selectedIconIndex: widget.selectedIconIndex,
              endDestinationChoice: widget.endDestinationChoice,
              topK: widget.topK,
              topN: widget.topN,
              latStart: widget.latStart,
              latEnd: widget.latEnd,
              longStart: widget.longStart,
              longEnd: widget.longEnd,
              routeindex: '0',
              jsonData: jsonData,
            );
          },
        ),
      );
    } else {
      showTopSnackBar(context,
          error: 'Error',
          message: 'No recommendations received from the server.');
    }
    setState(() {
      _isLoading = false; // Stop loading
    });
  }

  int nowSec = 0;
  int endSec = 0;
  int previousSec = 0;
  int diffSec = 0;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now(); // Current system time
    final DateTime endTimeAdjusted =
        _endTime; // End time set by user and adjusted for UTC+8
    final Duration difference = endTimeAdjusted
        .difference(now); // Duration between now and the end time

    final int hours = difference.inHours; // Total hours in the duration
    final int minutes = difference.inMinutes % 60;

    final timeOfDayDifference = TimeOfDay(hour: hours, minute: minutes);

    setState(() {
      widget.endTime = timeOfDayDifference;
    });

    return Scaffold(
      // backgroundColor: const Color(0xffC4DFCB),
      // body: pages[pageIndex],
      body: _isLoading
          ? Container(
              color:
                  Colors.white, // Light blue background color for loading state
              width: double
                  .infinity, // Ensures the container fills the screen width
              height: MediaQuery.of(context)
                  .size
                  .height, // Ensures the container fills the screen height
              child: Center(
                // Center widget to center the CircularProgressIndicator
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade500), // Red color for the spinner
                ),
              ),
            )
          : SingleChildScrollView(
              child: Container(
                child: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 25, left: 15, right: 30),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 1,
                              ),
                              child: Column(
                                children: const [
                                  Text(
                                    '   AI Powered Planner                          ',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      // color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // const SizedBox(width: 35),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) {
                                      return ProfilePage();
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(50, 60),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ///////////////
                      // Transport //
                      ///////////////
                      const Padding(
                        padding:
                            EdgeInsets.only(right: 250, top: 20, bottom: 20),
                        child: Text(
                          'Transport',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 25, left: 25, bottom: 10),
                            child: SizedBox(
                              height: 60,
                              width: 342,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        widget.selectedIconIndex = 1;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      child: Container(
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: widget.selectedIconIndex == 1
                                              ? Colors.red
                                              : Colors.grey.shade200,
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 17),
                                              ///////////////
                                              // Walk Icon //
                                              ///////////////
                                              child:
                                                  widget.selectedIconIndex == 1
                                                      ? const Icon(
                                                          Icons.directions_walk,
                                                          size: 25,
                                                          color: Colors.white,
                                                        )
                                                      : const Icon(
                                                          Icons.directions_walk,
                                                          size: 25,
                                                          color: Colors.black,
                                                        ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        widget.selectedIconIndex = 2;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      child: Container(
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: widget.selectedIconIndex == 2
                                              ? Colors.red
                                              : Colors.grey.shade200,
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 18),
                                              ///////////////
                                              // Car Icon //
                                              ///////////////
                                              child:
                                                  widget.selectedIconIndex == 2
                                                      ? const Icon(
                                                          Icons.directions_car,
                                                          size: 25,
                                                          color: Colors.white,
                                                        )
                                                      : const Icon(
                                                          Icons.directions_car,
                                                          size: 25,
                                                          color: Colors.black,
                                                        ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        widget.selectedIconIndex = 3;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      child: Container(
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: widget.selectedIconIndex == 3
                                              ? Colors.red
                                              : Colors.grey.shade200,
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 18),
                                              ////////////////
                                              // Cycle Icon //
                                              ////////////////
                                              child:
                                                  widget.selectedIconIndex == 3
                                                      ? const Icon(
                                                          Icons.directions_bike,
                                                          size: 25,
                                                          color: Colors.white,
                                                        )
                                                      : const Icon(
                                                          Icons.directions_bike,
                                                          size: 25,
                                                          color: Colors.black,
                                                        ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        widget.selectedIconIndex = 4;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 5, right: 5),
                                      child: Container(
                                        width: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          color: widget.selectedIconIndex == 4
                                              ? Colors.red
                                              : Colors.grey.shade200,
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 12),
                                                ///////////////////////////
                                                // Public Transport Icon //
                                                ///////////////////////////
                                                child:
                                                    widget.selectedIconIndex ==
                                                            4
                                                        ? Image.asset(
                                                            'assets/public-transport.jpg',
                                                            height: 35,
                                                            width: 35,
                                                            color: Colors.white,
                                                          )
                                                        : Image.asset(
                                                            'assets/public-transport.jpg',
                                                            height: 35,
                                                            width: 35,
                                                            color: Colors.black,
                                                          )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        /////////////////////////
                        // Recommendation Mode //
                        /////////////////////////
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(left: 26.0),
                            child: Text(
                              'Recommendation Mode',
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 10,
                          left: 20,
                        ),
                        child: Row(
                          ///////////////////////////////////
                          // Recommendation Mode Drop Down //
                          ///////////////////////////////////
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (BuildContext context) {
                                      ////////////////////////////////
                                      // Go to End Destination Page //
                                      ////////////////////////////////
                                      return ChoiceForEndPage(
                                        // firstLocation: widget.firstLocation,
                                        secondLocation: widget.secondLocation,
                                        startTime: widget.startTime,
                                        endTime: widget.endTime,
                                        selectedIconIndex:
                                            widget.selectedIconIndex,
                                        endDestinationChoice:
                                            widget.endDestinationChoice,
                                        topK: widget.topK,
                                        topN: widget.topN,
                                        latStart: widget.latStart,
                                        latEnd: widget.latEnd,
                                        longStart: widget.longStart,
                                        longEnd: widget.longEnd,
                                        // dateandTime: widget.dateandTime,
                                      );
                                    },
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                minimumSize: const Size(352, 60),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon(
                                  //   Icons.search,
                                  //   color: Colors.grey.shade800,
                                  // ),
                                  Padding(
                                    padding: const EdgeInsets.only(),
                                    child: SizedBox(
                                      height: 40,
                                      width: 245,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12, left: 0, bottom: 10),
                                        child: Text(
                                          widget.secondLocation,
                                          style: TextStyle(
                                            color: Colors.grey.shade900,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  //////////////////////////////////////////////////////////////////////////
                                  // Down arrow button on right side of Recommendation Mode Drop down box //
                                  //////////////////////////////////////////////////////////////////////////
                                  // Padding(
                                  //   padding: const EdgeInsets.only(),
                                  //   child: IconButton(
                                  //     onPressed: () {
                                  //       setState(() {
                                  //         widget.secondLocation = '';
                                  //       });
                                  //     },
                                  //     icon: Icon(
                                  //       Icons.arrow_drop_down,
                                  //       color: Colors.grey.shade600,
                                  //     ),
                                  //   ),
                                  // )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: const [
                          /////////////////////////////////////////////
                          // Change Request ** Remove Number of POIs //
                          /////////////////////////////////////////////
                          // Padding(
                          //   padding: EdgeInsets.only(left: 25, top: 20),
                          //   child: Text(
                          //     'Number of POIs',
                          //     style: TextStyle(
                          //       color: Colors.black,
                          //       fontSize: 20,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //   ),
                          // ),

                          ///////////////////////////
                          // Itinerary to Generate //
                          ///////////////////////////
                          Padding(
                            padding: EdgeInsets.only(left: 26, top: 20),
                            child: Text(
                              'Itinerary to Generate',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(),
                        child: Row(
                          children: [
                            /////////////////////////////////////////////////////////
                            // Change Request ** Remove Number of POIs ** DropDown //
                            /////////////////////////////////////////////////////////

                            // Padding(
                            //   padding: const EdgeInsets.only(top: 15, left: 20),
                            //   child: Container(
                            //     height: 60,
                            //     width: 118,
                            //     decoration: BoxDecoration(
                            //       color: Colors.white,
                            //       boxShadow: [
                            //         BoxShadow(
                            //           color: Colors.grey.withOpacity(0.5),
                            //           // spreadRadius: 1,
                            //           blurRadius: 1,
                            //           offset: const Offset(0, 3),
                            //         ),
                            //       ],
                            //       borderRadius: const BorderRadius.all(
                            //         Radius.circular(20),
                            //       ),
                            //     ),
                            //     child: Column(
                            //       children: [
                            //         Padding(
                            //           padding:
                            //               const EdgeInsets.only(top: 5, left: 17),
                            //           child: DropdownButton2(
                            //             iconStyleData: const IconStyleData(
                            //               icon: Padding(
                            //                 padding: EdgeInsets.only(left: 38),
                            //                 child: Icon(Icons.arrow_drop_down),
                            //               ),
                            //               iconSize: 30,
                            //             ),
                            //             dropdownStyleData: DropdownStyleData(
                            //               maxHeight: 200,
                            //               width: 100,
                            //               padding: null,
                            //               decoration: BoxDecoration(
                            //                 borderRadius: BorderRadius.circular(14),
                            //               ),
                            //               elevation: 8,
                            //               offset: const Offset(-20, 0),
                            //               scrollbarTheme: ScrollbarThemeData(
                            //                 radius: const Radius.circular(40),
                            //                 thickness: MaterialStateProperty.all(6),
                            //                 thumbVisibility:
                            //                     MaterialStateProperty.all(true),
                            //               ),
                            //             ),
                            //             underline: const SizedBox(),
                            //             value: widget.topK.toString(),
                            //             onChanged: (newValue) {
                            //               setState(() {
                            //                 dropdownValueNoOfPOIs = newValue!;
                            //                 widget.topK = int.parse(dropdownValueNoOfPOIs);
                            //               });
                            //             },
                            //             items: NoOfPOIs.map<DropdownMenuItem<String>>(
                            //                 (value) {
                            //               return DropdownMenuItem<String>(
                            //                 value: value,
                            //                 child: Text(value),
                            //               );
                            //             }).toList(),
                            //           ),
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15, left: 26),
                              child: Container(
                                height: 60,
                                width: 118,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      // spreadRadius: 1,
                                      blurRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, left: 17),
                                      child: DropdownButton2(
                                        iconStyleData: const IconStyleData(
                                          icon: Padding(
                                            padding: EdgeInsets.only(left: 38),
                                            child: Icon(Icons.arrow_drop_down),
                                          ),
                                          iconSize: 30,
                                        ),
                                        dropdownStyleData: DropdownStyleData(
                                          maxHeight: 200,
                                          width: 100,
                                          padding: null,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          elevation: 8,
                                          offset: const Offset(-20, 0),
                                          scrollbarTheme: ScrollbarThemeData(
                                            radius: const Radius.circular(40),
                                            thickness:
                                                MaterialStateProperty.all(6),
                                            thumbVisibility:
                                                MaterialStateProperty.all(true),
                                          ),
                                        ),
                                        underline: const SizedBox(),
                                        value: widget.topN > 0
                                            ? widget.topN.toString()
                                            : '1',
                                        onChanged: (newValue3) {
                                          setState(() {
                                            dropdownValueNoOfItinerary =
                                                newValue3!;
                                            widget.topN = int.parse(
                                                dropdownValueNoOfItinerary);
                                          });
                                        },
                                        items: NoofItinerary.map<
                                            DropdownMenuItem<String>>((value1) {
                                          return DropdownMenuItem<String>(
                                            value: value1,
                                            child: Text(value1),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(left: 25, top: 20),
                            child: Text(
                              'End Time',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 15, left: 20),
                              child: ElevatedButton(
                                onPressed: _selectDateTime,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  minimumSize: const Size(100, 60),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      color: Colors.grey.shade900,
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(_endTime),
                                      style: TextStyle(
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: ElevatedButton(
                          onPressed: () async {
                            currentLocation();
                            await _getCurrentLocation();

                            if (formKey.currentState!.validate()) {
                              nowSec = (widget.startTime.hour * 60 +
                                      widget.startTime.minute) *
                                  60;
                              endSec = (widget.endTime.hour * 60 +
                                      widget.endTime.minute) *
                                  60;
                              previousSec =
                                  (_timeOfDay1.hour * 60 + _timeOfDay1.minute) *
                                      60;
                              diffSec = endSec - nowSec;

                              if (widget.secondLocation != 'Select mode' &&
                                  (widget.selectedIconIndex == 1 ||
                                      widget.selectedIconIndex == 2 ||
                                      widget.selectedIconIndex == 3 ||
                                      widget.selectedIconIndex == 4)) {
                                await main();
                                setState(() {
                                  _isLoading = false;
                                }); // Stop loading after operations
                                // Use await to ensure this completes before potentially showing a dialog
                              } else {
                                if (widget.secondLocation == 'Select mode') {
                                  showTopSnackBar(context,
                                      error: 'Error',
                                      message:
                                          'Please choose a recommendation mode');
                                } else if (!(widget.selectedIconIndex >= 1 &&
                                    widget.selectedIconIndex <= 4)) {
                                  showTopSnackBar(context,
                                      error: 'Error',
                                      message:
                                          'Please select a mode of transport');
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(360, 60),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Get Recommendations',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20)
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void showTopSnackBar(BuildContext context,
          {required String error, required String message}) =>
      Flushbar(
        icon: const Icon(
          Icons.error,
          size: 32,
          color: Colors.white,
        ),
        shouldIconPulse: false,
        padding: const EdgeInsets.all(24),
        title: error,
        message: message,
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
        dismissDirection: FlushbarDismissDirection.HORIZONTAL,
        duration: const Duration(seconds: 2),
        barBlur: 20,
        backgroundColor: Colors.red.shade700.withOpacity(0.9),
      )..show(context);
}

class TravelInfo {
  final String name;
  final String email;

  TravelInfo(this.name, this.email);

  TravelInfo.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        email = json['email'];

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };
}
