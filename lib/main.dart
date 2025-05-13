import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Explorer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OnboardingScreen(), // initial screen
    );
  }
}
