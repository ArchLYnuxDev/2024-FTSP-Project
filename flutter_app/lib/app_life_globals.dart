library globals;

import 'package:project/network_util.dart' as networking;

networking.HttpSession? currentSession;
String serverURL = "https://10.0.2.2:7687/"; // Not the same localhost, ur running app on emulator.