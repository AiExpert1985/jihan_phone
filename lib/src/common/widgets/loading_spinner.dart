import 'package:flutter/material.dart';
import 'package:tablets/src/common/values/gaps.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner(this.text, {super.key, this.fontColor = Colors.white});
  final String text;
  final Color fontColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        VerticalGap.xl,
        Text(text, style: TextStyle(color: fontColor, fontSize: 14))
      ],
    );
  }
}
