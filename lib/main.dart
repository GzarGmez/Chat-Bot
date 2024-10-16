import 'package:flutter/material.dart';
import 'Pages/HomePage.dart';
import 'Pages/ChatPage.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBot App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomePage(),
        '/chat': (context) => const ChatPage(), 
      },
    );
  }
}