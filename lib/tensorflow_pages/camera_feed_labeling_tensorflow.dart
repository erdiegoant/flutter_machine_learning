import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning/main.dart';
import 'package:tflite/tflite.dart';

class CameraFeedLabelingTensorFlow extends StatefulWidget {
  const CameraFeedLabelingTensorFlow({Key? key}) : super(key: key);

  @override
  _CameraFeedLabelingTensorFlowState createState() =>
      _CameraFeedLabelingTensorFlowState();
}

class _CameraFeedLabelingTensorFlowState
    extends State<CameraFeedLabelingTensorFlow> {
  late CameraController controller;
  CameraImage? _image;
  String result = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: 'assets/models/mobilenet_v1_1.0_224.tflite',
      labels: 'assets/models/mobilenet_v1_1.0_224.txt',
      isAsset: true,
      useGpuDelegate: false,
    );

    print(res);
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
                  labelLiveFeed();
                })
              }
          });
    });
  }

  Future<void> labelLiveFeed() async {
    if (_image == null) {
      return;
    }

    var labels = await Tflite.runModelOnFrame(
      bytesList: _image!.planes.map((e) => e.bytes).toList(),
      imageHeight: _image!.height,
      imageWidth: _image!.width,
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
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage('assets/images/img2.jpeg'),
                fit: BoxFit.cover),
          ),
          child: Column(
            children: <Widget>[
              SizedBox(width: 100),
              Container(
                margin: EdgeInsets.only(top: 105),
                child: Stack(
                  children: [
                    Stack(children: <Widget>[
                      Center(
                        child: Image.asset(
                          'assets/images/lcd2.jpeg',
                          height: 235,
                          width: 370,
                        ),
                      ),
                    ]),
                    Center(
                      child: TextButton(
                        onPressed: startCamera,
                        child: _image != null
                            ? AspectRatio(
                                aspectRatio: controller.value.aspectRatio,
                                child: CameraPreview(controller),
                              )
                            : Container(
                                margin: EdgeInsets.only(top: 40),
                                width: 140,
                                height: 150,
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.white,
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
      ),
    );
  }
}
