import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as UI;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class DetectedObject {
  final String label;
  final double confidence;
  final Rect rect;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.rect,
  });

  @override
  String toString() {
    return 'DetectedObject{label: $label, confidence: $confidence, rect: $rect}';
  }
}

class CameraObjectDetectionTensorFLow extends StatefulWidget {
  CameraObjectDetectionTensorFLow({Key? key}) : super(key: key);

  @override
  _CameraObjectDetectionTensorFLowState createState() =>
      _CameraObjectDetectionTensorFLowState();
}

class _CameraObjectDetectionTensorFLowState
    extends State<CameraObjectDetectionTensorFLow> {
  File? _image;
  UI.Image? image;
  List<DetectedObject> detectedObjects = [];
  late ImagePicker picker;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/ssd_mobilenet.tflite',
      labels: 'assets/models/ssd_mobilenet.txt',
      isAsset: true,
      useGpuDelegate: false,
    );

    print(res);
  }

  Future<void> chooseImageFromGallery() async {
    var selectedImage = await picker.pickImage(source: ImageSource.gallery);

    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
      });

      detectObjects();
    }
  }

  Future<void> getImageFromCamera() async {
    var selectedImage = await picker.pickImage(source: ImageSource.camera);

    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
      });

      detectObjects();
    }
  }

  Future<void> detectObjects() async {
    var objects = await Tflite.detectObjectOnImage(
      model: "SSDMobileNet",
      path: _image!.path,
      imageStd: 255.0,
      threshold: 0.3,
      asynch: true,
    );

    if (objects == null) {
      return;
    }

    setState(() {
      detectedObjects = objects
          .map(
            (object) => DetectedObject(
              label: object['detectedClass'],
              confidence: object['confidenceInClass'],
              rect: Rect.fromLTWH(
                object['rect']['x'],
                object['rect']['y'],
                object['rect']['w'],
                object['rect']['h'],
              ),
            ),
          )
          .toList();
    });

    processImage();
  }

  Future<void> processImage() async {
    Uint8List bytes = await _image!.readAsBytes();
    UI.Image decodedImage = (await decodeImageFromList(bytes));

    setState(() {
      image = decodedImage;
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
                      child: image != null
                          ? ImageFrame(objects: detectedObjects, image: image!)
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
          ],
        ),
      ),
    );
  }
}

class ImageFrame extends StatelessWidget {
  final List<DetectedObject> objects;
  final UI.Image image;

  const ImageFrame({
    Key? key,
    required this.objects,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: image.width.toDouble(),
        height: image.height.toDouble(),
        child: CustomPaint(
          painter: ObjectFrame(rect: objects, imageFile: image),
        ),
      ),
    );
  }
}

class ObjectFrame extends CustomPainter {
  final List<DetectedObject> rect;
  final UI.Image imageFile;

  const ObjectFrame({required this.rect, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    double factorX = size.width;
    double factorY = imageFile.height / imageFile.width * factorX;

    canvas.drawImage(imageFile, Offset.zero, Paint());

    Paint p = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (DetectedObject rectangle in rect) {
      double top = rectangle.rect.top * factorY;
      double left = rectangle.rect.left * factorX;
      double width = rectangle.rect.width * factorX;
      double height = rectangle.rect.height * factorY;
      String text =
          '${rectangle.label} ${(rectangle.confidence * 100).toStringAsFixed(0)}%';

      canvas.drawRect(Rect.fromLTWH(left, top, width, height), p);

      TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
              color: Colors.black,
              fontSize: 180,
              backgroundColor: Colors.yellow),
        ),
        textDirection: TextDirection.ltr,
      )
        ..layout(maxWidth: size.width)
        ..paint(canvas, Offset(left, top + height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
