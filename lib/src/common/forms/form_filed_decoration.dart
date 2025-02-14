import 'package:flutter/material.dart';

InputDecoration formFieldDecoration({String? label, bool hideBorders = false}) {
  return InputDecoration(
    // floatingLabelAlignment: FloatingLabelAlignment.center,
    label: label == null
        ? null
        : Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.all(12),
    isDense: true, // Add this line to remove the default padding
    border: hideBorders
        ? InputBorder.none
        : const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
  );
}
