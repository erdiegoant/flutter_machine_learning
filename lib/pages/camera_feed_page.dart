import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning/main.dart';

class CameraFeedPage extends StatefulWidget {
  const CameraFeedPage({Key? key}) : super(key: key);

  @override
  _CameraFeedPageState createState() => _CameraFeedPageState();
}

class _CameraFeedPageState extends State<CameraFeedPage> {
  late CameraController controller;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[1], ResolutionPreset.high);

    controller.initialize().then((_) {
      if (!mounted) return;

      controller.startImageStream((image) => {});

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: controller != null
          ? AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            )
          : Container(),
    );
  }
}
