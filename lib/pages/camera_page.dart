import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  CameraPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _image;
  late ImagePicker picker;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_image != null) Image.file(_image!),
            ElevatedButton(
              onPressed: chooseImageFromGallery,
              onLongPress: getImageFromCamera,
              child: Text('Choose/ Capture'),
            )
          ],
        ),
      ),
    );
  }
}
