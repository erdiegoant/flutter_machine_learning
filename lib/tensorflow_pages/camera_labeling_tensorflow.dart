import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class CameraLabelingTensorFLow extends StatefulWidget {
  CameraLabelingTensorFLow({Key? key}) : super(key: key);

  @override
  _CameraLabelingTensorFLowState createState() =>
      _CameraLabelingTensorFLowState();
}

class _CameraLabelingTensorFLowState extends State<CameraLabelingTensorFLow> {
  File? _image;
  late ImagePicker picker;
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/mobilenet_v1_1.0_224.tflite',
      labels: 'assets/models/mobilenet_v1_1.0_224.txt',
      isAsset: true,
      useGpuDelegate: false,
    );
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
    var labels = await Tflite.runModelOnImage(
      path: _image!.path,
      imageStd: 255.0,
      threshold: 0.3,
      asynch: true,
    );

    if (labels == null) {
      return;
    }

    String newResult = "";

    for (final label in labels) {
      final text = (label['label'] as String);
      final confidence = (label['confidence'] as double);

      newResult += "$text  ${confidence.toStringAsFixed(2)} \n";
    }

    setState(() {
      result = newResult;
    });
  }

  @override
  Future<void> dispose() async {
    await Tflite.close();
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
