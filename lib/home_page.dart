import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hige scores
          Expanded(
            child: Container(
              color: Colors.blue,
            ),
          ),

          // Game grid
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.green,
            ),
          ),

          // Play button
          Expanded(
            child: Container(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
