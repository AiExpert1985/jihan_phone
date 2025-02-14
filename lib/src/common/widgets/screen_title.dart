import 'package:flutter/material.dart';

Widget buildScreenTitle(BuildContext context, String label) {
  return Container(
    padding: const EdgeInsets.all(10),
    child: Text(
      label,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.yellow),
    ),
  );
}
