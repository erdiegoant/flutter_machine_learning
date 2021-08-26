import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:machine_learning/main.dart';

class CameraFeedBarcodePage extends StatefulWidget {
  const CameraFeedBarcodePage({Key? key}) : super(key: key);

  @override
  _CameraFeedBarcodePageState createState() => _CameraFeedBarcodePageState();
}

class _CameraFeedBarcodePageState extends State<CameraFeedBarcodePage> {
  late CameraController controller;
  CameraImage? _image;
  late BarcodeScanner barcodeScanner;
  String result = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    barcodeScanner = GoogleMlKit.vision.barcodeScanner();
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
                  barcodeLiveFeed();
                })
              }
          });
    });
  }

  Future<void> barcodeLiveFeed() async {
    final inputImage = getInputImage();
    final List<Barcode> barcodes =
        await barcodeScanner.processImage(inputImage);
    String newResult = "";

    for (final barcode in barcodes) {
      final String displayValue = getBarcodeInformation(barcode);
      newResult += "$displayValue \n";
    }

    setState(() {
      result = newResult;
      busy = false;
    });
  }

  String getBarcodeInformation(Barcode barcode) {
    String result = "";

    print(barcode.type);

    switch (barcode.type) {
      case BarcodeType.email:
        BarcodeEmail data = barcode.value as BarcodeEmail;
        result = data.displayValue!;
        break;
      case BarcodeType.phone:
        BarcodePhone data = barcode.value as BarcodePhone;
        result = data.number!;
        break;
      case BarcodeType.wifi:
        BarcodeWifi data = barcode.value as BarcodeWifi;
        result = "${data.ssid} ${data.password}";
        break;
      case BarcodeType.url:
        BarcodeUrl data = barcode.value as BarcodeUrl;
        result = data.url!;
        break;
      case BarcodeType.text:
        BarcodeValue data = barcode.value;
        result = data.rawValue!;
        break;
      default:
        result = barcode.value.rawValue!;
        break;
    }

    return result;
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
    barcodeScanner.close();
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
