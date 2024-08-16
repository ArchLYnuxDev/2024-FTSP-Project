/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:project/pages/profile/profile.dart';

import 'package:project/constants.dart';
import 'dart:convert';
import 'package:project/app_life_globals.dart' as globals;
import 'package:project/network_util.dart' as networking;

class UserCurrentLocation extends StatefulWidget {
  Map? account; // Not used here.

  UserCurrentLocation({
    Key? key,
  }) : super(key: key);

  @override
  State<UserCurrentLocation> createState() => UserCurrentLocationState();
}

class UserCurrentLocationState extends State<UserCurrentLocation> {
  @override
  void initState() {
    super.initState();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      widget.account = response == null ? null : jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  void getLocation() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    print(position);

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
  }

  Position? _currentLocation;

  late bool servicePermission = false;
  late LocationPermission permission;

  String _currentAddress = "";

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

  _getAddressFromCoordinates() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentLocation!.latitude, _currentLocation!.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.street} , ${place.name} , ${place.country} ${place.postalCode}";
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext context) {
              return ProfilePage();
            }));
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.black,
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(left: 70.0),
          child: Text(
            "Current Location",
            style: TextStyle(color: Colors.black, fontSize: 17),
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Location",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
                "Latitude = ${_currentLocation?.latitude} ; Longitude = ${_currentLocation?.longitude}"),
            const SizedBox(
              height: 30,
            ),
            const Text(
              "Address Location",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              _currentAddress,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                _currentLocation = await _getCurrentLocation();
                await _getAddressFromCoordinates();
                debugPrint('The button works');
                debugPrint('$_currentLocation');
                debugPrint(_currentAddress);
              },
              child: const Text('Get Current Location'),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

class CurrentLocationPage extends StatefulWidget {
  String Email;

  String UID;

  CurrentLocationPage({
    Key? key,
    required this.UID,
    required this.Email,
  }) : super(key: key);

  @override
  State<CurrentLocationPage> createState() => CurrentLocationPageState();
}

class CurrentLocationPageState extends State<CurrentLocationPage> {
  // final Completer<GoogleMapController> _controller = Completer();

  static const LatLng sourceLocation = LatLng(1.2931, 103.852);
  static const LatLng destination = LatLng(1.2931, 103.852);

  List<LatLng> polyLineCoordinates = [];

  @override
  void initState() {
    super.initState();
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
                    return ProfilePage();
                  },
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Colors.black,
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(left: 70.0),
            child: Text(
              "Current Location",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
          backgroundColor: Colors.white,
        ),
        body: Stack(children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: sourceLocation, // Use the starting point as center
              initialZoom: 14.5,
            ),
            // markers: {
            //   const Marker(
            //     markerId: MarkerId("source"),
            //     position: sourceLocation,
            //   ),
            //   const Marker(
            //     markerId: MarkerId("destination"),
            //     position: destination,
            //   ),
            // },
            children: [
              PolylineLayer(polylines: [
                Polyline(
                  points: polyLineCoordinates,
                  color: Colors.black,
                  strokeWidth: 8,
                )
              ]),
              PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                markers: [
                  const Marker(
                    width: 40.0,
                    height: 40.0,
                    point: sourceLocation,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.red,
                      size: 50,
                    ),
                  ), //sourceLocation
                ],
              )),
              PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                markers: [
                  const Marker(
                    width: 40.0,
                    height: 40.0,
                    point: destination,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.red,
                      size: 50,
                    ),
                  ), //destination
                ],
              ))
            ],
          ),
        ]));
  }

}
