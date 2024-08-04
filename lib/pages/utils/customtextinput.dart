import 'package:flutter/material.dart';

class CustomTextInput extends StatelessWidget {
  final String hintText;
  final IconData leading;
  final ValueChanged<String> userTyped;
  final bool obscure;
  final TextInputType keyboard;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;

  CustomTextInput({
    required this.hintText,
    required this.leading,
    required this.userTyped,
    required this.obscure,
    this.onSubmitted,
    this.keyboard = TextInputType.text,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // 버튼 너비 계산
    final buttonWidth =
        screenSize.width > 800 ? 700.0 : screenSize.width * 0.85;
    return Container(
      margin: EdgeInsets.only(top: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: EdgeInsets.only(left: 10),
      width: buttonWidth,
      child: TextField(
        onChanged: userTyped,
        keyboardType: keyboard,
        onSubmitted: onSubmitted,
        autofocus: false,
        obscureText: obscure ? true : false,
        decoration: InputDecoration(
          icon: Icon(
            leading,
            color: Colors.deepPurple,
          ),
          border: InputBorder.none,
          hintText: hintText,
        ),
        focusNode: focusNode,
      ),
    );
  }
}
