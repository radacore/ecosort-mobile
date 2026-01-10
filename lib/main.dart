import 'package:flutter/material.dart';
import 'package:ecosort/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoSort',
      theme: ThemeData(
        // Using the primary green color from the design
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF368b3a),
          primary: const Color(0xFF368b3a),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
