import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class TextTranslationPage extends StatefulWidget {
  const TextTranslationPage({Key? key}) : super(key: key);

  @override
  _TextTranslationPageState createState() => _TextTranslationPageState();
}

class _TextTranslationPageState extends State<TextTranslationPage> {
  TextEditingController controller = TextEditingController();
  String result = 'Translation here';
  OnDeviceTranslator? translator;
  TranslateLanguageModelManager? modelManager;

  @override
  void initState() {
    super.initState();

    modelManager = GoogleMlKit.nlp.translateLanguageModelManager();

    translator = GoogleMlKit.nlp.onDeviceTranslator(
      sourceLanguage: TranslateLanguage.ENGLISH,
      targetLanguage: TranslateLanguage.SPANISH,
    );

    downloadModel();
  }

  Future<void> downloadModel() async {
    var result = await modelManager!.downloadModel(TranslateLanguage.ENGLISH);
    print('Model downloaded: $result');
    result = await modelManager!.downloadModel(TranslateLanguage.SPANISH);
    print('Model downloaded: $result');
  }

  Future<void> deleteModel() async {
    var result = await modelManager!.deleteModel(TranslateLanguage.ENGLISH);
    print('Model deleted: $result');
    result = await modelManager!.deleteModel(TranslateLanguage.SPANISH);
    print('Model deleted: $result');
  }

  // Future<void> getAvailableModels() async {
  //   var result = await modelManager!.getAvailableModels();
  //   print('Available models: $result');
  // }
  //
  // Future<void> isModelDownloaded() async {
  //   var result =
  //       await modelManager!.isModelDownloaded(TranslateLanguage.ENGLISH);
  //   print('Is model downloaded: $result');
  //   result = await modelManager!.isModelDownloaded(TranslateLanguage.SPANISH);
  //   print('Is model downloaded: $result');
  // }

  @override
  void dispose() {
    deleteModel();
    controller.dispose();
    translator!.close();
    super.dispose();
  }

  Future<void> translateText() async {
    String translation = await translator!.translateText(controller.text);

    setState(() {
      result = translation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          color: Colors.black12,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                height: 50,
                child: Card(
                  child: Row(
                    children: [
                      Text('English'),
                      Container(
                        height: 48,
                        width: 1,
                        color: Colors.black,
                      ),
                      Text('Spanish'),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 20, left: 10, right: 10),
                child: Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          hintText: 'Type text here...',
                          filled: true,
                          border: InputBorder.none),
                      style: TextStyle(color: Colors.black),
                      maxLines: 100,
                    ),
                  ),
                ),
                width: double.infinity,
                height: 250,
              ),
              Container(
                margin: EdgeInsets.only(top: 15, left: 13, right: 13),
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      textStyle: TextStyle(color: Colors.white),
                      primary: Colors.green),
                  child: Text('Translate'),
                  onPressed: translateText,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 15, left: 10, right: 10),
                child: Card(
                  color: Colors.white,
                  child: Container(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        result,
                        style: TextStyle(fontSize: 18),
                      )),
                ),
                width: double.infinity,
                height: 250,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
