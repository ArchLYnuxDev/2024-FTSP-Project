/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'package:flutter/material.dart';
import 'explorermap.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:project/constants.dart';
import 'explorer.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:project/app_life_globals.dart' as globals;
import 'package:project/network_util.dart' as networking;

class SelectRoutePage extends StatefulWidget {
  final List<Map<String, dynamic>> jsonData;
  Map? account;

  // String dateandTime;

  // String firstLocation;

  String secondLocation;

  String routeindex;

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

  SelectRoutePage(
      {Key? key,
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
      required this.routeindex,
      required this.jsonData
      // required this.dateandTime,
      })
      : super(key: key);

  @override
  State<SelectRoutePage> createState() => _SelectRoutePageState();
}

class _SelectRoutePageState extends State<SelectRoutePage> {
  bool _isLoading = false;
  List<List<List<double>>> coordinates =
      []; // Each itinerary has its own list of coordinate pairs
  List<List<LatLng>> polylineCoordinates =
      []; // Each itinerary has its own list of polyline coordinates
  List<List<Map<String, dynamic>>> poiItinerary = [];
  List<List<Map<String, dynamic>>> itiTotalTime = [];
  List<List<Map<String, dynamic>>> itineraryName = [];
  List<List<String>> routeInstructions =
      []; // Each itinerary has its own list of instructions
  final PolylinePoints polylinePoints = PolylinePoints();

  // List coords = [];
  List<TaggedPolyline> polydata = [];
  // int selectedidx = 0;

  @override
  void initState() {
    super.initState();
    prepareItineraries();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      if(response != null) widget.account = jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  void prepareItineraries() {
    if (widget.selectedIconIndex == 4) {
      List<List<TaggedPolyline>> polydataTemp =
          List.generate(widget.jsonData.length, (_) => []);
      List<List<double>> itineraryCoordinates = [];
      List<LatLng> itineraryPolylineCoordinates = [];
      List<String> itineraryRouteInstructions = [];

      for (var itineraryData in widget.jsonData) {
        //coordinates
        if (itineraryData.containsKey('Coords')) {
          itineraryCoordinates = (itineraryData['Coords'] as List<dynamic>)
              .map((e) => [e[0] as double, e[1] as double])
              .toList();
        }
        coordinates.add(itineraryCoordinates);

        //polylines
        for (int i = 0; i < widget.jsonData.length; i++) {
          if (itineraryData.containsKey('Routes')) {
            List<dynamic> routes = itineraryData['Routes'];
            for (int j = 0; j < routes.length; j++) {
              var route = routes[j];
              if (route.containsKey('plan') &&
                  route['plan'].containsKey('itineraries')) {
                List<dynamic> itineraries = route['plan']['itineraries'];
                if (itineraries.isNotEmpty) {
                  List<dynamic> legs = itineraries[0]['legs'];
                  for (var leg in legs) {
                    String travelMode = leg['mode'];
                    String? mrtLineName = leg['routeLongName'];
                    String? busNo = leg['routeShortName'];
                    String fromName = leg['from']['name'];
                    String toName = leg['to']['name'];
                    String encodedPoly = leg['legGeometry']['points'];
                    List<PointLatLng> decodedPoly =
                        polylinePoints.decodePolyline(encodedPoly);
                    List<LatLng> polyPoints = decodedPoly
                        .map((point) => LatLng(point.latitude, point.longitude))
                        .toList();

                    // Adding polyline points to the itineraryPolylineCoordinates
                    itineraryPolylineCoordinates.addAll(polyPoints);
                    print('mrtLineName: $mrtLineName');
                    if (travelMode == "SUBWAY") {
                      if (mrtLineName == "NORTH SOUTH LINE") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.red.shade500,
                        ));
                      } else if (mrtLineName == "EAST WEST LINE") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.green,
                        ));
                      } else if (mrtLineName == "NORTH EAST LINE") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.purple,
                        ));
                      } else if (mrtLineName == "CIRCLE LINE") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.orange.shade300,
                        ));
                      } else if (mrtLineName == "DOWNTOWN LINE") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.blue.shade600,
                        ));
                      } else if (mrtLineName == "SENTOSA EXPRESS") {
                        polydata.add(TaggedPolyline(
                          tag:
                              "Take the $mrtLineName from $fromName to $toName.",
                          points: polyPoints,
                          strokeWidth: 5.0,
                          color: Colors.white,
                        ));
                      }
                    } else if (travelMode == "BUS") {
                      polydata.add(TaggedPolyline(
                        tag: "Take Bus $busNo from $fromName to $toName.",
                        points: polyPoints,
                        strokeWidth: 5.0,
                        color: Colors.black,
                      ));
                    } else {
                      polydata.add(TaggedPolyline(
                        tag: "Walk from $fromName to $toName.",
                        points: polyPoints,
                        strokeWidth: 5.0,
                        color: Colors.grey.shade700,
                        isDotted: true,
                        borderStrokeWidth: 2.0,
                        borderColor: Colors.white,
                      ));
                    }
                  }
                }
              }
            }

            for (int i = 0; i < coordinates.length; i++) {
              if (i == 0) {
                // pois.add("Starting Point");
                itineraryRouteInstructions
                    .add("Starting Point: ${coordinates[i].toString()}");
              } else {
                if (itineraryData.containsKey('Itinerary') &&
                    i < itineraryData['Itinerary'].length) {
                  // pois.add(itineraryData['Itinerary'][i]);
                  itineraryRouteInstructions.add(
                      "Stop ${i}: ${itineraryData['Itinerary'][i]} at coordinates ${coordinates[i].toString()}");
                }
              }
            }
            polylineCoordinates.add(itineraryPolylineCoordinates);
            routeInstructions.add(itineraryRouteInstructions);
          }
          List<Map<String, dynamic>> itineraryDetails = [];
          if (itineraryData.containsKey('Itinerary')) {
            List<dynamic> itineraryNames = itineraryData[
                'Itinerary']; // Assuming this is a flat list with names only
            List<dynamic> categories = itineraryData['POICategories'];
            List<dynamic> startTimes = itineraryData['StartTimePOI'];
            List<dynamic> reachTimes = itineraryData['ReachTimePOI'];
            List<dynamic> leaveTimes = itineraryData['LeaveTimePOI'];

            // Process each point in the itinerary
            for (int i = 0; i < itineraryNames.length; i++) {
              Map<String, dynamic> details = {
                "Itinerary": itineraryNames[i],
                "POICategories": i < categories.length ? categories[i] : null,
                "StartTimePOI": i < startTimes.length
                    ? startTimes[i]
                    : null // This line is common for all, always set
              };

              // Use adjusted indices for reach and leave times, reflecting their nature of being applicable from the second item
              if (i > 0) {
                // If not the first item, add reach and leave times
                int reachTimeIndex = i - 1; // Adjusted index for reach time
                int leaveTimeIndex = i - 1; // Adjusted index for leave time

                details["ReachTimePOI"] = reachTimeIndex < reachTimes.length
                    ? reachTimes[reachTimeIndex]
                    : null;
                details["LeaveTimePOI"] = leaveTimeIndex < leaveTimes.length
                    ? leaveTimes[leaveTimeIndex]
                    : null;
              }

              itineraryDetails.add(details);
            }
          }
          List<Map<String, dynamic>> itineraryTotalTime = [];
          if (itineraryData.containsKey('TotalTime')) {
            // Creating a map to store index and TotalTime
            Map<String, dynamic> timeMap = {
              // 'index': itineraryData['index'],
              'TotalTime': itineraryData['TotalTime']
            };

            // Adding the map to the list
            itineraryTotalTime.add(timeMap);
          }

          poiItinerary.add(itineraryDetails);
          itiTotalTime.add(itineraryTotalTime);
        }
      }
    } else {
      for (var itineraryData in widget.jsonData) {
        List<List<double>> itineraryCoordinates = [];
        List<LatLng> itineraryPolylineCoordinates = [];
        List<String> itineraryRouteInstructions = [];

        if (itineraryData.containsKey('Coords')) {
          itineraryCoordinates = (itineraryData['Coords'] as List<dynamic>)
              .map((e) => [e[0] as double, e[1] as double])
              .toList();
        }

        if (itineraryData.containsKey('Routes')) {
          List<dynamic> routes = itineraryData['Routes'];
          for (var route in routes) {
            if (route.containsKey('route_geometry')) {
              List<LatLng> decodedPolyline =
                  decodePolylineNormal(route['route_geometry']);
              itineraryPolylineCoordinates.addAll(decodedPolyline);
            }
            if (route.containsKey('route_instructions')) {
              List<dynamic> instructions = route['route_instructions'];
              itineraryRouteInstructions
                  .addAll(instructions.map((inst) => inst.toString()));
            }
          }
        }

        coordinates.add(itineraryCoordinates);
        polylineCoordinates.add(itineraryPolylineCoordinates);
        routeInstructions.add(itineraryRouteInstructions);

        List<Map<String, dynamic>> itineraryDetails = [];
        if (itineraryData.containsKey('Itinerary')) {
          List<dynamic> itineraryNames = itineraryData[
              'Itinerary']; // Assuming this is a flat list with names only
          List<dynamic> categories = itineraryData['POICategories'];
          List<dynamic> startTimes = itineraryData['StartTimePOI'];
          List<dynamic> reachTimes = itineraryData['ReachTimePOI'];
          List<dynamic> leaveTimes = itineraryData['LeaveTimePOI'];

          // Process each point in the itinerary
          for (int i = 0; i < itineraryNames.length; i++) {
            Map<String, dynamic> details = {
              "Itinerary": itineraryNames[i],
              "POICategories": i < categories.length ? categories[i] : null,
              "StartTimePOI": i < startTimes.length
                  ? startTimes[i]
                  : null // This line is common for all, always set
            };

            // Use adjusted indices for reach and leave times, reflecting their nature of being applicable from the second item
            if (i > 0) {
              // If not the first item, add reach and leave times
              int reachTimeIndex = i - 1; // Adjusted index for reach time
              int leaveTimeIndex = i - 1; // Adjusted index for leave time

              details["ReachTimePOI"] = reachTimeIndex < reachTimes.length
                  ? reachTimes[reachTimeIndex]
                  : null;
              details["LeaveTimePOI"] = leaveTimeIndex < leaveTimes.length
                  ? leaveTimes[leaveTimeIndex]
                  : null;
            }

            itineraryDetails.add(details);
          }
        }

        List<Map<String, dynamic>> itineraryTotalTime = [];
        if (itineraryData.containsKey('TotalTime')) {
          // Creating a map to store index and TotalTime
          Map<String, dynamic> timeMap = {
            // 'index': itineraryData['index'],
            'TotalTime': itineraryData['TotalTime']
          };

          // Adding the map to the list
          itineraryTotalTime.add(timeMap);
        }

        poiItinerary.add(itineraryDetails);
        itiTotalTime.add(itineraryTotalTime);
      }
    }
  }

  List<LatLng> decodePolylineNormal(String encodedPolyline) {
    List<PointLatLng> decodedPolyline =
        polylinePoints.decodePolyline(encodedPolyline);
    return decodedPolyline
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  String routeindex = '';
  @override
  Widget build(BuildContext context) {
    TimeOfDay endTime = widget.endTime;

    int hours = endTime.hour;
    int minutes = endTime.minute;
    print(endTime);
    print(itiTotalTime);
    if (_isLoading) {
      // Show loading screen when _isLoading is true
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 5),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: IconButton(
                    onPressed: () {
                      // print('numbner of topk: ${widget.topK}');
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return ExplorerPage(
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
                  padding: EdgeInsets.only(left: 65),
                  child: Text(
                    "Select Your Route",
                    style: TextStyle(
                      color: textColorLightTheme,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(),
            child: Container(
              height: 170,
              width: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.circular(27),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 25.0),
                          child: Icon(
                            Icons.location_on,
                            size: 30,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Container(
                          height: 50,
                          width: 3,
                          color: Colors.grey.shade400,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Icon(
                            Icons.location_on,
                            size: 30,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 208, top: 25),
                        child: Text(
                          'From',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: SizedBox(
                              height: 30,
                              width: 150,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 9.0),
                                child: Text(
                                  "Current Location",
                                  // widget.secondLocation,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 20,
                            width: 3,
                            color: Colors.grey.shade300,
                          ),
                          Column(children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.now()
                                    .toUtc()
                                    .add((const Duration(hours: 8)))),
                                // DateFormat('kk:mm a').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 15,
                              ),
                              child: Text(
                                DateFormat('h:mm a').format(DateTime.now()
                                    .toUtc()
                                    .add((const Duration(hours: 8)))),
                                // DateFormat('kk:mm a').format(DateTime.now()),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ])
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 3),
                        child: Container(
                          height: 3,
                          width: 240,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 225, top: 10),
                            child: Text(
                              'To',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 10, right: 10),
                                child: SizedBox(
                                  height: 40,
                                  width: 150,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 9.0),
                                    child: Text(
                                      widget.secondLocation,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 20,
                                width: 3,
                                color: Colors.grey.shade300,
                              ),
                              Column(children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                      widget.startTime.hour,
                                      widget.startTime.minute,
                                    )),
                                    // DateFormat('kk:mm a').format(DateTime.now()),
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 15,
                                  ),
                                  child: Text(
                                    DateFormat('h:mm a').format(DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                      widget.startTime.hour,
                                      widget.startTime.minute,
                                    )),
                                    style: TextStyle(
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ])
                            ],
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),

          // routes
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: const Offset(0, 5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(27),
                  topRight: Radius.circular(27),
                ),
              ),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(
                      'Here are the best generated',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'itineraries just for you:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Available Time: $hours hours $minutes minutes',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      )),
                  Expanded(
                    // This is optional depending on your layout needs
                    child: Column(
                      children: [
                        // Any other widgets you want above the list
                        Expanded(
                          // Adjusted height according to content
                          child: ListView.builder(
                            itemCount: widget.topN,
                            itemBuilder: (context, index) {
                              // Safely check that routeInstructions has the required data for the given index
                              String displayText = "N/A";
                              if (index < poiItinerary.length &&
                                  poiItinerary[index].isNotEmpty) {
                                displayText = poiItinerary[index]
                                    .map((item) => item['Itinerary'].toString())
                                    .join(
                                        ' > '); // Concatenating itineraries with ' > '
                              }

                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, bottom: 20),
                                child: InkWell(
                                  onTap: () async {
                                    // Add async here to make this function asynchronous
                                    setState(() {
                                      widget.routeindex =
                                          '$index'; // Set the current index as the route index
                                      _isLoading = true; // Start loading
                                    });

                                    // Optionally delay the navigation to simulate processing
                                    // await Future.delayed(Duration(seconds: 2));
                                    print('polyline: ${polylineCoordinates}');
                                    print('polydata: ${polydata}');
                                    print(
                                        'poiItinerary: ${poiItinerary.length}');
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (BuildContext context) {
                                          return ExplorerMapPage(
                                            coordinates: coordinates[index],
                                            polylineCoordinates:
                                                polylineCoordinates[index],
                                            poiItinerary: poiItinerary[index],
                                            routeInstructions:
                                                routeInstructions[index],
                                            secondLocation:
                                                widget.secondLocation,
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
                                            routeindex: widget.routeindex,
                                            jsonData: widget.jsonData,
                                            polydata: polydata,
                                          );
                                        },
                                      ),
                                    );
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  },
                                  child: Expanded(
                                    child: Container(
                                      width: 400,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 7,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(27),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20, top: 20, right: 15),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex:
                                                      2, // You can adjust flex to change the proportion
                                                  child: Text(
                                                    'Route ${index + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey,
                                                      fontSize: 16,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 20,
                                                            right: 15),
                                                    child: Text(
                                                      displayText, // Assuming displayText is the variable holding your text
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey.shade500,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines:
                                                          10, // Allows text to wrap onto up to two lines
                                                      overflow: TextOverflow
                                                          .visible, // Allows text to be visible beyond the first line
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (widget.selectedIconIndex == 1)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                  left: 15,
                                                  bottom: 20),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.directions_walk,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  Text(
                                                    (index <
                                                                itiTotalTime
                                                                    .length &&
                                                            itiTotalTime[index]
                                                                .isNotEmpty)
                                                        ? itiTotalTime[index][0]
                                                                ['TotalTime'] ??
                                                            'N/A'
                                                        : 'N/A',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis, // Managing long strings gracefully
                                                  )
                                                ],
                                              ),
                                            ),
                                          if (widget.selectedIconIndex == 2)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                  left: 15,
                                                  bottom: 20),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.drive_eta,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  Text(
                                                    (index <
                                                                itiTotalTime
                                                                    .length &&
                                                            itiTotalTime[index]
                                                                .isNotEmpty)
                                                        ? itiTotalTime[index][0]
                                                                ['TotalTime'] ??
                                                            'N/A'
                                                        : 'N/A',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis, // Managing long strings gracefully
                                                  )
                                                ],
                                              ),
                                            ),
                                          if (widget.selectedIconIndex == 3)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                  left: 20,
                                                  bottom: 20),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.pedal_bike_outlined,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 2),
                                                  ),
                                                  Text(
                                                    (index <
                                                                itiTotalTime
                                                                    .length &&
                                                            itiTotalTime[index]
                                                                .isNotEmpty)
                                                        ? itiTotalTime[index][0]
                                                                ['TotalTime'] ??
                                                            'N/A'
                                                        : 'N/A',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis, // Managing long strings gracefully
                                                  )
                                                ],
                                              ),
                                            ),
                                          if (widget.selectedIconIndex == 4)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                  left: 20,
                                                  bottom: 20),
                                              child: Row(
                                                children: [
                                                  Image.asset(
                                                    'assets/public-transport.jpg',
                                                    height: 30,
                                                    width: 30,
                                                    color: Colors.black,
                                                  ),
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 2),
                                                  ),
                                                  Text(
                                                    (index <
                                                                itiTotalTime
                                                                    .length &&
                                                            itiTotalTime[index]
                                                                .isNotEmpty)
                                                        ? itiTotalTime[index][0]
                                                                ['TotalTime'] ??
                                                            'N/A'
                                                        : 'N/A',
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis, // Managing long strings gracefully
                                                  )
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
