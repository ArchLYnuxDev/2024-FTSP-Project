/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:another_flushbar/flushbar.dart';

import 'package:project/pages/profile/profile.dart';
import 'package:project/app_life_globals.dart' as globals;

class EnhanceProfilePage extends StatefulWidget {
  Map? account;

  EnhanceProfilePage({
    Key? key,
  }) : super(key: key);

  @override
  _EnhanceProfilePageState createState() => _EnhanceProfilePageState();
}

class _EnhanceProfilePageState extends State<EnhanceProfilePage> {
  @override
  void initState() {
    super.initState();
    (() async {
      var response = await globals.currentSession?.get(globals.serverURL + "accountdetails");
      if(response != null) widget.account = jsonDecode(response.body);
    })();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  final formKey = GlobalKey<FormState>();

  Map<String, double> initialmap = {'Western': 2, 'Thai': 3};

  late List<Map> intermediatelist =
      initialmap.entries.map((entry) => {entry.key: entry.value}).toList();

  late List<FoodPref> foodprefslist = intermediatelist
      .asMap()
      .entries
      .map((entry) => FoodPref(
            pref: entry.value.keys.first,
            rating: entry.value.values.first,
            index: entry.key,
          ))
      .toList();

  late int idcounter = -1;

  void deletefoodpref(int id) {
    setState(() {
      foodprefslist.removeWhere((element) => element.index == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: FloatingActionButton.extended(
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
                    message: 'Preferences saved',
                    flushbarPosition: FlushbarPosition.TOP,
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10),
                    ),
                    duration: const Duration(seconds: 3),
                    barBlur: 20,
                    backgroundColor: Colors.green.shade700.withOpacity(0.9),
                  ).show(context);
                });
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ProfilePage();
                    },
                  ),
                );
              },
              foregroundColor: Colors.white,
              backgroundColor: Colors.red.shade600,
              label: const Text('Save'),
              icon: Icon(Icons.save),
            ),
            body: SingleChildScrollView(
                child: Form(
                    key: formKey,
                    child: Column(children: [
                      const SizedBox(
                        height: 50,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        child: Text(
                          'Enhance Profile',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        child: Text(
                          '1 = Strongly dislike, 4 = Strongly like',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 185),
                        child: Text(
                          'Food Preferences',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),

                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: foodprefslist.length,
                          itemBuilder: (BuildContext context, int index) {
                            return (PrefFormField(
                              key: ObjectKey(foodprefslist[index]),
                              foodpref: foodprefslist[index],
                              removefunc: deletefoodpref,
                            ));
                          }),

                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              foodprefslist.add(FoodPref(
                                  pref: 'untitled',
                                  rating: 2,
                                  index: idcounter));
                              idcounter = idcounter - 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(270, 40),
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50))),
                          ),
                          child: const Icon(Icons.add)),
                    ])))));
  }
}

class FoodPref {
  FoodPref({
    required this.pref,
    required this.rating,
    required this.index,
  });
  String pref;
  double rating;
  int index;
}

class PrefFormField extends StatefulWidget {

  FoodPref foodpref;
  void Function(int id) removefunc;
  PrefFormField({super.key, required this.foodpref, required this.removefunc});

  @override
  State<StatefulWidget> createState() => _PrefFormField();
}

class _PrefFormField extends State<PrefFormField> {
  @override
  void initState() {
    super.initState();

    prefController.text = widget.foodpref.pref;
  }

  TextEditingController prefController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
              padding: const EdgeInsets.only(left: 30, right: 5),
              child: SizedBox(
                height: 40,
                child: TextFormField(
                  controller: prefController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(20),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    hintText: 'Preference',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {
                      widget.foodpref.pref = text;
                    });
                  },
                ),
              )),
        ),
        Expanded(
            flex: 4,
            child: Slider(
              value: widget.foodpref.rating,
              min: 1,
              max: 4,
              divisions: 3,
              label: widget.foodpref.rating.round().toString(),
              onChanged: (double value) {
                setState(() {
                  widget.foodpref.rating = value;
                });
              },
            )),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton(
                iconSize: 20,
                icon: const Icon(Icons.remove_circle),
                onPressed: () => widget.removefunc(widget.foodpref.index),
              ),
            ))
      ],
    );
  }
}
