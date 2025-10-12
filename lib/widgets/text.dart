part of '../pagify.dart';

/// pagify text widget
class _PagifyText extends StatelessWidget {
  /// required text [String]
  final String text;

  /// text color [Color]
  final Color? color;
  final TextAlign? textAlign;

  /// pagify text widget constructor
  const _PagifyText(
    this.text, {
    this.color, this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.start,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
