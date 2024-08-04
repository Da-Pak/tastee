import 'package:tastee_app/pages/utils/custombutton.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'utils/constants.dart';

class ChatterHome extends StatefulWidget {
  @override
  _ChatterHomeState createState() => _ChatterHomeState();
}

class _ChatterHomeState extends State<ChatterHome>
    with TickerProviderStateMixin {
  late AnimationController mainController;
  late Animation<Color?> mainAnimation;

  @override
  void initState() {
    super.initState();
    mainController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    mainAnimation =
        ColorTween(begin: Colors.deepPurple[900], end: Colors.grey[100])
            .animate(mainController);
    mainController.forward();
    mainController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 버튼 너비 계산
    final buttonWidth = screenSize.width > 800 ? 600.0 : screenSize.width * 0.8;

    // 화면 크기에 따른 텍스트 크기 계산
    final descTextSize = buttonWidth * 0.04; // 3% of shortest side

    return Scaffold(
      backgroundColor: mainAnimation.value,
      body: SafeArea(
        child: Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Hero(
                  tag: 'mainIcon',
                  child: Icon(
                    Icons.recommend,
                    size: mainController.value * buttonWidth * 0.3,
                    color: Colors.deepPurple[900],
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Hero(
                  tag: 'mainTitle',
                  child: Text(
                    NameBox.appName,
                    style: TextStyle(
                        color: Colors.deepPurple[900],
                        fontFamily: 'Poppins',
                        fontSize: buttonWidth * 0.1,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(height: screenSize.height * 0.01),
                TyperAnimatedTextKit(
                  isRepeatingAnimation: false,
                  speed: Duration(milliseconds: 20),
                  text: [NameBox.appDesc],
                  textStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: descTextSize,
                      color: Colors.deepPurple),
                ),
                SizedBox(height: screenSize.height * 0.09),
                Hero(
                  tag: 'loginbutton',
                  child: CustomButton(
                    text: 'Login',
                    accentColor: Colors.deepPurple,
                    mainColor: Colors.white,
                    onpress: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ),
                SizedBox(height: screenSize.height * 0.02),
                Hero(
                  tag: 'signupbutton',
                  child: CustomButton(
                    text: 'Signup',
                    accentColor: Colors.white,
                    mainColor: Colors.deepPurple,
                    onpress: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                  ),
                ),
                SizedBox(height: screenSize.height * 0.1),
                Text(NameBox.appMaker,
                    style: TextStyle(fontSize: 12)) // 80% of desc text size
              ],
            ),
          ),
        ),
      ),
    );
  }
}
