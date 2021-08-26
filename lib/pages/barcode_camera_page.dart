import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class BarcodeCameraPage extends StatefulWidget {
  BarcodeCameraPage({Key? key}) : super(key: key);

  @override
  _BarcodeCameraPageState createState() => _BarcodeCameraPageState();
}

class _BarcodeCameraPageState extends State<BarcodeCameraPage> {
  File? _image;
  late ImagePicker picker;
  late BarcodeScanner barcodeScanner;
  String result = '';

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
    barcodeScanner = GoogleMlKit.vision.barcodeScanner();
  }

  Future<void> chooseImageFromGallery() async {
    var image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      scanBarcode();
    }
  }

  Future<void> getImageFromCamera() async {
    var image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      scanBarcode();
    }
  }

  Future<void> scanBarcode() async {
    final inputImage = InputImage.fromFile(_image!);
    List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);

    String newResult = "";

    for (final barcode in barcodes) {
      final String displayValue = getBarcodeInformation(barcode);
      newResult += "$displayValue \n";
    }

    setState(() {
      result = newResult;
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

  @override
  void dispose() {
    barcodeScanner.close();
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
                      child: _image != null
                          ? Image.file(
                              _image!,
                              width: 135,
                              height: 195,
                              fit: BoxFit.fill,
                            )
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
