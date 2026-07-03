import 'package:flutter/material.dart';
import 'screens/login.dart';

void main() {
  runApp(const StreamerApp());
}

class StreamerApp extends StatelessWidget {
  const StreamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streaming Pessoal',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),

      home: const LoginScreen(),
    );
  }
}