/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:crypt/crypt.dart';
//import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:project/pages/account/serverlogin.dart'; // serverlogin or login????
//import 'package:email_validator/email_validator.dart'; Not used, unnecessary for its simplicity and current use case
//import '../intro_pages/intro_pages.dart'; TODO: to be implemented
import 'package:http/http.dart' as http;

import 'package:project/network_util.dart' as networking;
import 'package:project/app_life_globals.dart' as globals;

class ServerRegisterPage extends StatefulWidget {
  const ServerRegisterPage({
    super.key,
  });

  @override
  State<ServerRegisterPage> createState() => _ServerRegisterPageState();
}

class _ServerRegisterPageState extends State<ServerRegisterPage> {
  @override
  void initState() {
    super.initState();

    // Prepopulate text
    nameController.text = "Johnny1";
    emailController.text = "Johnny1@gmail.com";
    dateController.text = "01/01/1970";
    mobilenumberController.text = "91234567";
    password.text = "Johnny112345!";
    confirmPassword.text = "Johnny112345!";
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  // use this controller to get what the user typed
  bool _secureText1 = true;
  final bool _secureText2 = true;
  bool? isCheck = false;
  final formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController mobilenumberController = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();

  RegExp passwordRegex =
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');

  RegExp dateRegExp = RegExp(r'^(0[1-9]|[12][0-9]|3[01])[- /.]');

  String selectedMonth = '01';
  String selectedYear =
      (DateTime.now().year - 30).toString(); // Defaulting to 30 years ago
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String? UID;
  String? _genderchoice = "Male";
  String dropdownValueNoOfPOIs = "2";
  Container emptyContainer = Container();
  Container emptyContainer2 = Container();

  Future<void> doRegistration() async {
    try {
      // RNG
      int random(int min, int max) {return min + Random().nextInt(max - min);}

      //A typical Google ID length is 21 characters long e.g. 105965179182758845591. 
      //9+9+3
      // Dev 2 Notes: thanks for the redudant code
      // Dev 2 Notes: Horrible UID implementation btw, for others working on this, do not use this. I kept it for demo sake. Should be done server-side anyways.
      //UID = "${random1(100000000, 999999999)}${random1(100000000, 999999999)}${random1(100, 999)}";
      UID = "${random(100000000, 999999999)}${random(100000000, 999999999)}${random(100, 999)}";

      DateTime currentDate = DateTime.now();
      int age = currentDate.year - int.parse(selectedYear);

      String NameForDB = nameController.text;
      String EmailForDB = emailController.text;
      String MobileNumberForDB = mobilenumberController.text;
      String PasswordForDB = password.text;
      Crypt HashedPassword = Crypt.sha256(PasswordForDB, salt: 'abcdefghijklmnop');
      String HashedPasswordString = HashedPassword.toString();

      // Creating a DateTime object with selectedMonth and selectedYear
      DateTime birthDate = DateTime(int.parse(selectedYear), int.parse(selectedMonth));
      String formattedDate = DateFormat('dd/MM/yyyy').format(birthDate);

      debugPrint("UID: $UID");
      debugPrint("Name: $NameForDB");
      //debugPrint("Age: $age"); // Age need not be sent. Horrible SQL Schema
      debugPrint("Gender: $_genderchoice");
      debugPrint("Email: $EmailForDB");
      debugPrint("Password: $PasswordForDB");
      debugPrint("Hashed Password: $HashedPassword");
      debugPrint("Mobile Number: $MobileNumberForDB");
      debugPrint("Birth Date: $formattedDate");

      var url = '${globals.serverURL}register';
      var client = networking.HttpSession(); // client isnt needed, but used as i js copy from login

      var body = {
          'Name': NameForDB,
          'age': age,
          'gender': _genderchoice,
          'password': HashedPasswordString,
          'email': EmailForDB,
          'birthdate': formattedDate,
          'mobilenumber': MobileNumberForDB,
      };

      debugPrint('connecting to ${url}');

      late final response;
      try {
        response = await client.post(url, body);
      }
      on TimeoutException catch (e){ // Not working, try to get this working.
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Unable to connect to server"),
        ));
        rethrow;
      }

      debugPrint('${response.body}');

      if (response.statusCode > 299 || response.statusCode < 200) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to create post!"),
        ));
      }
      Map status = json.decode(response.body);
      switch(response.statusCode) {
        case 201:
          showTopSnackBar(context, error: 'Error', message: 'Invalid credentials');
        break;
        case 200:
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Flushbar(
              icon: const Icon(
                Icons.message,
                size: 32,
                color: Colors.white,
              ),
              shouldIconPulse: false,
              padding: const EdgeInsets.all(24),
              title: 'Success Message',
              message: 'Account has been registered successfully',
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
          Navigator.of(context).pop();
        break;
        default:
          debugPrint("something wong");
          throw Exception();
      }

    } catch (e) {
      print('Caught Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(
                  height: 75,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 97),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                ///////////////
                // Full Name //
                ///////////////
                const Padding(
                  padding: EdgeInsets.only(right: 220),
                  child: Text(
                    'Full Name',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      hintText: ' Johnny',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.length < 6) {
                        return 'Name must have at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                ///////////
                // Email //
                ///////////
                const Padding(
                  padding: EdgeInsets.only(right: 245),
                  child: Text(
                    'Email',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      hintText: ' Johnny@gmail.com',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'Email is required';
                      }
                      /* TODO: Validate email
                      if (!EmailValidator.validate(value, true)) {
                        return 'Invalid Email Address';
                      }*/
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

                ////////////////
                // Birth Date //
                ////////////////
                const Padding(
                  padding: EdgeInsets.only(right: 218),
                  child: Text(
                    'Birth Date',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),

                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: Row(
                    children: [
                      // Month Dropdown
                      DropdownButton<String>(
                        value: selectedMonth,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedMonth = newValue!;
                            debugPrint("*******************");
                            debugPrint("** selectedMonth **");
                            debugPrint("*******************");
                            debugPrint(selectedMonth);
                          });
                        },
                        //Generate 12 months in dropdown list
                        items: List<DropdownMenuItem<String>>.generate(12,
                            (int index) {
                          return DropdownMenuItem<String>(
                            value: (index + 1).toString().padLeft(2, '0'),
                            child: Text(months[index]),
                          );
                        }),
                      ),
                      SizedBox(width: 10),
                      // Year Dropdown
                      DropdownButton<String>(
                        value: selectedYear,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedYear = newValue!;
                            debugPrint("******************");
                            debugPrint("** selectedYear **");
                            debugPrint("******************");
                            debugPrint(selectedYear);
                          });
                        },
                        //Generate 120 years in dropdown list
                        items: List<DropdownMenuItem<String>>.generate(120,
                            (int index) {
                          int year = DateTime.now().year - index;
                          return DropdownMenuItem<String>(
                            value: year.toString(),
                            child: Text(year.toString()),
                          );
                        }),
                      ),
                      SizedBox(width: 10),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),
                ////////////
                // Gender //
                ////////////
                const Padding(
                  padding: EdgeInsets.only(right: 240),
                  child: Text(
                    'Gender',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: Radio(
                              value: "Male",
                              groupValue: _genderchoice,
                              onChanged: (val1) {
                                setState(() {
                                  _genderchoice = val1;
                                  debugPrint(val1);
                                });
                              },
                            ),
                          ),
                          const Text(
                            "Male",
                            style: TextStyle(fontSize: 15),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: Radio(
                              value: "Female",
                              groupValue: _genderchoice,
                              onChanged: (val2) {
                                setState(() {
                                  _genderchoice = val2;
                                });
                              },
                            ),
                          ),
                          const Text(
                            "Female",
                            style: TextStyle(fontSize: 15),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          Transform.scale(
                            scale: 1.2,
                            child: Radio(
                              value: "Undisclose",
                              groupValue: _genderchoice,
                              onChanged: (val1) {
                                setState(() {
                                  _genderchoice = val1;
                                  debugPrint(val1);
                                });
                              },
                            ),
                          ),
                          const Text(
                            "Undisclosed",
                            style: TextStyle(fontSize: 15),
                          )
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                ///////////////////
                // Mobile Number //
                ///////////////////
                const Padding(
                  padding: EdgeInsets.only(right: 186),
                  child: Text(
                    'Mobile Number',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: TextFormField(
                    controller: mobilenumberController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      hintText: ' Mobile Number',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(8),
                      FilteringTextInputFormatter.allow(RegExp("[0-9]")),
                    ],
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'Mobile Number is required';
                      }
                      if (value.length != 8) {
                        return 'Invalid Mobile Number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                //////////////
                // Password //
                //////////////
                const Padding(
                  padding: EdgeInsets.only(right: 226),
                  child: Text(
                    'Password',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: TextFormField(
                    controller: password,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      hintText: ' Password',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _secureText1 = !_secureText1;
                          });
                        },
                        child: Icon(
                          _secureText1
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    obscureText: _secureText1,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'Password is required';
                      }
                      if (!passwordRegex.hasMatch(value)) {
                        return 'Please enter a stronger password';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                //////////////////////
                // Confirm Password //
                //////////////////////
                const Padding(
                  padding: EdgeInsets.only(right: 168),
                  child: Text(
                    'Confirm Password',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 50, left: 50),
                  child: TextFormField(
                    controller: confirmPassword,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(30),
                        ),
                      ),
                      hintText: ' Confirm Password',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                    obscureText: _secureText2,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return 'Confirm Password is required';
                      }
                      if (password.text != confirmPassword.text) {
                        return 'The 2 passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                //////////////////////////////////////////////////////
                // Agree to the Terms of service and Privacy Policy //
                //////////////////////////////////////////////////////
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: CheckboxListTile(
                      activeColor: Colors.red.shade800,
                      // set the checkbox to the left
                      controlAffinity: ListTileControlAffinity.leading,
                      title: RichText(
                          text: TextSpan(children: <TextSpan>[
                        const TextSpan(
                          text: 'Agree to the ',
                          style: TextStyle(color: Colors.red),
                        ),
                        TextSpan(
                            text: 'Terms of service ',
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                            //////////////
                            // Checkbox //
                            //////////////
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
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
                                              padding: const EdgeInsets.only(
                                                  left: 170.0),
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
                                      ),
                                    );
                                  },
                                );
                              }),
                        const TextSpan(
                          text: 'and ',
                          style: TextStyle(color: Colors.red),
                        ),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ])),
                      value: isCheck,
                      onChanged: (bool? newBool) {
                        setState(() {
                          isCheck = newBool;
                        });
                      }),
                ),
                const SizedBox(
                  height: 50,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (isCheck == false) {
                        showTopSnackBar(context,
                            error: 'Error',
                            message:
                                'Please agree to the Terms of service and Privacy Policy.');
                      } else {
                        if (_genderchoice != "Male" &&
                            _genderchoice != "Female" &&
                            _genderchoice != "Undisclose") {
                          showTopSnackBar(context,
                              error: 'Error',
                              message: 'Please select a gender');
                        } else {
                          doRegistration();
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(300, 60),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ))),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // use text span to have multiple types of colors in a statement
                // or statement with different fonts sizes etc.
                RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (BuildContext context) {
                                  return const ServerLoginPage();// which bro????
                                },
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                )
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
