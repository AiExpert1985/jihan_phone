import 'package:flutter/material.dart';
import 'package:tablets/src/common/values/gaps.dart';

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      CircularProgressIndicator(),
      VerticalGap.xl,
      Text('جاري تحميل البيانات', style: TextStyle(color: Colors.white, fontSize: 14))
    ]);
  }
}
