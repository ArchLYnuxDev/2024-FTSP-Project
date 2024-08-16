/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'dart:convert';
import 'dart:async';
import 'package:another_flushbar/flushbar.dart';
//import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:project/pages/account/serverlogin.dart';
import 'package:project/pages/account/servernewpassword.dart';
import 'package:http/http.dart' as http;


class ServerForgetPassword extends StatefulWidget {
  String Email;

  ServerForgetPassword({
    Key? key,
    required this.Email,
  }) : super(key: key);

  @override
  State<ServerForgetPassword> createState() => _ServerForgetPasswordState();
}

class _ServerForgetPasswordState extends State<ServerForgetPassword> {
  @override
  void initState() {
    super.initState();
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
  }

  final formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();

  Future<void> connectAndPerformOperations() async {
    try {
      String Email = emailController.text;

      final response = await http.post(
        Uri.parse('http://10.0.2.2:7687/forgetpassword'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Connection': 'Keep-Alive'
        },
        body: jsonEncode({
          'email': Email,
        }),
      );

      if (response.statusCode == 200) {
        Map status = json.decode(response.body);
        if (status['status'] == 'Email is not registered') {
          showTopSnackBar1(context);
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return ServerNewPassword(
                  Email: emailController.text,
                );
              },
            ),
          );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to create post!"),
        ));
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsets.only(right: 160, top: 45),
                child: Text(
                  'Enter Email',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 90,
                ),
                child: Text(
                  'Verification code will be sent to your email to reset your password. Please enter your email.',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(
                height: 59,
              ),
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
                    /* TODO: validate email
                    if (!EmailValidator.validate(value, true)) {
                      return 'Invalid Email Address';
                    }*/
                    return null;
                  },
                ),
              ),
              const SizedBox(
                height: 200,
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    connectAndPerformOperations();
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(300, 60),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ))),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const ServerLoginPage();
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(300, 60),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                      Radius.circular(30),
                    ))),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 17,
                  ),
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
        message: 'Email is not registerd',
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
