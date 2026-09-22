import 'package:flutter/material.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const DiaxApp());
}

class DiaxApp extends StatelessWidget {
  const DiaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diax',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const RegisterScreen(),
    );
  }
}