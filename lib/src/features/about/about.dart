import 'package:flutter/material.dart';
import 'package:tablets/src/common/values/gaps.dart';
import 'package:tablets/src/common/widgets/main_frame.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainFrame(
      child: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity, // because the width wasn't filling the whole space
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'برنامج الواح',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            VerticalGap.xxl,
            Text(
              'برنامج محاسبي يتميز بالسهولة و السرعة والدقة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            VerticalGap.xl,
            Text(
              'للتواصل 07701791983',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            )
          ],
        ),
      ),
    );
  }
}
