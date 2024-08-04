import 'package:tastee_app/pages/utils/constants.dart';
import 'package:tastee_app/pages/login.dart';
import 'package:tastee_app/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:tastee_app/pages/chatterScreen.dart';
import 'package:tastee_app/pages/chatterSurvey.dart';
import 'pages/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChatterApp());
}

class ChatterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: NameBox.appName,

      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
      ),
      // home: ChatterHome(),
      initialRoute: '/',
      routes: {
        '/': (context) => ChatterHome(),
        '/login': (context) => ChatterLogin(),
        '/signup': (context) => ChatterSignUp(),
        '/chat': (context) => ChatterScreen(),
        '/tastesurvey': (context) => ChatterSurvey(),
        // '/chats':(context)=>ChatterScreen()
      },
    );
  }
}
