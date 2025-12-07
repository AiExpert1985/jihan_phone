import 'package:flutter/material.dart';
import 'package:tablets/src/common/functions/utils.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';

class StyledTotalText extends StatelessWidget {
  const StyledTotalText(this.text, this.fontColor, {super.key});
  final String text;
  final Color fontColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: fontColor,
        fontSize: 18,
      ),
    );
  }
}

class FormFieldLabel extends StatelessWidget {
  const FormFieldLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(2),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }
}

Widget buildTotalAmount(BuildContext context, dynamic amount, String label,
    {LinearGradient bgColorGradient = itemColorGradient, Color fontColor = Colors.yellow}) {
  String displayValue;
  if (amount is DateTime) {
    displayValue = formatDate(amount);
  } else if (amount is String) {
    displayValue = amount;
  } else {
    displayValue = doubleToStringWithComma(amount);
  }
  return Container(
    height: 45,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
        gradient: bgColorGradient, borderRadius: const BorderRadius.all(Radius.circular(6))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      StyledTotalText(label, fontColor),
      StyledTotalText(displayValue, fontColor),
    ]),
  );
}
