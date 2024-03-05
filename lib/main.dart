import 'package:always_awake_flutter/socket_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        primarySwatch: Colors.deepPurple,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle:
          SystemUiOverlayStyle(statusBarColor: Colors.transparent),
        ),
      ),
      title: 'WebSockets',
      home:   const LocationPage(),
    );
  }
}