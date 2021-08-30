import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as UI;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class Keypoint {
  final double x, y, score;
  final String label;

  Keypoint({
    required this.x,
    required this.y,
    required this.score,
    required this.label,
  });
}

class Pose {
  final double score;
  final List<Keypoint> keyPoints;

  Pose({required this.score, required this.keyPoints});
}

class CameraPoseDetectionTensorFLow extends StatefulWidget {
  CameraPoseDetectionTensorFLow({Key? key}) : super(key: key);

  @override
  _CameraPoseDetectionTensorFLowState createState() =>
      _CameraPoseDetectionTensorFLowState();
}

class _CameraPoseDetectionTensorFLowState
    extends State<CameraPoseDetectionTensorFLow> {
  File? _image;
  UI.Image? image;
  late ImagePicker picker;
  List<Pose> poses = [];

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/posenet_mv1_075_float_from_checkpoints.tflite',
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

      detectPoses();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });

      detectPoses();
    }
  }

  Future<void> detectPoses() async {
    var detected = await Tflite.runPoseNetOnImage(
      path: _image!.path,
      imageStd: 255.0,
      threshold: 0.5,
      numResults: 1,
      asynch: true,
    );

    if (detected == null) {
      return;
    }

    setState(() {
      poses = detected.map((object) {
        List<Keypoint> keypoints = (object['keypoints'])
            .values
            .map<Keypoint>((value) => Keypoint(
                  x: value['x'],
                  y: value['y'],
                  score: value['score'],
                  label: value['part'],
                ))
            .toList();

        return Pose(
          score: object['score'],
          keyPoints: keypoints.where((element) => element.score > 0.5).toList(),
        );
      }).toList();
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
                          ? ImageFrame(poses: poses, image: image!)
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
  final List<Pose> poses;
  final UI.Image image;

  const ImageFrame({
    Key? key,
    required this.poses,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: image.width.toDouble(),
        height: image.height.toDouble(),
        child: CustomPaint(
          painter: ObjectFrame(poses: poses, imageFile: image),
        ),
      ),
    );
  }
}

class ObjectFrame extends CustomPainter {
  final List<Pose> poses;
  final UI.Image imageFile;

  const ObjectFrame({required this.poses, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    double factorX = size.width;
    double factorY = imageFile.height / imageFile.width * factorX;

    canvas.drawImage(imageFile, Offset.zero, Paint());

    Paint p = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (Pose pose in poses) {
      for (Keypoint keypoint in pose.keyPoints) {
        double top = keypoint.y * factorY;
        double left = keypoint.x * factorX;
        String text =
            '${keypoint.label} ${(keypoint.score * 100).toStringAsFixed(0)}%';

        canvas.drawCircle(Offset(left, top), 10.0, p);

        TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
                color: Colors.black,
                fontSize: 110,
                backgroundColor: Color.fromRGBO(0, 255, 255, 0.2)),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout(maxWidth: size.width)
          ..paint(canvas, Offset(left, top + 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
