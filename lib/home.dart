import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'camera.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _resultText = "";
  @override
  void initState() {
    super.initState();
  }

  setResultText(resultText) {
    setState(() {
      _resultText = resultText;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [Camera(widget.cameras, setResultText)],
      ),
    );
  }
}
