import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

typedef void Callback(String resultText);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setResultText;

  Camera(this.cameras, this.setResultText);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  String imageUrl = "";

  @override
  void initState() {
    super.initState();

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
        const interval = const Duration(milliseconds: 1000);
        new Timer.periodic(interval, (Timer t) => capturePictures());
      });
    }
  }

  void parseResponse(var response) {
    imageUrl = "https://socdist.enis.dev/${response['file_name']}";
    setState(() {
      widget.setResultText(imageUrl);
    });
  }

  Future<Map<String, dynamic>> fetchResponse(File image) async {
    var fileStream =
        new http.ByteStream(DelegatingStream.typed(image.openRead()));
    var length = await image.length();

    var request = new http.MultipartRequest(
        "POST", Uri.parse('https://socdist.enis.dev/predict'));
    var multipartFile = new http.MultipartFile('file', fileStream, length,
        filename: 'uploaded.jpg');
    request.files.add(multipartFile);
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      parseResponse(responseData);
      return responseData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  capturePictures() async {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/social_dist';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/$timestamp.jpg';
    controller.takePicture(filePath).then((_) {
      File imgFile = File(filePath);
      fetchResponse(imgFile);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;

    return OverflowBox(
        maxHeight: screenRatio > previewRatio
            ? screenH
            : screenW / previewW * previewH,
        maxWidth: screenRatio > previewRatio
            ? screenH / previewH * previewW
            : screenW,
        child: Image.network(imageUrl)
        // CameraPreview(controller),
        );
  }
}
