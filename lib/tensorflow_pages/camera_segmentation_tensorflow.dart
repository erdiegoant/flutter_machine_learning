import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class CameraSegmentationTensorFLow extends StatefulWidget {
  CameraSegmentationTensorFLow({Key? key}) : super(key: key);

  @override
  _CameraSegmentationTensorFLowState createState() =>
      _CameraSegmentationTensorFLowState();
}

class _CameraSegmentationTensorFLowState
    extends State<CameraSegmentationTensorFLow> {
  File? _image;
  late ImagePicker picker;
  Uint8List? image;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/deeplabv3_257_mv_gpu.tflite',
      labels: 'assets/models/deeplabv3_257_mv_gpu.txt',
      isAsset: true,
      useGpuDelegate: false,
    );

    print(res);
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      segmentateImage();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      segmentateImage();
    }
  }

  Future<void> segmentateImage() async {
    var segmentedImage = await Tflite.runSegmentationOnImage(
      path: _image!.path,
      imageStd: 255.0,
      asynch: true,
    );

    if (segmentedImage == null) {
      return;
    }

    setState(() {
      image = segmentedImage;
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
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/img2.jpeg'), fit: BoxFit.cover),
        ),
        child: Stack(
          children: <Widget>[
            if (image != null)
              Container(
                width: double.infinity,
                height: 600,
                child: Image.memory(
                  image!,
                  fit: BoxFit.fill,
                ),
              ),
            TextButton(
              onPressed: chooseImageFromGallery,
              onLongPress: getImageFromCamera,
              child: _image != null
                  ? Opacity(
                      opacity: 0.3,
                      child: Image.file(
                        _image!,
                        fit: BoxFit.fill,
                        height: 600,
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.grey[800],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
