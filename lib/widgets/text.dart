import 'package:flutter/material.dart';

/// pagify text widget
class AppText extends StatelessWidget {
  /// required text [String]
  final String text;

  /// text color [Color]
  final Color? color;

  /// text font size [double]
  final double? fontSize;

  /// text font weight [FontWeight]
  final FontWeight fontWeight;

  /// text align [TextAlign]
  final TextAlign textAlign;

  /// text overflow [TextOverflow]
  final TextOverflow? overflow;

  /// text max lines [int]
  final int? maxLines;

  /// text height [double]
  final double? height;

  /// pagify text widget constructor
  const AppText(
      this.text, {
        super.key,
        this.color,
        this.fontSize,
        this.fontWeight = FontWeight.normal,
        this.overflow,
        this.textAlign = TextAlign.start,
        this.maxLines,
        this.height,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: TextStyle(
        color: color,
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }
}
