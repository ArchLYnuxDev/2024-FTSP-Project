/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:google_maps_webservice/places.dart';
import 'package:project/pages/explorer/choiceForEnd.dart';
import 'package:project/pages/explorer/explorer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:another_flushbar/flushbar.dart';

import 'package:project/location_list_tile.dart';
import 'package:project/network_util.dart' as networking; // Was imported before I did, unused tho.
import 'package:project/constants.dart';
import 'package:project/autocomplate_prediction.dart';
import 'package:project/place_auto_complate_response.dart';

import 'package:project/app_life_globals.dart' as globals;
import 'dart:convert';

class SearchLocationPage2 extends StatefulWidget {
  Map? account; // Not necessary here.
  // String dateandTime;

  // String firstLocation;

  String secondLocation;

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

  SearchLocationPage2({
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
  State<SearchLocationPage2> createState() => _SearchLocationPage2State();
}

class _SearchLocationPage2State extends State<SearchLocationPage2> {
  TextEditingController inputUserEndPOI = TextEditingController();
  @override
  void initState() {
    super.initState();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      widget.account = response == null ? null : jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  // final GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: search_apiKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, bottom: 4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return ChoiceForEndPage(
                              // firstLocation: widget.firstLocation,
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
                              // dateandTime: widget.dateandTime,
                            );
                          },
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      color: Colors.black,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 45),
                  child: Text(
                    "Your end destination",
                    style: TextStyle(
                        color: textColorLightTheme,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 30,
              bottom: 20,
            ),
            child: Container(
                height: 60,
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                    ),
                    TextField(
                      controller: inputUserEndPOI,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: SvgPicture.asset(
                            "assets/location_pin_2.svg",
                            color: secondaryColor40LightTheme,
                            height: 20,
                            width: 20,
                          ),
                        ),
                        hintText: "Input your preferred end point here",
                        hintStyle: TextStyle(color: Colors.grey[410]),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 12.0),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isEmpty) {
                          showTopSnackBar(context,
                              error: "Input Error",
                              message:
                                  "Please enter a destination to proceed.");
                        } else {
                          // If the text is not empty, navigate using the text as the location
                          navigateToExplorerPage(value);
                        }
                      },
                    )
                  ],
                )),
          ),
          Divider(
            height: 4,
            thickness: 4,
            color: Colors.grey.shade200,
          ),
          // Padding(
          //   padding: const EdgeInsets.all(defaultPadding),
          //   child: ElevatedButton.icon(
          //     onPressed: () async {
          //       String enteredText = inputUserEndPOI.text.trim();

          //       if (enteredText.isNotEmpty) {
          //         // If the text is not empty, navigate using the text as the location
          //         navigateToExplorerPage(enteredText);
          //       } else {
          //         // If the text is empty, try to fetch the current location
          //         bool serviceEnabled =
          //             await Geolocator.isLocationServiceEnabled();
          //         if (!serviceEnabled) {
          //           showTopSnackBar(context,
          //               error: 'Error',
          //               message:
          //                   'Location services are disabled. Please enable them to use this feature.');
          //           return;
          //         }

          //         LocationPermission permission =
          //             await Geolocator.checkPermission();
          //         if (permission == LocationPermission.denied) {
          //           permission = await Geolocator.requestPermission();
          //           if (permission == LocationPermission.denied) {
          //             showTopSnackBar(context,
          //                 error: 'Error',
          //                 message:
          //                     'Location permissions are denied. Please grant permission to use this feature.');
          //             return;
          //           }
          //         }

          //         if (permission == LocationPermission.deniedForever) {
          //           showTopSnackBar(context,
          //               error: 'Error',
          //               message:
          //                   'Location permissions are permanently denied. Please enable them in your device settings.');
          //           return;
          //         }

          //         // Permissions are granted, proceed to get the location
          //         var position = await Geolocator.getCurrentPosition(
          //             desiredAccuracy: LocationAccuracy.high);
          //         List<Placemark> placemarks = await placemarkFromCoordinates(
          //             position.latitude, position.longitude);
          //         String fullAddress =
          //             '${placemarks.first.street}, ${placemarks.first.locality}, ${placemarks.first.postalCode}, ${placemarks.first.country}';

          //         navigateToExplorerPage(fullAddress,
          //             lat: position.latitude, lon: position.longitude);
          //       }
          //     },
          //     icon: const Icon(Icons.location_on),
          //     label: const Text("Use my Current Location"),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: Colors.grey.shade200,
          //       foregroundColor: textColorLightTheme,
          //       elevation: 0,
          //       minimumSize: const Size(380, 45),
          //       shape: const RoundedRectangleBorder(
          //         borderRadius: BorderRadius.all(Radius.circular(10)),
          //       ),
          //     ),
          //   ),
          // ),
          // Divider(
          //   height: 4,
          //   thickness: 4,
          //   color: Colors.grey.shade200,
          // ),
          // Expanded(
          //   child: ListView.builder(
          //     itemCount: placePredictions.length,
          //     itemBuilder: (context, index) => LocationListTile(
          //       press: () async {
          //         debugPrint(placePredictions[index].placeId!);
          //         var placeId = placePredictions[index].placeId!;

          //         // PlacesDetailsResponse detail =
          //         //     await _places.getDetailsByPlaceId(placeId);

          //         // double? lat2 = detail.result.geometry?.location.lat;
          //         // double? lng2 = detail.result.geometry?.location.lng;

          //         // print('$lat2');
          //         // print('$lng2');

          //         Navigator.of(context).pushReplacement(
          //           MaterialPageRoute(
          //             builder: (BuildContext context) {
          //               return ExplorerPage(
          //                 Email: widget.Email,
          //                 UID: widget.UID,
          //                 // firstLocation: widget.firstLocation,
          //                 secondLocation: placePredictions[index].description!,
          //                 startTime: widget.startTime,
          //                 endTime: widget.endTime,
          //                 selectedIconIndex: widget.selectedIconIndex,
          //                 endDestinationChoice: widget.endDestinationChoice,
          //                 topK: widget.topK,
          //                 topN: widget.topN,
          //                 // start coords
          //                 latStart: widget.latStart,
          //                 longStart: widget.longStart,
          //                 // end coords
          //                 latEnd: 0,
          //                 longEnd: 0,
          //                 // dateandTime: widget.dateandTime,
          //               );
          //             },
          //           ),
          //         );
          //       },
          //       location: placePredictions[index].description!,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void navigateToExplorerPage(String location, {double? lat, double? lon}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return ExplorerPage(
            secondLocation: location,
            startTime: widget.startTime,
            endTime: widget.endTime,
            selectedIconIndex: widget.selectedIconIndex,
            endDestinationChoice: widget.endDestinationChoice,
            topK: widget.topK,
            topN: widget.topN,
            latStart: widget.latStart,
            longStart: widget.longStart,
            latEnd: lat ?? widget.latEnd,
            longEnd: lon ?? widget.longEnd,
          );
        },
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
