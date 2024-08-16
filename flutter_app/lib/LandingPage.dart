/*debugging purposes*/import 'package:stack_trace/stack_trace.dart' as stacktrace;
import 'package:flutter/material.dart';
import 'package:project/pages/account/serverlogin.dart';
import 'package:project/pages/account/serverregister.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("\x1B[38;2;250;253;90m" + stacktrace.Frame.caller(0).library + "\x1B[0m");
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 200),
              ),
              Text(
                'Good to',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 55,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'have you back!',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Wonderous journey with AI',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20.0),
              // Image.asset(
              //   'assets/rocket-launch.PNG',
              //   height: 250,
              //   width: 250,
              // ),
              const SizedBox(height: 225.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const ServerRegisterPage();
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(270, 60),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return const ServerLoginPage();
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey,
                  minimumSize: const Size(270, 60),
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50))),
                ),
                child: Text(
                  'Log In',
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 17,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
