import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning/main.dart';
import 'package:machine_learning/tensorflow_pages/camera_object_detection_tensorflow.dart';
import 'package:tflite/tflite.dart';

class CameraFeedObjectDetectionTensorFlow extends StatefulWidget {
  const CameraFeedObjectDetectionTensorFlow({Key? key}) : super(key: key);

  @override
  _CameraFeedObjectDetectionTensorFlowState createState() =>
      _CameraFeedObjectDetectionTensorFlowState();
}

class _CameraFeedObjectDetectionTensorFlowState
    extends State<CameraFeedObjectDetectionTensorFlow> {
  late CameraController controller;
  CameraImage? _image;
  List<DetectedObject> detectedObjects = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/ssd_mobilenet.tflite',
      labels: 'assets/models/ssd_mobilenet.txt',
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  void startCamera() {
    controller = CameraController(cameras[0], ResolutionPreset.high);

    controller.initialize().then((_) {
      if (!mounted) return;

      controller.startImageStream((image) => {
            if (!busy)
              {
                setState(() {
                  _image = image;
                  busy = true;
                  detectObjectsLiveFeed();
                })
              }
          });
    });
  }

  Future<void> detectObjectsLiveFeed() async {
    if (_image == null) {
      return;
    }

    var objects = await Tflite.detectObjectOnFrame(
      bytesList: _image!.planes.map((e) => e.bytes).toList(),
      model: "SSDMobileNet",
      imageHeight: _image!.height,
      imageWidth: _image!.width,
      imageStd: 255.0,
      threshold: 0.4,
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
      busy = false;
    });
  }

  @override
  Future<void> dispose() async {
    await controller.dispose();
    await Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/img2.jpeg'), fit: BoxFit.cover),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Container(
                width: double.infinity,
                child: _image != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ),
                          ImageFrame(objects: detectedObjects, pageSize: size),
                        ],
                      )
                    : Container(
                        color: Colors.black,
                      ),
              ),
            ),
            Container(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: startCamera,
                    color: Colors.white,
                    icon: Icon(
                      Icons.videocam,
                    ),
                  ),
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
  final Size pageSize;

  const ImageFrame({
    Key? key,
    required this.objects,
    required this.pageSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        child: CustomPaint(
          painter: BorderPainter(rect: objects, pageSize: pageSize),
        ),
      ),
    );
  }
}

class BorderPainter extends CustomPainter {
  final List<DetectedObject> rect;
  final Size pageSize;

  const BorderPainter({required this.rect, required this.pageSize});

  @override
  void paint(Canvas canvas, Size size) {
    double factorX = size.width;
    double factorY = pageSize.height / pageSize.width * factorX;

    Paint p = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

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
              fontSize: 14,
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
