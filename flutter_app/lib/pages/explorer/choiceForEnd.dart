/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:async';
import 'package:flutter/material.dart';
import 'explorer.dart';
import 'searchlocation2.dart';
import 'dart:convert';

import 'package:project/constants.dart';

import 'package:project/app_life_globals.dart' as globals;
import 'package:project/network_util.dart' as networking;

class ChoiceForEndPage extends StatefulWidget {
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

  ChoiceForEndPage({
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
  State<ChoiceForEndPage> createState() => _ChoiceForEndPageState();
}

class _ChoiceForEndPageState extends State<ChoiceForEndPage> {
  @override
  void initState() {
    super.initState();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      widget.account = response == null ? null : jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  @override
  Widget build(BuildContext context) {
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
                  padding: EdgeInsets.only(left: 50),
                  child: Text(
                    "Select endpoint",
                    style: TextStyle(
                        color: textColorLightTheme,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 65,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, right: 45),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(350, 120),
                elevation: 5,
                shadowColor: Colors.grey,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(30),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ExplorerPage(
                        // firstLocation: widget.firstLocation,
                        secondLocation: "End at start point",
                        startTime: widget.startTime,
                        endTime: widget.endTime,
                        selectedIconIndex: widget.selectedIconIndex,
                        endDestinationChoice: widget.endDestinationChoice = 2,
                        topK: widget.topK,
                        topN: widget.topN,
                        latStart: widget.latStart,
                        latEnd: widget.latStart,
                        longStart: widget.longStart,
                        longEnd: widget.longStart,
                        // dateandTime: widget.dateandTime,
                      );
                    },
                  ),
                );
              },
              child: Row(
                children: [
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'End at start point',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Image.asset('assets/directions.jpg', height: 150, width: 150),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, right: 45),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(350, 120),
                elevation: 5,
                shadowColor: Colors.grey,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(30),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ExplorerPage(
                        // firstLocation: widget.firstLocation,
                        secondLocation: "End at recommended place",
                        startTime: widget.startTime,
                        endTime: widget.endTime,
                        selectedIconIndex: widget.selectedIconIndex,
                        endDestinationChoice: widget.endDestinationChoice = 1,
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
              child: Row(
                children: [
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'End at recommended place',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Image.asset('assets/adventure.jpg', height: 150, width: 150),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, right: 45),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(300, 120),
                elevation: 5,
                shadowColor: Colors.grey,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(30),
                  ),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return SearchLocationPage2(
                        // firstLocation: widget.firstLocation,
                        secondLocation: widget.secondLocation,
                        startTime: widget.startTime,
                        endTime: widget.endTime,
                        selectedIconIndex: widget.selectedIconIndex,
                        endDestinationChoice: widget.endDestinationChoice = 3,
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
              child: Row(
                children: [
                  const Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.0),
                      child: Text(
                        'End at a place of your choice',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Image.asset('assets/choose_location.jpg',
                        height: 150, width: 140),
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
