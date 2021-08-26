import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:machine_learning/main.dart';

class CameraFeedLabelingPage extends StatefulWidget {
  const CameraFeedLabelingPage({Key? key}) : super(key: key);

  @override
  _CameraFeedLabelingPageState createState() => _CameraFeedLabelingPageState();
}

class _CameraFeedLabelingPageState extends State<CameraFeedLabelingPage> {
  late CameraController controller;
  CameraImage? _image;
  late ImageLabeler imageLabeler;
  String result = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    imageLabeler = GoogleMlKit.vision.imageLabeler();
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
    final inputImage = getInputImage();
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);
    String newResult = "";

    for (final label in labels) {
      final text = label.label;
      final confidence = label.confidence;

      newResult += "$text  ${confidence.toStringAsFixed(2)} \n";
    }

    setState(() {
      result = newResult;
      busy = false;
    });
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();

    for (Plane plane in _image!.planes) {
      allBytes.putUint8List(plane.bytes);
    }

    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      _image!.width.toDouble(),
      _image!.height.toDouble(),
    );

    final InputImageRotation imageRotation = InputImageRotation.Rotation_0deg;
    final InputImageFormat imageFormat =
        InputImageFormatMethods.fromRawValue(_image!.format.raw) ??
            InputImageFormat.NV21;

    final planeData = _image!.planes.map((plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    }).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: imageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  @override
  void dispose() {
    controller.dispose();
    imageLabeler.close();
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
