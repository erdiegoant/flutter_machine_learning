import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as UI;

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class CameraFaceRecognitionPage extends StatefulWidget {
  CameraFaceRecognitionPage({Key? key}) : super(key: key);

  @override
  _CameraFaceRecognitionPageState createState() =>
      _CameraFaceRecognitionPageState();
}

class _CameraFaceRecognitionPageState extends State<CameraFaceRecognitionPage> {
  File? _image;
  UI.Image? image;
  late ImagePicker picker;
  late FaceDetector faceDetector;
  List<Face> faces = [];
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    faceDetector = GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
      enableClassification: true,
      mode: FaceDetectorMode.fast,
      minFaceSize: 0.1,
    ));
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      detectFaces();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      detectFaces();
    }
  }

  Future<void> detectFaces() async {
    final inputImage = InputImage.fromFile(_image!);
    List<Face> imageFaces = await faceDetector.processImage(inputImage);

    for (final face in imageFaces) {
      if (face.smilingProbability != null) {
        final double smileProb = face.smilingProbability!;
        result = smileProb > 0.5 ? 'Smiling' : 'Serious';

        setState(() {
          result = result;
        });
      }
    }

    setState(() {
      faces = imageFaces;
    });

    processImage();
  }

  Future<void> processImage() async {
    Uint8List bytes = await _image!.readAsBytes();
    image = (await decodeImageFromList(bytes));

    setState(() {
      image = image;
    });
  }

  @override
  void dispose() {
    faceDetector.close();
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
                          ? ImageFrame(faces: faces, image: image!)
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

class ImageFrame extends StatelessWidget {
  final List<Face> faces;
  final UI.Image image;

  const ImageFrame({
    Key? key,
    required this.faces,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: image.width.toDouble(),
        height: image.height.toDouble(),
        child: CustomPaint(
          painter: FacePainter(rect: faces, imageFile: image),
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> rect;
  final UI.Image imageFile;

  const FacePainter({required this.rect, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(imageFile, Offset.zero, Paint());
    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 2;

    for (Face rectangle in rect) {
      canvas.drawRect(rectangle.boundingBox, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
