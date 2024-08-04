import 'package:tastee_app/pages/utils/custombutton.dart';
import 'package:tastee_app/pages/utils/customtextinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'utils/constants.dart';

class ChatterSignUp extends StatefulWidget {
  @override
  _ChatterSignUpState createState() => _ChatterSignUpState();
}

class _ChatterSignUpState extends State<ChatterSignUp> {
  final _auth = FirebaseAuth.instance;
  String? email;
  String? password;
  String? confirmPassword;
  String? name;
  late FocusNode _emailFocusNode;

  @override
  void initState() {
    super.initState();
    _emailFocusNode = FocusNode();

    // 화면이 빌드된 후 이메일 입력 창에 포커스 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Signing up..."),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool validatePassword(String password, String confirmPassword) {
    if (password.length < 6) {
      showErrorDialog(context, 'Signup Failed',
          'Password must be at least 6 characters long.');
      return false;
    }
    if (password != confirmPassword) {
      showErrorDialog(context, 'Signup Failed', 'Passwords do not match.');
      return false;
    }
    return true;
  }

  Future<void> signUp() async {
    if (name != null &&
        password != null &&
        confirmPassword != null &&
        email != null) {
      if (!validatePassword(password!, confirmPassword!)) {
        return;
      }
      showLoadingDialog(context);
      try {
        final newUser = await _auth.createUserWithEmailAndPassword(
            email: email!, password: password!);
        hideLoadingDialog(context);
        if (newUser != null) {
          await newUser.user?.updateProfile(displayName: name);
          Navigator.pushNamed(context, '/login');
        }
      } catch (e) {
        hideLoadingDialog(context);
        showErrorDialog(context, 'Signup Failed', e.toString());
      }
    } else {
      showErrorDialog(context, 'Signup Failed', 'All fields are required.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Hero(
                  tag: 'heroicon',
                  child: Icon(
                    Icons.textsms,
                    size: 120,
                    color: Colors.deepPurple[900],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                Hero(
                  tag: 'HeroTitle',
                  child: Text(
                    NameBox.appName,
                    style: TextStyle(
                        color: Colors.deepPurple[900],
                        fontFamily: 'Poppins',
                        fontSize: 26,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                CustomTextInput(
                  hintText: 'Name',
                  leading: Icons.text_format,
                  obscure: false,
                  userTyped: (value) {
                    name = value;
                  },
                  focusNode: _emailFocusNode,
                ),
                SizedBox(
                  height: 0,
                ),
                CustomTextInput(
                  hintText: 'Email',
                  leading: Icons.mail,
                  keyboard: TextInputType.emailAddress,
                  obscure: false,
                  userTyped: (value) {
                    email = value;
                  },
                ),
                SizedBox(
                  height: 0,
                ),
                CustomTextInput(
                  hintText: 'Password',
                  leading: Icons.lock,
                  keyboard: TextInputType.visiblePassword,
                  obscure: true,
                  userTyped: (value) {
                    password = value;
                  },
                ),
                SizedBox(
                  height: 0,
                ),
                CustomTextInput(
                  hintText: 'Confirm Password',
                  leading: Icons.lock,
                  keyboard: TextInputType.visiblePassword,
                  obscure: true,
                  userTyped: (value) {
                    confirmPassword = value;
                  },
                  onSubmitted: (value) {
                    signUp();
                  },
                ),
                SizedBox(
                  height: 30,
                ),
                Hero(
                  tag: 'signupbutton',
                  child: CustomButton(
                    onpress: signUp,
                    text: 'sign up',
                    accentColor: Colors.white,
                    mainColor: Colors.deepPurple,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'or log in instead',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.deepPurple),
                    )),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                Hero(
                    tag: 'appdesc',
                    child: Text(
                      NameBox.appDesc,
                      style: TextStyle(fontFamily: 'Poppins'),
                    )),
                Hero(
                  tag: 'footer',
                  child: Text(
                    NameBox.appMaker,
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
