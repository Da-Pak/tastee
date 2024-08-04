import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final Color accentColor;
  final Color mainColor;
  final String text;
  final VoidCallback onpress;

  CustomButton({
    required this.accentColor,
    required this.text,
    required this.mainColor,
    required this.onpress,
  });

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final buttonWidth = screenSize.width > 800 ? 600.0 : screenSize.width * 0.8;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onpress,
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300), // 여기를 300ms로 증가
          curve: Curves.easeInOut, // 부드러운 전환을 위한 커브 추가
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.accentColor,
              width: 2,
            ),
            color: _isHovering
                ? widget.mainColor.withOpacity(0.9)
                : widget.mainColor,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: _isHovering
                    ? widget.mainColor.withOpacity(0.3)
                    : Colors.transparent,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          width: buttonWidth,
          padding: EdgeInsets.all(15),
          child: Center(
            child: AnimatedDefaultTextStyle(
              // 텍스트 스타일 변화에도 애니메이션 적용
              duration: Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: widget.accentColor,
                fontWeight: _isHovering ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(widget.text.toUpperCase()),
            ),
          ),
        ),
      ),
    );
  }
}
