import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class CameraTextRecognitionPage extends StatefulWidget {
  CameraTextRecognitionPage({Key? key}) : super(key: key);

  @override
  _CameraTextRecognitionPageState createState() =>
      _CameraTextRecognitionPageState();
}

class _CameraTextRecognitionPageState extends State<CameraTextRecognitionPage> {
  File? _image;
  late ImagePicker picker;
  late TextDetector textDetector;
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    textDetector = GoogleMlKit.vision.textDetector();
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      processText();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      processText();
    }
  }

  Future<void> processText() async {
    final inputImage = InputImage.fromFile(_image!);
    RecognisedText text = await textDetector.processImage(inputImage);

    String newResult = "";

    for (final textBlock in text.blocks) {
      final blockText = textBlock.text;

      newResult += "$blockText \n";
    }

    setState(() {
      result = newResult;
    });
  }

  @override
  void dispose() {
    textDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/img2.jpeg'), fit: BoxFit.cover),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(width: 100),
            Container(
              margin: EdgeInsets.only(top: 100),
              child: Stack(
                children: [
                  Stack(children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/frame3.png',
                        height: 210,
                        width: 200,
                      ),
                    ),
                  ]),
                  Center(
                    child: TextButton(
                      onPressed: chooseImageFromGallery,
                      onLongPress: getImageFromCamera,
                      child: _image != null
                          ? Image.file(
                              _image!,
                              width: 135,
                              height: 195,
                              fit: BoxFit.fill,
                            )
                          : Container(
                              width: 140,
                              height: 150,
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.grey[800],
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Text(
                '$result',
                style: TextStyle(fontFamily: 'finger_paint', fontSize: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
