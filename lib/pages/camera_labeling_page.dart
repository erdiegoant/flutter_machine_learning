import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class ImageLabelingPage extends StatefulWidget {
  ImageLabelingPage({Key? key}) : super(key: key);

  @override
  _ImageLabelingPageState createState() => _ImageLabelingPageState();
}

class _ImageLabelingPageState extends State<ImageLabelingPage> {
  File? _image;
  late ImagePicker picker;
  late ImageLabeler imageLabeler;
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    imageLabeler = GoogleMlKit.vision.imageLabeler();
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      labelImage();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      labelImage();
    }
  }

  Future<void> labelImage() async {
    final inputImage = InputImage.fromFile(_image!);
    List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

    String newResult = "";

    for (final label in labels) {
      final text = label.label;
      final confidence = label.confidence;

      newResult += "$text  ${confidence.toStringAsFixed(2)} \n";
    }

    setState(() {
      result = newResult;
    });
  }

  @override
  void dispose() {
    imageLabeler.close();
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
