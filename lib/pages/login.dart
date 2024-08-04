import 'package:tastee_app/pages/utils/custombutton.dart';
import 'package:tastee_app/pages/utils/customtextinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tastee_app/pages/utils/loading_dialog.dart';

class ChatterLogin extends StatefulWidget {
  @override
  _ChatterLoginState createState() => _ChatterLoginState();
}

class _ChatterLoginState extends State<ChatterLogin> {
  String email = '';
  String password = '';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

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

  Future<void> login() async {
    if (password.isNotEmpty && email.isNotEmpty) {
      showLoadingDialog(context);
      try {
        final loggedUser = await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        hideLoadingDialog(context);
        if (loggedUser != null) {
          final userDoc = await _firestore
              .collection('tastesurvey')
              .doc(loggedUser.user?.uid)
              .get();
          if (userDoc.exists) {
            Navigator.pushNamed(context, '/chat');
          } else {
            Navigator.pushNamed(context, '/tastesurvey');
          }
        }
      } on FirebaseAuthException catch (e) {
        hideLoadingDialog(context);
        print("Firebase Auth Error Code: ${e.code}");
        print("Firebase Auth Error Message: ${e.message}");

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
            errorMessage = 'Please check your ID or password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          default:
            errorMessage = 'Login failed. Please try again.';
        }
        showErrorDialog(context, 'Login Failed', "${e.code}: ${e.message}");
      } catch (e) {
        hideLoadingDialog(context);
        print("Unexpected Error: $e");
        showErrorDialog(context, 'Login Failed', e.toString());
      }
    } else {
      showErrorDialog(
          context, 'Uh oh!', 'Please enter the email and password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final screenSize = MediaQuery.of(context).size;
    // final buttonWidth = screenSize.width > 800 ? 600.0 : screenSize.width * 0.8;

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
                  hintText: 'Email',
                  leading: Icons.mail,
                  obscure: false,
                  keyboard: TextInputType.emailAddress,
                  userTyped: (val) {
                    email = val;
                  },
                  focusNode: _emailFocusNode, // 여기에 FocusNode 추가
                ),
                SizedBox(
                  height: 0,
                ),
                CustomTextInput(
                  hintText: 'Password',
                  leading: Icons.lock,
                  obscure: true,
                  userTyped: (val) {
                    password = val;
                  },
                  onSubmitted: (val) {
                    login();
                  },
                ),
                SizedBox(
                  height: 30,
                ),
                Hero(
                  tag: 'loginbutton',
                  child: CustomButton(
                    text: 'login',
                    accentColor: Colors.white,
                    mainColor: Colors.deepPurple,
                    onpress: () {
                      login();
                    },
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: Text(
                      'or create an account',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.deepPurple),
                    )),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                Hero(
                  tag: 'footer',
                  child: Text(
                    NameBox.appMaker,
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
