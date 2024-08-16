/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:async';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';

import 'selectroute.dart';

import 'dart:convert';
import 'explorer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'popup/place_popup.dart';
import 'popup/info_popup.dart';

import 'package:project/app_life_globals.dart' as globals;
import 'package:project/network_util.dart' as networking;

class ExplorerMapPage extends StatefulWidget {
  Map? account;

  List<List<double>> coordinates;
  List<LatLng> polylineCoordinates;
  List<dynamic> poiItinerary;
  List<dynamic> routeInstructions;
  final List<Map<String, dynamic>> jsonData;
  List<TaggedPolyline> polydata;

  String routeindex;

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

  ExplorerMapPage(
      {Key? key,
      required this.coordinates,
      required this.polylineCoordinates,
      required this.poiItinerary,
      required this.routeInstructions,
      required this.polydata,
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
  State<ExplorerMapPage> createState() => ExplorerMapPageState();
}

class ExplorerMapPageState extends State<ExplorerMapPage> {
  String? tappedMarkerInfo;
  late MapController mapController;
  late PageController _pageController;
  int prevPage = 0; // Declare MapController
  bool greyMarkersVisible = true; // Variable to track visibility of grey markers

  @override
  void initState() {
    super.initState();
    mapController = MapController(); // Initialize MapController
    _pageController = PageController(initialPage: 1, viewportFraction: 0.8)
      ..addListener(_onScroll);

    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      if(response != null) widget.account = jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  @override
  void dispose() {
    resetData(); // Call the function to reset the data
    super.dispose();
  }

  void resetData() {
    // Clear the data variable
  }

  void _onScroll() {
    if (_pageController.page!.toInt() != prevPage) {
      prevPage = _pageController.page!.toInt();
      moveCamera(prevPage);
    }
  }

  void moveCamera(int index) {
    final LatLng target = LatLng(
      widget.coordinates[index][0],
      widget.coordinates[index][1],
    );

    mapController.move(
      target,
      mapController.camera.zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return SelectRoutePage(
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
                    routeindex: widget.routeindex,
                    jsonData: widget.jsonData,
                    // dateandTime: widget.dateandTime,
                  );
                },
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 95.0),
          child: Row(
            children: [
              const Text(
                "Route",
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 108),
                child: IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(32.0),
                            ),
                          ),
                          content: SizedBox(
                            height: 240,
                            width: 240,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 65.0),
                                      child: Text(
                                        'Instructions',
                                        style: TextStyle(
                                            fontSize: 20,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 19),
                                      child: IconButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(
                                          Icons.close,
                                          size: 35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  '1. The map shows your starting ',
                                  style: TextStyle(fontSize: 17),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 167),
                                  child: Text('point'),
                                ),
                                const Text(''),
                                const Padding(
                                  padding: EdgeInsets.only(right: 20.0),
                                  child: Text(
                                    '2. To increase map size, click',
                                    style: TextStyle(fontSize: 17),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(),
                                  child: Text('on the "+" icon at the bottom'),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(right: 68),
                                  child: Text('right of the screen.'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                  iconSize: 30,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(1.2931, 103.8520),
          initialZoom: 15,
          minZoom: 10,
          maxZoom: 100,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://www.onemap.gov.sg/maps/tiles/Original/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.polylineCoordinates,
                color: Colors.black,
                strokeWidth: 8,
              )
            ],
          ),
          TappablePolylineLayer(
            polylineCulling: true,
            polylines: widget.polydata,
            onTap: (polylines, tapPosition) {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                            title: Text(polylines
                                .map((polyline) => polyline.tag)
                                .toString()))
                      ],
                    ));
                  });
            },
          ),
          Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  markers: [
                    for (int i = 0; i < widget.coordinates.length; i++)
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(
                          widget.coordinates[i][0],
                          widget.coordinates[i][1],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                  ],
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, Marker marker) {
                      print('Marker Latitude: ${marker.point.latitude}');
                      print('Marker Longitude: ${marker.point.longitude}');
                      // Find the index of the marker in the list of coordinates
                      int index = widget.coordinates.indexWhere((coord) =>
                          coord[0] == marker.point.latitude &&
                          coord[1] == marker.point.longitude);

                      // Return the ExamplePopup widget with the corresponding index
                      return ExamplePopup(
                        marker,
                        coordinates: widget.coordinates,
                        poiItinerary: widget.poiItinerary,
                        index: index,
                      );
                    },
                  ),
                ),
              ),
              if (widget.selectedIconIndex != 4)
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: greyMarkersVisible
                        ? [
                            for (int i = 0;
                                i < widget.routeInstructions.length;
                                i++)
                              Marker(
                                point:
                                    _extractLatLng(widget.routeInstructions[i]),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Color.fromARGB(255, 114, 218, 116),
                                  size: 30,
                                ),
                              )
                          ]
                        : [], // Empty list if greyMarkersVisible is false
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        // Find the index of the marker in the list of coordinates
                        print('Marker Latitude: ${marker.point.latitude}');
                        print('Marker Longitude: ${marker.point.longitude}');

                        int infoIndex =
                            widget.routeInstructions.indexWhere((instruction) {
                          List<String> coords =
                              instruction.toString().split(",");
                          String latitude = coords[3].trim();
                          String longitude = coords[4].trim();
                          return latitude == marker.point.latitude.toString() &&
                              longitude == marker.point.longitude.toString();
                        });

                        String lastItem = "";
                        if (infoIndex != -1 &&
                            infoIndex < widget.routeInstructions.length) {
                          List<String> instructionList = widget
                              .routeInstructions[infoIndex]
                              .toString()
                              .split(",");
                          lastItem =
                              instructionList.last.trim().replaceAll(']', '');
                        }

                        // Return the ExamplePopup widget with the corresponding index
                        return InfoPopup(
                          marker,
                          routeInstructions: widget.routeInstructions,
                          infoIndex: infoIndex,
                          lastItem: lastItem,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SizedBox(
                    height: 60.0,
                    child: ListView.builder(
                      scrollDirection:
                          Axis.horizontal, // Set scroll direction to horizontal
                      itemCount: widget.coordinates.length,
                      itemBuilder: (BuildContext context, int index) {
                        return _poiItineraryCard(index);
                      },
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              offset: Offset(0.0, 4.0),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            const double maxZoom =
                                25.0; // Set your maximum zoom level here
                            double newZoom = mapController.camera.zoom + 1;
                            if (newZoom <= maxZoom) {
                              mapController.move(
                                  mapController.camera.center, newZoom);
                            }
                          },
                          icon: const Icon(Icons.add),
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: IconButton(
                          onPressed: () {
                            mapController.move(mapController.camera.center,
                                mapController.camera.zoom - 1);
                          },
                          icon: const Icon(Icons.remove),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.selectedIconIndex != 4)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, 0, 10, 70),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40.0),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  greyMarkersVisible = !greyMarkersVisible;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red.shade600,
                                shadowColor: Colors
                                    .black87, // Change this to your desired color
                              ),
                              child: Text(
                                greyMarkersVisible
                                    ? 'Hide Direction Markers'
                                    : 'Show Direction Markers',
                              ),
                            ),
                          ),
                        ]),
                  ),
                )
            ],
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(32.0),
                  ),
                ),
                content: SizedBox(
                  height: 240,
                  width: 240,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 170.0),
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 35,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(),
                        child: Text(
                          'How would you rate your',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(),
                        child: Text(
                          'journey?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      RatingBar.builder(
                        initialRating: 3,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding:
                            const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          print(rating);
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            Flushbar(
                              icon: const Icon(
                                Icons.message,
                                size: 32,
                                color: Colors.white,
                              ),
                              shouldIconPulse: false,
                              padding: const EdgeInsets.all(24),
                              //title: '',
                              message: 'Rating has been submitted. Thank you!!',
                              flushbarPosition: FlushbarPosition.TOP,
                              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              duration: const Duration(seconds: 3),
                              barBlur: 20,
                              backgroundColor:
                                  Colors.green.shade700.withOpacity(0.9),
                            ).show(context);
                          });
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return ExplorerPage(
                                  // firstLocation: 'Select mode',
                                  secondLocation: 'Select mode',
                                  startTime: TimeOfDay.now(),
                                  endTime: TimeOfDay.now(),
                                  selectedIconIndex: -1,
                                  endDestinationChoice: 0,
                                  topK: 2,
                                  topN: 2,
                                  latStart: 0,
                                  latEnd: 0,
                                  longStart: 0,
                                  longEnd: 0,
                                  // dateandTime: " ",
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(230, 50),
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                              Radius.circular(20),
                            ))),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        label: const Text('End Journey'),
        icon: const Icon(Icons.map),
        backgroundColor: Colors.red.shade600,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _poiItineraryCard(int index) {
    return InkWell(
      onTap: () {
        moveCamera(index);
      },
      child: Center(
        child: Container(
          margin: EdgeInsets.all(5),
          height: 60.0,
          child: Material(
            elevation: 0, // Elevation value for the shadow effect
            borderRadius: BorderRadius.circular(45.0),
            child: ElevatedButton(
              onPressed: () {
                moveCamera(index);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade600, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(45.0),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: IntrinsicWidth(
                  child: Text(
                    '${widget.poiItinerary[index]["Itinerary"]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LatLng _extractLatLng(String instruction) {
    try {
      List<String> parts = instruction.split(',');
      if (parts.length < 6) {
        throw FormatException('Invalid instruction format: $instruction');
      }
      double latitude = double.parse(parts[3].trim());
      double longitude = double.parse(parts[4].trim());
      return LatLng(latitude, longitude);
    } catch (e) {
      print('Error parsing LatLng: $e');
      return LatLng(0, 0); // Default to (0, 0) or consider failing gracefully
    }
  }
}
