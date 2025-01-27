import 'package:flutter/material.dart';
// import 'package:tablets/src/common/widgets/main_frame.dart';
import 'package:toastification/toastification.dart';

void successUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.success);

void failureUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.error);

void infoUserMessage(BuildContext context, String message) =>
    _message(context, message, ToastificationType.info);

void _message(BuildContext context, String message, type) {
  toastification.show(
    // backgroundColor: itemsColor,
    // foregroundColor: Colors.yellow,
    context: context, // optional if you use ToastificationWrapper
    title: Text(
      message,
      style: const TextStyle(fontSize: 17),
    ),
    autoCloseDuration: const Duration(seconds: 5),
    type: type,
    style: ToastificationStyle.flatColored,
    alignment: Alignment.center,
    showProgressBar: false,
    showIcon: false,
  );
}
