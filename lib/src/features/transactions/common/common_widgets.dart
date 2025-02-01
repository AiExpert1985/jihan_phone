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
        fontSize: 20,
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
    {Color bgColor = itemsColor, Color fontColor = Colors.yellow}) {
  return Container(
    height: 50,
    width: 350,
    padding: const EdgeInsets.all(5),
    decoration:
        BoxDecoration(color: bgColor, borderRadius: const BorderRadius.all(Radius.circular(6))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      StyledTotalText(label, fontColor),
      amount is DateTime
          ? StyledTotalText(formatDate(amount), fontColor)
          : StyledTotalText(doubleToStringWithComma(amount), fontColor),
    ]),
  );
}
