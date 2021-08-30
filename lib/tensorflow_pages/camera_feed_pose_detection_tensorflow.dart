import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning/main.dart';
import 'package:machine_learning/tensorflow_pages/camera_pose_detection_tensorflow.dart';
import 'package:tflite/tflite.dart';

class CameraFeedPoseDetectionTensorFlow extends StatefulWidget {
  const CameraFeedPoseDetectionTensorFlow({Key? key}) : super(key: key);

  @override
  _CameraFeedPoseDetectionTensorFlowState createState() =>
      _CameraFeedPoseDetectionTensorFlowState();
}

class _CameraFeedPoseDetectionTensorFlowState
    extends State<CameraFeedPoseDetectionTensorFlow> {
  late CameraController controller;
  CameraImage? _image;
  List<Pose> poses = [];
  bool busy = false;

  @override
  void initState() {
    super.initState();
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

  void startCamera() {
    controller = CameraController(cameras[1], ResolutionPreset.high);

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

    var detected = await Tflite.runPoseNetOnFrame(
      bytesList: _image!.planes.map((e) => e.bytes).toList(),
      imageHeight: _image!.height,
      imageWidth: _image!.width,
      imageStd: 255.0,
      threshold: 0.5,
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
          keyPoints: keypoints.where((element) => element.score > 0.4).toList(),
        );
      }).toList();
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
                          ImageFrame(poses: poses, pageSize: size),
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
  final List<Pose> poses;
  final Size pageSize;

  const ImageFrame({
    Key? key,
    required this.poses,
    required this.pageSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        child: CustomPaint(
          painter: JointPainter(poses: poses, pageSize: pageSize),
        ),
      ),
    );
  }
}

class JointPainter extends CustomPainter {
  final List<Pose> poses;
  final Size pageSize;

  const JointPainter({required this.poses, required this.pageSize});

  @override
  void paint(Canvas canvas, Size size) {
    double factorX = size.width;
    double factorY = (pageSize.height - 100) / pageSize.width * factorX;

    Paint p = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

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
                fontSize: 14,
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
