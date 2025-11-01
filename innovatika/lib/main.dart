import 'package:flutter/material.dart';
import 'package:innovatika/widget/nav.dart';
import 'package:innovatika/widget/const.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innovatika',
      theme: ThemeData(
        // Use the app's color constants as the seed for the color scheme
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.darkGreen),
      ),
      home: NavBar(),
    );
  }
}
