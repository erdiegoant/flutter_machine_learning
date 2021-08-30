import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:machine_learning/tensorflow_pages/camera_segmentation_tensorflow.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraSegmentationTensorFLow(),
    );
  }
}
