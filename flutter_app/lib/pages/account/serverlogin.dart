/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:convert';
import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
import 'package:crypt/crypt.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:project/pages/account/serverforgetpassword.dart';
import 'package:project/pages/account/serverregister.dart';
import 'package:project/pages/explorer/explorer.dart';
import 'package:project/network_util.dart' as networking;
import 'package:project/app_life_globals.dart' as globals;


class ServerLoginPage extends StatefulWidget {
  const ServerLoginPage({super.key});

  @override
  State<ServerLoginPage> createState() => _ServerLoginPageState();
}

class _ServerLoginPageState extends State<ServerLoginPage> {
  bool _secureText = true;

  //bool? isCheck = false;

  RegExp reValidPWD = RegExp(
    r'^'
    r'(?=(?:[\s\S]*\d){2})' // At least two number
    r'(?=(?:[\s\S]*[a-z]){1})' // at least one lowercase letter
    r'(?=(?:[\s\S]*[A-Z]){1})' // at least one uppercase letter
    r'([\s\S]{5,15})' // at least 5 - 15 characters long
    r'$'
  ); // .hasMatch(query) to check

  String namevalue = '';

  String passwordvalue = '';

  //TextEditingController email = TextEditingController();
  TextEditingController email = TextEditingController();

  TextEditingController password = TextEditingController();

  TimeOfDay startTime = TimeOfDay.now();

  TimeOfDay endTime = TimeOfDay.now();
  final formKey = GlobalKey<FormState>();

  Future<void> validifyLogin() async {
    try {
      var url = '${globals.serverURL}login';
      var client = networking.HttpSession();

      var body = {
        'email': email.text,
        'password': Crypt.sha256(password.text as String, salt: 'abcdefghijklmnop').toString()
      };
      client.headers['Content-Type'] = 'application/json';

      debugPrint('connecting to ${url}');

      var response;
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
          showTopSnackBar1(context);
          password.clear();
        break;
        case 200:
          globals.currentSession = client; // binds client as current session for all future uses
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
                message: 'Login success',
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return ExplorerPage(
                    // firstLocation: 'Select mode',
                    secondLocation: 'Select mode',
                    startTime: startTime,
                    endTime: endTime,
                    selectedIconIndex: -1,
                    endDestinationChoice: 0,
                    topK: 2,
                    topN: 2,
                    latStart: 0,
                    latEnd: 0,
                    longStart: 0,
                    longEnd: 0,
                    // dateandTime: "",
                  );
                },
              ),
              (route) => route.isFirst
            );
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
  //This is to prepopulate textboxes for testing purposs
  void initState() {
    super.initState();
    email.text = "Johnny@gmail.com";
    password.text = "Johnny12345!";
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  Widget build(BuildContext context) {
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.selected,
        MaterialState.focused,
        MaterialState.pressed,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.red.shade800;
      }
      return Colors.red.shade800;
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(
                height: 105,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 220, top: 50),
                child: Text(
                  'Log In',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 80,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 252),
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
                  controller: email,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ),
                    ),
                    hintText: ' Email',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                  ),
                  validator: (namevalue) {
                    if (namevalue!.trim().isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              const Padding(
                padding: EdgeInsets.only(right: 220),
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
                          _secureText = !_secureText;
                        });
                      },
                      child: Icon(
                        _secureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  obscureText: _secureText,
                  validator: (passwordvalue) {
                    if (passwordvalue!.trim().isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 55.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Checkbox(
                    //   activeColor: Colors.red.shade800,
                    //   fillColor: MaterialStateProperty.resolveWith(getColor),
                    //   value: isCheck,
                    //   onChanged: (bool? newBool) {
                    //     setState(() {
                    //       isCheck = newBool;
                    //     });
                    //   },
                    // ),
                    // Text(
                    //   'Remember Me?            ',
                    //   style: TextStyle(
                    //     color: Colors.red.shade600,
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: RichText(
                        text: TextSpan(
                          text: 'Forget Password?',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return ServerForgetPassword(
                                      Email: email.text,
                                    );
                                  },
                                ),
                              );
                            },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 155,
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    validifyLogin();
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
                  'Log in',
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
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: 'Sign up',
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
                                return const ServerRegisterPage();
                              },
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showTopSnackBar1(BuildContext context) => Flushbar(
        icon: const Icon(
          Icons.error,
          size: 32,
          color: Colors.white,
        ),
        shouldIconPulse: false,
        padding: const EdgeInsets.all(24),
        title: 'Error',
        message:
            'Either Email or Password is incorrect. Please re-enter details.',
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
